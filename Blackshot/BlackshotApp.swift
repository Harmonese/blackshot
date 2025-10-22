import SwiftUI
import AppKit
import UserNotifications
import CoreGraphics
import Combine  // ✅ 添加这个导入！

@main
struct BlackshotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - Language Manager
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    enum Language: String {
        case chinese = "zh-Hans"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .chinese: return "中文"
            case .english: return "English"
            }
        }
    }
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage"),
           let lang = Language(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // 默认根据系统语言
            let systemLang = Locale.preferredLanguages.first ?? "en"
            self.currentLanguage = systemLang.hasPrefix("zh") ? .chinese : .english
        }
    }
    
    func localized(_ key: String) -> String {
        return LocalizedStrings.get(key, language: currentLanguage)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// MARK: - Localized Strings
struct LocalizedStrings {
    static func get(_ key: String, language: LanguageManager.Language) -> String {
        switch language {
        case .chinese:
            return chineseStrings[key] ?? key
        case .english:
            return englishStrings[key] ?? key
        }
    }
    
    private static let chineseStrings: [String: String] = [
        // Menu
        "app.name": "Blackshot",
        "menu.screenshot": "截图并反色 (⌘⇧6)",
        "menu.checkPermissions": "检查权限",
        "menu.language": "语言 / Language",
        "menu.quit": "退出",
        
        // Permissions
        "permission.needed.title": "需要授予权限",
        "permission.needed.message": "Blackshot 需要以下权限才能正常工作:\n\n%@\n\n点击\"打开系统设置\"前往授权页面。",  // ✅ 修复引号
        "permission.accessibility": "辅助功能",
        "permission.screenRecording": "屏幕录制",
        "permission.openSettings": "打开系统设置",
        "permission.later": "稍后",
        
        "permission.success.title": "权限检查通过 ✅",
        "permission.success.message": "所有必需权限已授予：\n\n✓ 辅助功能\n✓ 屏幕录制\n\nBlackshot 可以正常使用。",
        "permission.success.ok": "好的",
        
        // Hotkey
        "hotkey.failed.title": "无法注册全局快捷键",
        "hotkey.failed.message": "请在 辅助功能 权限中允许 Blackshot。",
        
        // Screenshot
        "screenshot.success.title": "Blackshot",
        "screenshot.success.message": "反色截图已复制到剪贴板 ✅",
        "screenshot.failed.title": "截图失败",
        "screenshot.copy.failed.title": "复制失败",
        "screenshot.copy.failed.message": "无法写入剪贴板",
    ]
    
    private static let englishStrings: [String: String] = [
        // Menu
        "app.name": "Blackshot",
        "menu.screenshot": "Screenshot & Invert (⌘⇧6)",
        "menu.checkPermissions": "Check Permissions",
        "menu.language": "Language / 语言",
        "menu.quit": "Quit",
        
        // Permissions
        "permission.needed.title": "Permissions Required",
        "permission.needed.message": "Blackshot needs the following permissions to work properly:\n\n%@\n\nClick \"Open System Settings\" to grant permissions.",
        "permission.accessibility": "Accessibility",
        "permission.screenRecording": "Screen Recording",
        "permission.openSettings": "Open System Settings",
        "permission.later": "Later",
        
        "permission.success.title": "Permissions Granted ✅",
        "permission.success.message": "All required permissions have been granted:\n\n✓ Accessibility\n✓ Screen Recording\n\nBlackshot is ready to use.",
        "permission.success.ok": "OK",
        
        // Hotkey
        "hotkey.failed.title": "Cannot Register Global Hotkey",
        "hotkey.failed.message": "Please allow Blackshot in Accessibility permissions.",
        
        // Screenshot
        "screenshot.success.title": "Blackshot",
        "screenshot.success.message": "Inverted screenshot copied to clipboard ✅",
        "screenshot.failed.title": "Screenshot Failed",
        "screenshot.copy.failed.title": "Copy Failed",
        "screenshot.copy.failed.message": "Unable to write to clipboard",
    ]
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private let langManager = LanguageManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 禁用系统调试日志(Release 构建推荐)
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        
        NSApp.setActivationPolicy(.accessory)
        requestNotificationPermission()
        setupStatusBar()
        checkPermissions(showSuccessAlert: false)
        HotkeyTap.shared.start()
        
        // 监听语言切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc func languageChanged() {
        setupStatusBar() // 重建菜单
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Blackshot")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: langManager.localized("app.name"), action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: langManager.localized("menu.screenshot"), action: #selector(triggerScreenshot), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: langManager.localized("menu.checkPermissions"), action: #selector(checkPermissionsManually), keyEquivalent: ""))
        menu.addItem(.separator())
        
        // 语言切换子菜单
        let languageMenu = NSMenu()
        let chineseItem = NSMenuItem(title: LanguageManager.Language.chinese.displayName, action: #selector(switchToChinese), keyEquivalent: "")
        chineseItem.state = langManager.currentLanguage == .chinese ? .on : .off
        languageMenu.addItem(chineseItem)
        
        let englishItem = NSMenuItem(title: LanguageManager.Language.english.displayName, action: #selector(switchToEnglish), keyEquivalent: "")
        englishItem.state = langManager.currentLanguage == .english ? .on : .off
        languageMenu.addItem(englishItem)
        
        let languageMenuItem = NSMenuItem(title: langManager.localized("menu.language"), action: nil, keyEquivalent: "")
        languageMenuItem.submenu = languageMenu
        menu.addItem(languageMenuItem)
        
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: langManager.localized("menu.quit"), action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func switchToChinese() {
        langManager.currentLanguage = .chinese
    }
    
    @objc func switchToEnglish() {
        langManager.currentLanguage = .english
    }
    
    @objc func triggerScreenshot() { ScreenshotManager.shared.captureAndInvert() }
    @objc func quitApp() { NSApp.terminate(nil) }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _,_ in }
    }

    @objc func checkPermissionsManually() {
        checkPermissions(showSuccessAlert: true)
    }

    private func checkPermissions(showSuccessAlert: Bool) {
        let hasAccessibility = AXIsProcessTrusted()
        let hasScreenRecording = checkScreenRecordingPermission()
        
        var missingPermissions: [String] = []
        if !hasAccessibility {
            missingPermissions.append(langManager.localized("permission.accessibility"))
        }
        if !hasScreenRecording {
            missingPermissions.append(langManager.localized("permission.screenRecording"))
        }
        
        if !missingPermissions.isEmpty {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = self.langManager.localized("permission.needed.title")
                alert.informativeText = String(format: self.langManager.localized("permission.needed.message"),
                                               missingPermissions.joined(separator: self.langManager.currentLanguage == .chinese ? "、" : ", "))
                alert.alertStyle = .warning
                alert.addButton(withTitle: self.langManager.localized("permission.openSettings"))
                alert.addButton(withTitle: self.langManager.localized("permission.later"))
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    self.openSystemPreferences(for: missingPermissions)
                }
            }
        } else if showSuccessAlert {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = self.langManager.localized("permission.success.title")
                alert.informativeText = self.langManager.localized("permission.success.message")
                alert.alertStyle = .informational
                alert.addButton(withTitle: self.langManager.localized("permission.success.ok"))
                alert.runModal()
            }
        }
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        let testPath = NSTemporaryDirectory() + "blackshot_permission_test.png"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-x", "-t", "png", "-R", "0,0,1,1", testPath]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            let fileExists = FileManager.default.fileExists(atPath: testPath)
            try? FileManager.default.removeItem(atPath: testPath)
            return task.terminationStatus == 0 && fileExists
        } catch {
            return false
        }
    }
    
    private func openSystemPreferences(for permissions: [String]) {
        let accessibilityName = langManager.localized("permission.accessibility")
        let screenRecordingName = langManager.localized("permission.screenRecording")
        
        if permissions.contains(accessibilityName) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else if permissions.contains(screenRecordingName) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - HotkeyTap(使用 CoreGraphics 监听 Command+Shift+6)
final class HotkeyTap {
    static let shared = HotkeyTap()
    private var eventTap: CFMachPort?
    private var runloopSource: CFRunLoopSource?
    private let keycode6: Int64 = 22

    func start() {
        let mask = (1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { (_, type, event, _) -> Unmanaged<CGEvent>? in
                guard type == .keyDown else { return Unmanaged.passUnretained(event) }
                let flags = event.flags
                let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                if flags.contains(.maskCommand),
                   flags.contains(.maskShift),
                   keycode == HotkeyTap.shared.keycode6 {
                    DispatchQueue.main.async {
                        ScreenshotManager.shared.captureAndInvert()
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        )
        guard let tap = eventTap else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = LanguageManager.shared.localized("hotkey.failed.title")
                alert.informativeText = LanguageManager.shared.localized("hotkey.failed.message")
                alert.runModal()
            }
            return
        }
        runloopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runloopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func stop() {
        if let src = runloopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
        runloopSource = nil
        eventTap = nil
    }
}

// MARK: - Screenshot Manager
class ScreenshotManager {
    static let shared = ScreenshotManager()
    private init() {}
    private let langManager = LanguageManager.shared
    
    func captureAndInvert() {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("blackshot_temp.png")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-i", "-o", "-r", "-t", "png", tmpURL.path]
        
        do {
            try task.run()
            DispatchQueue.global(qos: .userInitiated).async {
                task.waitUntilExit()
                if FileManager.default.fileExists(atPath: tmpURL.path),
                   let data = try? Data(contentsOf: tmpURL), data.count > 0 {
                    self.processScreenshot(at: tmpURL)
                } else {
                    self.cleanup(tmpURL)
                }
            }
        } catch {
            self.showError(langManager.localized("screenshot.failed.title"), message: error.localizedDescription)
        }
    }
    
    func processScreenshot(at url: URL) {
        guard let img = NSImage(contentsOf: url),
              let inv = invertColors(of: img) else {
            cleanup(url); return
        }
        if copyToClipboard(inv) {
            showNotification(title: langManager.localized("screenshot.success.title"),
                           message: langManager.localized("screenshot.success.message"))
        } else {
            showError(langManager.localized("screenshot.copy.failed.title"),
                     message: langManager.localized("screenshot.copy.failed.message"))
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { self.cleanup(url) }
    }
    
    func invertColors(of image: NSImage) -> NSImage? {
        guard let tiff = image.tiffRepresentation,
              let bmp = NSBitmapImageRep(data: tiff) else { return nil }
        let w = bmp.pixelsWide, h = bmp.pixelsHigh
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        for x in 0..<w {
            for y in 0..<h {
                if let c = bmp.colorAt(x: x, y: y) {
                    rep.setColor(NSColor(calibratedRed: 1-c.redComponent,
                                         green: 1-c.greenComponent,
                                         blue: 1-c.blueComponent,
                                         alpha: c.alphaComponent),
                                 atX: x, y: y)
                }
            }
        }
        let newImg = NSImage(size: NSSize(width: w, height: h))
        newImg.addRepresentation(rep)
        return newImg
    }
    
    func copyToClipboard(_ image: NSImage) -> Bool {
        guard let tiff = image.tiffRepresentation,
              let bmp = NSBitmapImageRep(data: tiff),
              let png = bmp.representation(using: .png, properties: [:]) else { return false }
        
        // 生成 macOS 风格的文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "Screenshot \(timestamp).png"
        
        // 创建临时文件用于提供文件承诺
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try png.write(to: fileURL)
        } catch {
            return false
        }
        
        let pb = NSPasteboard.general
        pb.clearContents()
        
        // 同时提供多种格式以兼容不同应用
        pb.declareTypes([.fileURL, .png, .tiff], owner: nil)
        pb.setData(png, forType: .png)
        pb.setData(tiff, forType: .tiff)
        pb.writeObjects([fileURL as NSURL])
        
        // 5秒后清理临时文件
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        return true
    }
    
    func cleanup(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
    
    func showError(_ title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.runModal()
        }
    }
}
