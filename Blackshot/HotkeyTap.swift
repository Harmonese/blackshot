import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyTap {
    static let shared = HotkeyTap()
    private static let signature: OSType = 0x42534854 // BSHT
    private let preference = "ScreenshotShortcut.v1"
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private var hotkeys: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    private(set) var shortcut: ScreenshotShortcut = .standard
    var onCapture: ((Bool) -> Void)?

    func start() throws {
        let saved = defaults.data(forKey: preference)
            .flatMap { try? JSONDecoder().decode(ScreenshotShortcut.self, from: $0) }
        try update(saved?.isValid == true ? saved! : .standard)
    }

    func update(_ candidate: ScreenshotShortcut) throws {
        guard candidate.isValid else { throw ShortcutError.invalid }
        if candidate == shortcut, !hotkeys.isEmpty { return }
        try installHandler()
        var replacements: [EventHotKeyRef] = []
        for id: UInt32 in [1, 2] {
            var reference: EventHotKeyRef?
            let modifiers = candidate.modifiers | (id == 2 ? UInt32(controlKey) : 0)
            let status = RegisterEventHotKey(candidate.keyCode, modifiers,
                EventHotKeyID(signature: Self.signature, id: id), GetApplicationEventTarget(),
                OptionBits(kEventHotKeyExclusive), &reference)
            guard status == noErr, let reference else {
                replacements.forEach { UnregisterEventHotKey($0) }
                throw ShortcutError.registration(status)
            }
            replacements.append(reference)
        }
        hotkeys.forEach { UnregisterEventHotKey($0) }
        hotkeys = replacements
        shortcut = candidate
        defaults.set(try JSONEncoder().encode(candidate), forKey: preference)
        NotificationCenter.default.post(name: .shortcutChanged, object: nil)
    }

    func stop() {
        hotkeys.forEach { UnregisterEventHotKey($0) }
        hotkeys.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }

    private func installHandler() throws {
        guard handler == nil else { return }
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            guard let event else { return noErr }
            var id = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard result == noErr, id.signature == 0x42534854, [1, 2].contains(id.id) else { return noErr }
            let copy = id.id == 2
            DispatchQueue.main.async {
                guard !ShortcutSettings.shared.isRecording else { return }
                HotkeyTap.shared.onCapture?(copy)
            }
            return noErr
        }, 1, &type, nil, &handler)
        guard status == noErr else { throw ShortcutError.registration(status) }
    }

    struct ShortcutError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
        @MainActor static var invalid: ShortcutError {
            .init(message: L("快捷键必须包含 ⌘，Control 保留给复制。", "The shortcut must include ⌘. Control is reserved for copying."))
        }
        @MainActor static func registration(_ status: OSStatus) -> ShortcutError {
            .init(message: L("无法注册快捷键（\(status)）。请尝试其他组合，并检查系统或其他应用是否占用。",
                             "Could not register shortcut (\(status)). Try another combination and check system or app shortcuts."))
        }
    }
}
