import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let language = LanguageManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = RecoveryStore.shared
        ScreenshotManager.shared.onMissingPermission = { [weak self] in self?.checkPermissions(showSuccess: false) }
        HotkeyTap.shared.onCapture = { copy in ScreenshotManager.shared.captureAndInvert(copyToClipboard: copy) }
        for name in [Notification.Name.languageChanged, .shortcutChanged, .recoveryChanged, .captureStateChanged] {
            NotificationCenter.default.addObserver(self, selector: #selector(rebuildMenu), name: name, object: nil)
        }
        rebuildMenu()
        do { try HotkeyTap.shared.start() }
        catch {
            let alert = NSAlert()
            alert.messageText = L("快捷键不可用", "Shortcut Unavailable")
            alert.informativeText = L("请从菜单打开“快捷键设置…”并选择其他组合。\n\n", "Open Shortcut Settings… from the menu and choose another combination.\n\n") + error.localizedDescription
            alert.runModal()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyTap.shared.stop()
        ScreenshotManager.shared.stop()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func rebuildMenu() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem?.button?.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Blackshot")
            statusItem?.button?.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(NSMenuItem(title: "Blackshot", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let capture = item(L("截图并反色", "Capture & Invert") + " (\(HotkeyTap.shared.shortcut.display))", #selector(capture))
        capture.isEnabled = ScreenshotManager.shared.state == .idle
        menu.addItem(capture)
        menu.addItem(item(L("快捷键设置…", "Shortcut Settings…"), #selector(shortcutSettings)))
        if RecoveryStore.shared.data != nil {
            menu.addItem(item(L("恢复最近截图…", "Recover Latest Screenshot…"), #selector(recover)))
        }
        menu.addItem(.separator())
        menu.addItem(item(L("检查权限", "Check Permissions"), #selector(checkPermissionsManually)))
        let languages = NSMenu()
        for (lang, selector) in [(LanguageManager.Language.chinese, #selector(chinese)), (.english, #selector(english))] {
            let entry = item(lang.displayName, selector)
            entry.state = language.currentLanguage == lang ? .on : .off
            languages.addItem(entry)
        }
        let languageItem = NSMenuItem(title: L("语言", "Language"), action: nil, keyEquivalent: "")
        languageItem.submenu = languages
        menu.addItem(languageItem)
        menu.addItem(.separator())
        let quit = item(L("退出", "Quit"), #selector(quit))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
        statusItem?.menu = menu
    }

    private func item(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }
    @objc private func capture() { ScreenshotManager.shared.captureAndInvert() }
    @objc private func shortcutSettings() { ShortcutSettings.shared.show() }
    @objc private func recover() { RecoveryStore.shared.showRecovery() }
    @objc private func chinese() { language.currentLanguage = .chinese }
    @objc private func english() { language.currentLanguage = .english }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func checkPermissionsManually() { checkPermissions(showSuccess: true) }

    private func checkPermissions(showSuccess: Bool) {
        if CGPreflightScreenCaptureAccess() {
            guard showSuccess else { return }
            let alert = NSAlert()
            alert.messageText = L("权限已授予", "Permission Granted")
            alert.informativeText = L("屏幕录制权限已授予，可以截图。", "Screen Recording permission is granted. Blackshot is ready to capture.")
            alert.runModal()
        } else {
            let alert = NSAlert()
            alert.messageText = L("系统暂未确认屏幕录制权限", "Screen Recording Access Is Not Confirmed")
            alert.informativeText = L("如果已经允许 Blackshot，可以直接试一次截图。若系统仍拒绝，请在系统设置中检查当前这份 Blackshot 的屏幕录制权限。", "If you have already allowed Blackshot, try a capture directly. If macOS still denies it, check Screen Recording access for this copy of Blackshot in System Settings.")
            alert.addButton(withTitle: L("尝试截图", "Try Capture"))
            alert.addButton(withTitle: L("打开系统设置", "Open System Settings"))
            alert.addButton(withTitle: L("稍后", "Later"))
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                // Start a fresh user-initiated capture after the current coordinator task finishes.
                DispatchQueue.main.async { ScreenshotManager.shared.captureAndInvert() }
            case .alertSecondButtonReturn:
                CGRequestScreenCaptureAccess()
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            default: break
            }
        }
    }
}
