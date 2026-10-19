import AppKit
import ImageIO
import Darwin

struct CapturedScreenshot: Sendable {
    struct Metadata: Sendable {
        let rect: CGRect
        let scale: Double
        let displayID: CGDirectDisplayID
        let isWindow: Bool
        let hasShadow: Bool
    }
    enum Destination: Sendable { case system, clipboard(changeCount: Int) }
    let data: Data
    let metadata: Metadata?
    let destination: Destination
}

enum CaptureOutcome {
    case cancelled
    case captured(CapturedScreenshot)
    case failed(String)
}

enum CaptureMetadata {
    nonisolated static func property(_ name: String, at url: URL) -> Any? {
        url.withUnsafeFileSystemRepresentation { path -> Any? in
            guard let path else { return nil }
            let count = getxattr(path, name, nil, 0, 0, 0)
            guard count > 0, count < 65_536 else { return nil }
            var data = Data(count: count)
            let read = data.withUnsafeMutableBytes { getxattr(path, name, $0.baseAddress, count, 0, 0) }
            guard read == count else { return nil }
            return try? PropertyListSerialization.propertyList(from: data, format: nil)
        }
    }

    nonisolated static func read(from url: URL, data: Data) -> CapturedScreenshot.Metadata? {
        guard let values = property("com.apple.metadata:kMDItemScreenCaptureGlobalRect", at: url) as? [NSNumber],
              values.count == 4,
              let type = property("com.apple.metadata:kMDItemScreenCaptureType", at: url) as? String,
              ["selection", "window"].contains(type),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let dpi = props[kCGImagePropertyDPIWidth] as? Double,
              let width = props[kCGImagePropertyPixelWidth] as? Double,
              let height = props[kCGImagePropertyPixelHeight] as? Double,
              dpi > 0 else { return nil }
        let rect = CGRect(x: values[0].doubleValue, y: values[1].doubleValue,
                          width: values[2].doubleValue, height: values[3].doubleValue)
        guard !rect.isEmpty, [rect.minX, rect.minY, rect.width, rect.height].allSatisfy(\.isFinite) else { return nil }
        var displays = [CGDirectDisplayID](repeating: 0, count: 32)
        var count: UInt32 = 0
        guard CGGetDisplaysWithRect(rect, UInt32(displays.count), &displays, &count) == .success, count > 0 else { return nil }
        let display = displays.prefix(Int(count)).max { a, b in
            let aa = CGDisplayBounds(a).intersection(rect), bb = CGDisplayBounds(b).intersection(rect)
            return aa.width * aa.height < bb.width * bb.height
        }!
        let scale = dpi / 72
        // Window images may extend beyond the window bounds to include their shadow.
        let shadow = type == "window" && (width > rect.width * scale + 1 || height > rect.height * scale + 1)
        return .init(rect: rect, scale: scale, displayID: display, isWindow: type == "window", hasShadow: shadow)
    }
}
