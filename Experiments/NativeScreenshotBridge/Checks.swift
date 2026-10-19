import AppKit
import ImageIO
import UniformTypeIdentifiers
import Carbon.HIToolbox

@MainActor
enum Checks {
    static func run() throws {
        let bytes = Data([0, 0, 0, 255, 255, 255, 255, 255, 64, 128, 192, 128, 0, 0, 0, 0])
        let provider = CGDataProvider(data: bytes as CFData)!
        let image = CGImage(width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 8,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let source = NSMutableData()
        let destination = CGImageDestinationCreateWithData(source, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyDPIWidth: 144, kCGImagePropertyDPIHeight: 144] as CFDictionary)
        precondition(CGImageDestinationFinalize(destination))
        let result = try ImageInverter.invert(source as Data)
        let bitmap = NSBitmapImageRep(data: result)!
        precondition(bitmap.pixelsWide == 2 && bitmap.pixelsHigh == 2)
        func color(_ x: Int, _ y: Int) -> NSColor { bitmap.colorAt(x: x, y: y)! }
        precondition(color(0, 0).redComponent > 0.99 && color(1, 0).redComponent < 0.01)
        precondition(abs(color(0, 1).alphaComponent - 128.0/255) < 0.01)
        precondition(abs(color(0, 1).redComponent - (1 - 64.0/255)) < 0.02)
        precondition(color(1, 1).alphaComponent == 0)
        let resultSource = CGImageSourceCreateWithData(result as CFData, nil)!
        let properties = CGImageSourceCopyPropertiesAtIndex(resultSource, 0, nil)! as NSDictionary
        precondition(abs((properties[kCGImagePropertyDPIWidth] as! Double) - 144) < 0.1)
        do { _ = try ImageInverter.invert(Data("invalid".utf8)); preconditionFailure("Invalid image accepted") }
        catch ImageInverter.Failure.invalidImage { }
        print("PASS inversion: RGB, dimensions, DPI, transparent and translucent pixels, invalid input")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Blackshot-check-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecoveryStore(directory: directory)
        precondition(store.data == nil)
        try store.store(result)
        precondition(RecoveryStore(directory: directory).data == result)
        try store.store(source as Data)
        precondition(store.data == source as Data)
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        precondition(files == ["latest.png"])
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -RecoveryStore.lifetime - 10)],
            ofItemAtPath: directory.appendingPathComponent("latest.png").path)
        precondition(RecoveryStore(directory: directory).data == nil)
        precondition(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("latest.png").path))
        try store.store(result)
        try store.discard()
        precondition(store.data == nil)
        print("PASS recovery: restart, replacement, single file, 24-hour expiry, discard")

        precondition(ScreenshotShortcut.standard.isValid)
        precondition(!ScreenshotShortcut(keyCode: 22, modifiers: UInt32(cmdKey | controlKey), keyLabel: "6").isValid)
        precondition(!ScreenshotShortcut(keyCode: 22, modifiers: UInt32(shiftKey), keyLabel: "6").isValid)
        let encoded = try JSONEncoder().encode(ScreenshotShortcut.standard)
        let decoded = try JSONDecoder().decode(ScreenshotShortcut.self, from: encoded)
        precondition(decoded == .standard)
        print("PASS shortcut: validation and persistence format")

        let suiteName = "Blackshot.Checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let hotkeys = HotkeyTap(defaults: defaults)
        defer { hotkeys.stop() }
        let old = ScreenshotShortcut(keyCode: UInt32(kVK_F18), modifiers: UInt32(cmdKey | optionKey | shiftKey), keyLabel: "F18")
        let new = ScreenshotShortcut(keyCode: UInt32(kVK_F19), modifiers: old.modifiers, keyLabel: "F19")
        try hotkeys.update(old)
        var blocker: EventHotKeyRef?
        let blocked = RegisterEventHotKey(new.keyCode, new.modifiers, EventHotKeyID(signature: 0x54455354, id: 10),
            GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &blocker)
        precondition(blocked == noErr)
        defer { if let blocker { UnregisterEventHotKey(blocker) } }
        do { try hotkeys.update(new); preconditionFailure("Conflicting shortcut accepted") }
        catch { precondition(hotkeys.shortcut == old) }
        var oldAttempt: EventHotKeyRef?
        let stillRegistered = RegisterEventHotKey(old.keyCode, old.modifiers, EventHotKeyID(signature: 0x54455354, id: 11),
            GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &oldAttempt)
        if let oldAttempt { UnregisterEventHotKey(oldAttempt) }
        precondition(stillRegistered == eventHotKeyExistsErr)
        UnregisterEventHotKey(blocker!); blocker = nil
        try hotkeys.update(new)
        precondition(hotkeys.shortcut == new)
        hotkeys.stop()
        let reloaded = HotkeyTap(defaults: defaults)
        defer { reloaded.stop() }
        try reloaded.start()
        precondition(reloaded.shortcut == new)
        print("PASS Carbon registration: conflict rollback, replacement, restart persistence; isolated test preferences")

    }
}
