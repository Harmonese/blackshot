import AppKit
import UniformTypeIdentifiers

extension Notification.Name {
    static let recoveryChanged = Notification.Name("BlackshotRecoveryChanged")
    static let shortcutChanged = Notification.Name("BlackshotShortcutChanged")
}

@MainActor
final class RecoveryStore {
    static let shared = RecoveryStore()
    static let lifetime: TimeInterval = 24 * 60 * 60
    private let file: URL
    private var expiration: Timer?
    private var memory: (data: Data, date: Date)?

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Blackshot/Recovery", isDirectory: true)
        file = base.appendingPathComponent("latest.png")
        refresh()
    }

    var data: Data? {
        refresh()
        return memory?.data
    }

    func store(_ data: Data) throws {
        memory = (data, Date())
        scheduleExpiration()
        NotificationCenter.default.post(name: .recoveryChanged, object: nil)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        // Never leave a second history entry behind.
        try data.write(to: file, options: .atomic)
    }

    func discard() throws {
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        memory = nil
        expiration?.invalidate()
        expiration = nil
        NotificationCenter.default.post(name: .recoveryChanged, object: nil)
    }

    private func refresh() {
        if memory == nil,
           let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
           let data = try? Data(contentsOf: file) {
            memory = (data, date)
        }
        guard let memory else { return }
        if Date().timeIntervalSince(memory.date) >= Self.lifetime {
            try? discard()
            self.memory = nil
        } else if expiration == nil {
            scheduleExpiration()
        }
    }

    private func scheduleExpiration() {
        expiration?.invalidate()
        guard let date = memory?.date else { return }
        expiration = Timer.scheduledTimer(withTimeInterval: max(1, Self.lifetime - Date().timeIntervalSince(date)), repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in try? self.discard() }
        }
    }

    func showRecovery() {
        guard let png = data else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = L("恢复最近截图", "Recover Latest Screenshot")
        alert.informativeText = L("可恢复最近一张反色图片，最多保留 24 小时。", "The latest inverted image is available for up to 24 hours.")
        [L("复制", "Copy"), L("另存为…", "Save As…"), L("丢弃", "Discard"), L("取消", "Cancel")].forEach { alert.addButton(withTitle: $0) }
        do {
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                if !ScreenshotClipboard.copy(png) { throw CocoaError(.fileWriteUnknown) }
            case .alertSecondButtonReturn:
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.png]
                panel.nameFieldStringValue = "Blackshot.png"
                if panel.runModal() == .OK, let url = panel.url { try png.write(to: url, options: .atomic) }
            case .alertThirdButtonReturn: try discard()
            default: break
            }
        } catch {
            let failure = NSAlert()
            failure.messageText = L("无法完成恢复操作", "Could Not Complete Recovery")
            failure.informativeText = error.localizedDescription
            failure.runModal()
        }
    }
}
