import SwiftUI
import AppKit
import UserNotifications
import CoreGraphics

@main
struct BlackshotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 禁用系统调试日志(Release 构建推荐)
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        
        NSApp.setActivationPolicy(.accessory)
        requestNotificationPermission()
        setupStatusBar()
        checkPermissions(showSuccessAlert: false)
        HotkeyTap.shared.start()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Blackshot")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Blackshot", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "截图并反色 (⌘⇧6)", action: #selector(triggerScreenshot), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "检查权限", action: #selector(checkPermissionsManually), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
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
            missingPermissions.append("辅助功能")
        }
        if !hasScreenRecording {
            missingPermissions.append("屏幕录制")
        }
        
        if !missingPermissions.isEmpty {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "需要授予权限"
                alert.informativeText = """
                Blackshot 需要以下权限才能正常工作:
                
                \(missingPermissions.joined(separator: "、"))
                
                点击"打开系统设置"前往授权页面。
                """
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "稍后")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    self.openSystemPreferences(for: missingPermissions)
                }
            }
        } else if showSuccessAlert {
            // 只有手动检查时才显示权限完备提示
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "权限检查通过 ✅"
                alert.informativeText = """
                所有必需权限已授予：
                
                ✓ 辅助功能
                ✓ 屏幕录制
                
                Blackshot 可以正常使用。
                """
                alert.alertStyle = .informational
                alert.addButton(withTitle: "好的")
                alert.runModal()
            }
        }
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        // macOS 上没有直接的 API 检测屏幕录制权限状态
        // 最佳实践：尝试执行一次轻量级截图测试
        
        // 方法1: 检查临时截图是否能成功创建
        let testPath = NSTemporaryDirectory() + "blackshot_permission_test.png"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-x", "-t", "png", "-R", "0,0,1,1", testPath] // 只捕获1x1像素
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // 检查文件是否创建成功
            let fileExists = FileManager.default.fileExists(atPath: testPath)
            
            // 清理测试文件
            try? FileManager.default.removeItem(atPath: testPath)
            
            // 如果退出码为0且文件存在，说明有权限
            return task.terminationStatus == 0 && fileExists
        } catch {
            return false
        }
    }
    
    private func openSystemPreferences(for permissions: [String]) {
        if permissions.contains("辅助功能") {
            // 打开辅助功能设置
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else if permissions.contains("屏幕录制") {
            // 打开屏幕录制设置
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
    private let keycode6: Int64 = 22 // ANSI 6 键位

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
                alert.messageText = "无法注册全局快捷键"
                alert.informativeText = "请在 辅助功能 权限中允许 Blackshot。"
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
    static let shared = ScreenshotManager(); private init() {}
    
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
            self.showError("截图失败", message: error.localizedDescription)
        }
    }
    
    func processScreenshot(at url: URL) {
        guard let img = NSImage(contentsOf: url),
              let inv = invertColors(of: img) else {
            cleanup(url); return
        }
        if copyToClipboard(inv) {
            showNotification(title: "Blackshot", message: "反色截图已复制到剪贴板 ✅")
        } else {
            showError("复制失败", message: "无法写入剪贴板")
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
        let pb = NSPasteboard.general
        pb.clearContents()
        return pb.setData(png, forType: .png)
    }
    
    func cleanup(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = message
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
    
    func showError(_ title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert(); alert.messageText = title
            alert.informativeText = message; alert.runModal()
        }
    }
}
