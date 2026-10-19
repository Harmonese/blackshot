import AppKit

@main
struct Validation {
    @MainActor
    static func main() async {
        setbuf(stdout, nil)
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let args = CommandLine.arguments
        if args.contains("--self-test") {
            do { try Checks.run(); exit(0) } catch { print("Checks failed: \(error)"); exit(1) }
        }
        if args.contains("--inspect") {
            guard let path = args.last, let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let metadata = CaptureMetadata.read(from: URL(fileURLWithPath: path), data: data) else {
                print("Missing capture metadata"); exit(1)
            }
            print("Metadata: rect=\(metadata.rect), scale=\(metadata.scale), display=\(metadata.displayID), window=\(metadata.isWindow), shadow=\(metadata.hasShadow)")
            exit(0)
        }
        guard args.contains("--capture") || args.contains("--clipboard") else {
            print("Usage: validate.sh --capture | --clipboard | --inspect screenshot.png"); exit(2)
        }
        let outcome = await NativeCaptureService().capture(copyToClipboard: args.contains("--clipboard"))
        switch outcome {
        case .cancelled: print("Cancelled; pasteboard untouched")
        case .failed(let error): print("Capture failed: \(error)"); exit(1)
        case .captured(let capture):
            do {
                let png = try await Task.detached { try ImageInverter.invert(capture.data) }.value
                let evidence = FileManager.default.temporaryDirectory.appendingPathComponent("blackshot-validation-\(UUID().uuidString).png")
                try png.write(to: evidence)
                print("Inverted evidence: \(evidence.path)")
                switch capture.destination {
                case .clipboard(let count):
                    print("Clipboard replacement: \(ScreenshotClipboard.copy(png, replacing: count))")
                case .system:
                    let m = capture.metadata!
                    print("Submitting real metadata: \(m)")
                    let result: BSNativeSubmissionResult = await withCheckedContinuation { continuation in
                        BSSubmitNativeScreenshot(png, m.rect, m.scale, m.displayID, m.isWindow, m.hasShadow) {
                            continuation.resume(returning: $0)
                        }
                    }
                    print("Transport result: \(result.rawValue) (not native-save confirmation)")
                    try? await Task.sleep(for: .seconds(30))
                }
            } catch { print("Processing failed: \(error)"); exit(1) }
        }
    }
}
