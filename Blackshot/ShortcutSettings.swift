import AppKit
import Carbon.HIToolbox

@MainActor
final class ShortcutSettings: NSObject, NSWindowDelegate {
    static let shared = ShortcutSettings()
    private var panel: NSPanel?
    private var recorder: ShortcutRecorder?
    private var errorLabel: NSTextField?
    private var monitor: Any?
    var isRecording: Bool { panel?.isKeyWindow == true }

    func show() {
        if let panel { panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 440, height: 210),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = L("截图快捷键", "Screenshot Shortcut")
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        let view = NSView(frame: panel.contentView!.bounds)
        panel.contentView = view
        let info = NSTextField(wrappingLabelWithString: L("点击下方并按下新快捷键。必须包含 ⌘；可搭配 ⇧、⌥。Control 保留给复制到剪贴板。", "Click below and press a shortcut containing ⌘, optionally ⇧ or ⌥. Control is reserved for copying to the clipboard."))
        info.frame = NSRect(x: 20, y: 145, width: 400, height: 48)
        view.addSubview(info)
        let recorder = ShortcutRecorder(frame: NSRect(x: 20, y: 95, width: 400, height: 36))
        recorder.stringValue = HotkeyTap.shared.shortcut.display
        recorder.onShortcut = { [weak self] shortcut in self?.apply(shortcut) }
        view.addSubview(recorder)
        let label = NSTextField(wrappingLabelWithString: "")
        label.textColor = .systemRed
        label.frame = NSRect(x: 20, y: 45, width: 400, height: 42)
        view.addSubview(label)
        let reset = NSButton(title: L("恢复默认", "Restore Default"), target: self, action: #selector(resetShortcut))
        reset.frame = NSRect(x: 20, y: 10, width: 130, height: 30)
        view.addSubview(reset)
        self.panel = panel
        self.recorder = recorder
        self.errorLabel = label
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel, self.panel?.firstResponder === self.recorder else { return event }
            self.recorder?.keyDown(with: event)
            return nil
        }
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(recorder)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func resetShortcut() { apply(.standard) }
    private func apply(_ shortcut: ScreenshotShortcut) {
        do {
            try HotkeyTap.shared.update(shortcut)
            recorder?.stringValue = shortcut.display
            errorLabel?.stringValue = ""
        } catch { errorLabel?.stringValue = error.localizedDescription }
    }
    func windowWillClose(_ notification: Notification) {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil; panel = nil; recorder = nil; errorLabel = nil
    }
}

private final class ShortcutRecorder: NSTextField {
    var onShortcut: ((ScreenshotShortcut) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { true }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) { window?.close(); return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command), !flags.contains(.control),
              let text = Self.keyLabel(event), !text.isEmpty,
              ![kVK_Command, kVK_RightCommand, kVK_Shift, kVK_RightShift, kVK_Option, kVK_RightOption, kVK_Control, kVK_RightControl, kVK_CapsLock, kVK_Function].contains(Int(event.keyCode)),
              !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            NSSound.beep(); return
        }
        var modifiers = UInt32(cmdKey)
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        onShortcut?(.init(keyCode: UInt32(event.keyCode), modifiers: modifiers, keyLabel: text))
    }
    private static func keyLabel(_ event: NSEvent) -> String? {
        let symbols: [Int: String] = [kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7",
            kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12", kVK_Space: "Space"]
        if let symbol = symbols[Int(event.keyCode)] { return symbol }
        if let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
           let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) {
            let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue()
            if let bytes = CFDataGetBytePtr(data) {
                let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
                var dead: UInt32 = 0, length = 0
                var chars = [UniChar](repeating: 0, count: 8)
                let status = UCKeyTranslate(layout, event.keyCode, UInt16(kUCKeyActionDisplay), 0,
                    UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysMask), &dead, 8, &length, &chars)
                if status == noErr, length > 0 { return String(utf16CodeUnits: chars, count: length).uppercased() }
            }
        }
        return event.charactersIgnoringModifiers?.uppercased()
    }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        keyDown(with: event)
        return true
    }
}
