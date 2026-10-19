# Blackshot

<div align="center">
  <img src="./icon.png" alt="Blackshot Icon" width="128">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2012%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</div>

> **English | [中文说明](#blackshot-中文版)**

---

## 🪶 Overview

**Blackshot** is a lightweight macOS menu bar utility that lets you quickly take screenshots and automatically invert their colors.
Perfect for designers or developers who frequently switch between light and dark content.

## ✨ Features

- **Global Shortcut:** Trigger with `⌘⇧6` (Command + Shift + 6), or set your own shortcut
- **Auto Invert:** Automatically inverts all colors after screenshot
- **Clipboard Integration:** Hold Control with the shortcut or when completing a selection to copy the inverted image
- **Native Screenshot Workflow:** Use the macOS thumbnail to mark up, drag, copy, delete or save the inverted screenshot
- **Recovery:** Recover the latest inverted screenshot for up to 24 hours
- **Menu Bar Resident:** Stays quietly in the menu bar, not in the Dock
- **Performance Optimized:** Asynchronous processing, no UI blocking

## 📋 System Requirements

- macOS 12 Monterey or later on Apple Silicon (arm64)
- Requires the following permissions:
  - **Screen Recording** (for screenshot functionality)

> Tested on macOS 27.2. macOS 12–26 compatibility is inferred and awaits user feedback. Native thumbnail integration uses an undocumented system interface.

## 🚀 Installation

### Option 1: Download Prebuilt Release

1. Download the macOS arm64 `.zip` from [Releases](https://github.com/Harmonese/blackshot/releases)
2. Extract the `.zip` and move **Blackshot.app** into your Applications folder
3. On first capture, grant Screen Recording permission as prompted

> The current build uses Apple Development signing and is not notarized. macOS may block first launch on another Mac.

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/Harmonese/blackshot.git
cd blackshot

# Open in Xcode
open Blackshot.xcodeproj

# Build and Run
```

## 🎯 Usage

### Basic Usage

1. Launch Blackshot — a camera icon appears in the menu bar
2. Press `⌘⇧6`
3. Select an area using macOS’s native screenshot tool; press Space to capture a window or Esc to cancel
4. The image is automatically inverted and handed to the native macOS screenshot thumbnail
5. Click the thumbnail to mark up, drag it elsewhere, or use its menu to copy, delete or save

Hold Control with the shortcut or when completing the selection to copy directly, then paste with `⌘V`. Save location and thumbnail visibility follow the system screenshot options (`⌘⇧5`).

### Menu Options

* **Capture & Invert (⌘⇧6)** – Trigger manually
* **Shortcut Settings…** – Change the shortcut or restore the default
* **Recover Latest Screenshot…** – Copy, save or discard the latest inverted image; shown when recovery is available
* **Check Permissions** – Verify Screen Recording permission
* **Language** – Switch between English and Chinese
* **Quit** – Exit the app

## 🔐 Permissions

Blackshot requires Screen Recording permission for capture. Accessibility and notification permissions are not required.

### Screen Recording

1. Go to **System Settings → Privacy & Security → Screen Recording**
2. Enable **Blackshot**

> 💡 Restart the app after granting permission. If access is enabled but capture still fails, remove the stale Blackshot permission entry, add the installed app again and restart.

## 📄 License

Licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## 👤 Author

[@Harmonese](https://github.com/Harmonese)

---

# Blackshot 中文版

<div align="center">
  <img src="./icon.png" alt="Blackshot Icon" width="128">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2012%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</div>

一个轻量级的 macOS 菜单栏工具，让你快速截图并自动反转颜色。完美适用于需要在深色和浅色内容之间切换的场景。

## ✨ 功能特性

* **全局快捷键**: 使用 `⌘⇧6` (Command + Shift + 6) 快速触发，也可自定义组合
* **自动反转**: 截图后自动反转所有颜色
* **剪贴板集成**: 触发快捷键或完成选区时按住 Control，直接复制反色图片
* **原生截图流程**: 通过 macOS 原生缩略图标注、拖拽、复制、删除和保存反色图片
* **最近截图恢复**: 最近一张反色结果最多保留 24 小时，可手动恢复
* **菜单栏常驻**: 简洁的菜单栏图标，不占用 Dock 空间
* **性能优化**: 异步处理，不影响系统响应速度

## 📋 系统要求

* macOS 12 Monterey 或更高版本，Apple Silicon (arm64)
* 需要授予以下权限：

  * **屏幕录制权限** (用于截图功能)

> 已在 macOS 27.2 实测；macOS 12–26 为推断兼容，待用户反馈验证。原生缩略图交接使用系统内部接口。

## 🚀 安装

### 方式一：下载预编译版本

1. 从 [Releases](https://github.com/Harmonese/blackshot/releases) 页面下载 macOS arm64 `.zip` 文件
2. 解压 `.zip`，将 **Blackshot.app** 移入应用程序文件夹
3. 首次截图时，按照提示授予屏幕录制权限

> 当前构建使用 Apple Development 签名，尚未公证，在其他 Mac 上首次启动可能被系统阻止。

### 方式二：从源码编译

```bash
# 克隆仓库
git clone https://github.com/Harmonese/blackshot.git
cd blackshot

# 使用 Xcode 打开项目
open Blackshot.xcodeproj

# 在 Xcode 中编译运行
```

## 🎯 使用方法

### 基本使用

1. 启动 Blackshot，应用会在菜单栏显示相机图标
2. 按下 `⌘⇧6` 快捷键
3. 使用系统截图工具选择区域；按空格切换窗口截图，按 Esc 取消
4. 截图自动反色后，交由 macOS 原生缩略图处理
5. 点击缩略图进行标注、拖到其他位置，或通过其菜单复制、删除和保存

触发快捷键或完成选区时按住 Control，可直接复制，再按 `⌘V` 粘贴。保存位置和缩略图开关沿用系统截图选项（`⌘⇧5`）。

### 菜单选项

* **截图并反色 (⌘⇧6)**: 手动触发截图功能
* **快捷键设置…**: 自定义快捷键或恢复默认
* **恢复最近截图…**: 复制、另存或丢弃最近反色结果；有缓存时显示
* **检查权限**: 检查屏幕录制权限
* **语言**: 切换中文和英文
* **退出**: 关闭应用

## 🔐 权限设置

Blackshot 仅需屏幕录制权限进行截图，不需要辅助功能或通知权限。

### 屏幕录制权限

1. 打开 **系统设置** > **隐私与安全性** > **屏幕录制**
2. 找到并勾选 **Blackshot**

> 💡 授予权限后，请重启应用。如果已允许却仍截图失败，请移除旧的 Blackshot 权限项，重新添加当前安装的应用并重启。

## 📄 开源协议

本项目采用 MIT 协议 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👤 作者

[@Harmonese](https://github.com/Harmonese)
