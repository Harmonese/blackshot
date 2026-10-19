# Blackshot

<img src="./icon.png" alt="Blackshot" width="96">

macOS 菜单栏截图工具：**原生选区 / 窗口截图 → 自动反色 → 系统原生缩略图、标注和保存**。

当前准备版本：**1.2.0**。系统要求：**macOS 12 Monterey 或更新版本，Apple Silicon**。旧系统兼容性基于接口与构建检查推断，目前已在 macOS 27.2 实测。

## 使用

1. 启动 Blackshot；应用只驻留菜单栏，不显示主窗口或 Dock 图标。
2. 按 `⌘⇧6`，拖动选择截图区域。可按空格切换窗口截图，按 Option 去掉窗口阴影，按 Esc 取消。
3. 图片自动反色，随后由 macOS 显示原生浮动缩略图。可点击标注、拖拽、右键复制或删除。
4. 保存位置和缩略图开关沿用系统截图设置（`⌘⇧5` → 选项）。Blackshot 不修改这些设置，也不额外自动复制或发送成功通知。

按 `⌃⌘⇧6`，或在选区完成时按住 Control 松开鼠标，可直接得到剪贴板中的反色图片；此时不额外显示缩略图。取消截图不会提前清空剪贴板。

## 菜单

- **截图并反色**：进入系统截图。
- **快捷键设置…**：点击录入框并按新组合，立即保存；可恢复默认。基础组合必须包含 Command，可配合 Shift、Option；Control 专用于复制分支。注册冲突时保留原快捷键。
- **恢复最近截图…**：有恢复数据时出现，提供复制、另存和丢弃。只保留最近一张反色图片，最长 24 小时，不建立截图历史。
- **检查权限**、**语言**（英文界面显示 **Language**）、**退出**。

首次截图需要**屏幕录制权限**。在系统设置 → 隐私与安全性 → 屏幕与系统音频录制中允许 Blackshot，随后重启应用。不需要辅助功能和通知权限。

如果已允许却仍无法截图，请检查授权项是否指向旧版应用：右键 Blackshot → 在访达中显示。移除旧授权项，通过“＋”重新添加当前 `build/Blackshot.app`，允许后退出并重新打开这份应用。测试期间请始终启动同一路径的应用，避免混用旧的 Xcode 构建。

## 当前支持情况

- 最低构建目标：macOS 12.0，架构 arm64；macOS 12–26 预计兼容，尚未实测。本次实际验证：macOS 27.2（26B5112a）、Apple Silicon、内置 2× 屏幕。
- 输出为 SDR PNG，RGB 反色，保留透明度、像素尺寸和 DPI；暂不支持 HDR 反色、全屏截图入口或录屏。
- 已在独立原型验证：原生缩略图、标注保存、窗口截图拖拽与阴影、两种 Control 用法、右键复制及删除。右键复制后的图片与输入反色图逐像素一致。
- 已在签名的正式应用验证：默认快捷键进入系统选区，完成后出现反色原生缩略图；Esc 取消保留剪贴板；两种 Control 用法均复制反色图片。旧授权记录问题通过重新添加当前应用解决。
- 正式应用的快捷键修改、重启记忆、恢复默认，以及最近截图恢复复制均已通过交互验证。
- macOS 12–26、外接屏幕和混合缩放仍待验证；Intel 版本暂不提供。最终应用的交互验收及权限状态见 [验证记录](Experiments/NativeScreenshotBridge/README.md)。

**此版本调用系统内部截图服务 `com.apple.screencaptureui`，没有公开兼容性承诺。** 当前预发布包使用 Apple Development 签名，尚未公证；其他 Mac 的首次启动可能被 Gatekeeper 阻止。关闭 App Sandbox，保留 Hardened Runtime；不是 Mac App Store 发行方案。不修改或注入系统进程，不关闭系统保护。

服务没有可靠的保存成功回执。Blackshot 不自动重试或重复保存；如果没有出现预期结果，可从菜单恢复最近截图。仅凭 `Connection interrupted` 不能判断交接失败。

## 构建与验证

无第三方依赖，使用 Xcode 与 Apple 框架：

```sh
xcodebuild -project Blackshot.xcodeproj -scheme Blackshot -configuration Debug -destination 'platform=macOS' build
xcodebuild -project Blackshot.xcodeproj -scheme Blackshot -configuration Release -destination 'platform=macOS' build
./Experiments/NativeScreenshotBridge/validate.sh --self-test
./Experiments/NativeScreenshotBridge/validate.sh --capture
```

构建需本机有效的 Apple Development 签名配置。本地测试应用位于 `build/Blackshot.app`；预发布 ZIP 和 SHA-256 校验文件位于 `build/releases/`，均不进入 Git。分发签名、公证和发布步骤见 [发布准备](docs/RELEASE.md)，版本改动见 [CHANGELOG](CHANGELOG.md)。

## English

Blackshot stays in the menu bar. Press `⌘⇧6` to select a region, or Space to capture a window. It inverts the screenshot and hands it to the native macOS screenshot UI for thumbnails, markup, drag and drop, copying, deletion, and saving. Native screenshot preferences apply.

Use Control with the shortcut, or hold Control when completing the selection, to copy the inverted screenshot directly. Choose Shortcut Settings… to change the shortcut; Command is required and Control is reserved for copying. Recover Latest Screenshot… keeps one inverted result for up to 24 hours.

Screen Recording permission is required; Accessibility and notification permissions are not. Version 1.2.0 targets macOS 12 or newer on Apple Silicon (arm64). Compatibility with macOS 12–26 is inferred from API availability and build checks; only macOS 27.2 has been tested interactively. Intel Macs, external displays and mixed display scales remain unverified. This build relies on an undocumented native service, runs outside App Sandbox with Hardened Runtime, and outputs SDR PNG. The local prerelease uses Apple Development signing and is not notarized; Gatekeeper may block it on another Mac. See the [release checklist](docs/RELEASE.md) and [changelog](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE). Author: [Harmonese](https://github.com/Harmonese).
