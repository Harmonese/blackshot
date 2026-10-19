import AppKit

extension Notification.Name {
    static let captureStateChanged = Notification.Name("BlackshotCaptureStateChanged")
}

@MainActor
final class ScreenshotManager {
    static let shared = ScreenshotManager()
    enum State { case idle, selecting, processing, submitting }
    private(set) var state: State = .idle {
        didSet { NotificationCenter.default.post(name: .captureStateChanged, object: nil) }
    }
    private let captureService = NativeCaptureService()
    private var work: Task<Void, Never>?
    private var stopping = false
    var onMissingPermission: (() -> Void)?

    func captureAndInvert(copyToClipboard: Bool = false) {
        guard !stopping, state == .idle else { return }
        state = .selecting
        work = Task { @MainActor in
            defer { state = .idle; work = nil }
            let outcome = await captureService.capture(copyToClipboard: copyToClipboard)
            guard !Task.isCancelled, !stopping else { return }
            switch outcome {
            case .cancelled: return
            case .failed(let reason):
                if reason == "capture.failed", !CGPreflightScreenCaptureAccess() {
                    onMissingPermission?()
                } else {
                    showFailure(reason)
                }
            case .captured(let capture):
                state = .processing
                do {
                    let input = capture.data
                    let png = try await Task.detached(priority: .userInitiated) { try ImageInverter.invert(input) }.value
                    guard !Task.isCancelled, !stopping else { return }
                    do { try RecoveryStore.shared.store(png) }
                    catch {
                        showFailure("recovery.disk", detail: error.localizedDescription)
                    }
                    state = .submitting
                    switch capture.destination {
                    case .clipboard(let count):
                        guard ScreenshotClipboard.copy(png, replacing: count) else {
                            showFailure("clipboard.changed"); return
                        }
                    case .system:
                        guard let metadata = capture.metadata else { showFailure("capture.metadata"); return }
                        let result: BSNativeSubmissionResult = await withCheckedContinuation { continuation in
                            BSSubmitNativeScreenshot(png, metadata.rect, metadata.scale, metadata.displayID,
                                metadata.isWindow, metadata.hasShadow) { continuation.resume(returning: $0) }
                        }
                        guard !Task.isCancelled, !stopping else { return }
                        if result == .failed { showFailure("native.failed") }
                        // Submitted/uncertain have no reliable save acknowledgement. No duplicate fallback.
                    }
                } catch { showFailure("image.failed") }
            }
        }
    }

    func stop() {
        stopping = true
        work?.cancel()
        captureService.cancel()
    }

    private func showFailure(_ reason: String, detail: String? = nil) {
        let message: String
        switch reason {
        case "capture.metadata": message = L("无法读取系统截图的区域或缩放信息。", "Could not read the capture region or display scale.")
        case "capture.busy": message = L("已有截图正在进行。", "A capture is already in progress.")
        case "clipboard.changed": message = L("处理期间剪贴板发生了变化，未覆盖新内容。", "The clipboard changed during processing. Its newer content was preserved.")
        case "native.failed": message = L("无法连接系统截图服务。", "Could not connect to the native screenshot service.")
        case "recovery.disk": message = L("无法将恢复图片写入磁盘；图片仅在本次运行中可恢复。", "Could not save recovery data to disk. The image is available only during this run.")
        case "image.failed": message = L("无法处理截图。", "Could not process the screenshot.")
        default: message = L("系统截图未能完成，请检查屏幕录制权限后重试。", "The capture failed. Check Screen Recording permission and try again.")
        }
        let alert = NSAlert()
        alert.messageText = L("截图未能完成", "Screenshot Could Not Be Completed")
        alert.informativeText = message + (detail.map { "\n\n" + $0 } ?? "") +
            (RecoveryStore.shared.data != nil ? L("\n\n可从菜单中的“恢复最近截图…”复制或另存最近的反色结果。", "\n\nUse Recover Latest Screenshot… in the menu to copy or save the latest inverted result.") : "")
        alert.alertStyle = .warning
        alert.runModal()
    }
}
