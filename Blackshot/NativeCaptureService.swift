import AppKit
import ImageIO

@MainActor
final class NativeCaptureService {
    private var process: Process?
    private var cancelled = false
    private var activeDirectory: URL?

    func cancel() {
        cancelled = true
        if let process, process.isRunning { process.terminate() }
        if let activeDirectory { try? FileManager.default.removeItem(at: activeDirectory) }
    }

    func capture(copyToClipboard: Bool) async -> CaptureOutcome {
        guard process == nil else { return .failed("capture.busy") }
        cancelled = false
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Blackshot-\(UUID().uuidString)", isDirectory: true)
        let file = directory.appendingPathComponent("capture.png")
        let errors = directory.appendingPathComponent("stderr.txt")
        activeDirectory = directory
        defer { try? FileManager.default.removeItem(at: directory); activeDirectory = nil }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            _ = FileManager.default.createFile(atPath: errors.path, contents: nil)
            let errorHandle = try FileHandle(forWritingTo: errors)
            defer { try? errorHandle.close() }
            let pasteboard = NSPasteboard.general
            let before = pasteboard.changeCount
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            task.arguments = ["-i", "-t", "png"] + (copyToClipboard ? ["-c"] : []) + [file.path]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = errorHandle
            process = task
            defer { process = nil }
            let status: Int32 = try await withCheckedThrowingContinuation { continuation in
                task.terminationHandler = { process in
                    let status = process.terminationStatus
                    DispatchQueue.main.async { continuation.resume(returning: status) }
                }
                do { try task.run() }
                catch { task.terminationHandler = nil; continuation.resume(throwing: error) }
            }
            if cancelled { return .cancelled }
            if let data = try? Data(contentsOf: file), !data.isEmpty {
                guard status == 0 else { return .failed("capture.failed") }
                let metadata = CaptureMetadata.read(from: file, data: data)
                return .captured(.init(data: data, metadata: metadata, destination: .system))
            }
            // Control at mouse release redirects screencapture to the general pasteboard.
            // Never clear it in advance, and don't consume unrelated ordinary clipboard content.
            if status == 0, pasteboard.changeCount != before,
               let data = pasteboard.data(forType: .png), Self.isSystemScreenshot(data) {
                return .captured(.init(data: data, metadata: nil,
                                      destination: .clipboard(changeCount: pasteboard.changeCount)))
            }
            let detail = (try? String(contentsOf: errors, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // Native cancellation produces no image and no diagnostic.
            return detail.isEmpty ? .cancelled : .failed("capture.failed")
        } catch {
            return cancelled ? .cancelled : .failed("capture.failed")
        }
    }

    private static func isSystemScreenshot(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] else { return false }
        return exif[kCGImagePropertyExifUserComment] as? String == "Screenshot"
    }
}

@MainActor
enum ScreenshotClipboard {
    static func copy(_ png: Data, replacing changeCount: Int? = nil) -> Bool {
        let pasteboard = NSPasteboard.general
        guard changeCount == nil || pasteboard.changeCount == changeCount,
              let source = NSImage(data: png), let tiff = source.tiffRepresentation else { return false }
        let item = NSPasteboardItem()
        guard item.setData(png, forType: .png), item.setData(tiff, forType: .tiff) else { return false }
        pasteboard.clearContents()
        return pasteboard.writeObjects([item])
    }
}
