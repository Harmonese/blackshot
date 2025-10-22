# Blackshot

<div align="center">
  <img src="./icon.png" alt="Blackshot Icon" width="128">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2026%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</div>

> **English | [中文说明](#blackshot-中文版)**

---

## 🪶 Overview

**Blackshot** is a lightweight macOS menu bar utility that lets you quickly take screenshots and automatically invert their colors.  
Perfect for designers or developers who frequently switch between light and dark content.

## ✨ Features

- **Global Shortcut:** Trigger instantly with `⌘⇧6` (Command + Shift + 6)
- **Auto Invert:** Automatically inverts all colors after screenshot
- **Clipboard Integration:** Processed image is automatically copied to the clipboard
- **Notifications:** Sends a system notification when done
- **Menu Bar Resident:** Stays quietly in the menu bar, not in the Dock
- **Performance Optimized:** Asynchronous processing, no UI blocking

## 📋 System Requirements

- macOS 26 or later
- Requires the following permissions:
  - **Accessibility** (to monitor global hotkeys)
  - **Screen Recording** (for screenshot functionality)

## 🚀 Installation

### Option 1: Download Prebuilt Release

1. Download the latest `.dmg` file from the [Releases] page  
2. Open the `.dmg` and drag **Blackshot** into your Applications folder  
3. On first launch, grant the required system permissions as prompted

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/Harmonese/blackshot.git
cd blackshot

# Open in Xcode
open Blackshot.xcodeproj

# Build and Run
````

## 🎯 Usage

### Basic Usage

1. Launch Blackshot — a camera icon appears in the menu bar
2. Press `⌘⇧6`
3. Select a capture area using macOS’s native screenshot tool
4. The image is automatically inverted and copied to clipboard
5. Paste anywhere with `⌘V`

### Menu Options

* **Capture & Invert (⌘⇧6)** – Trigger manually
* **Check Permissions** – Verify system permissions
* **Quit** – Exit the app

## 🔐 Permissions

When first launched, Blackshot automatically checks for the following permissions and prompts you to grant them:

### Accessibility

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Enable **Blackshot**

### Screen Recording

1. Go to **System Settings → Privacy & Security → Screen Recording**
2. Enable **Blackshot**

> 💡 Restart the app after granting permissions if needed.

## 📄 License

Licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## 👤 Author

[@Harmonese](https://github.com/Harmonese)

---

# Blackshot

<div align="center">
  <img src="./icon.png" alt="Blackshot Icon" width="128">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2026%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</div>

一个轻量级的 macOS 菜单栏工具，让你快速截图并自动反转颜色。完美适用于需要在深色和浅色内容之间切换的场景。

## ✨ 功能特性

* **全局快捷键**: 使用 `⌘⇧6` (Command + Shift + 6) 快速触发
* **自动反转**: 截图后自动反转所有颜色
* **剪贴板集成**: 处理后的图片自动复制到剪贴板，随时可粘贴
* **通知提醒**: 操作完成后发送系统通知
* **菜单栏常驻**: 简洁的菜单栏图标，不占用 Dock 空间
* **性能优化**: 异步处理，不影响系统响应速度

## 📋 系统要求

* macOS 26 或更高版本
* 需要授予以下权限：

  * **辅助功能权限** (用于监听全局快捷键)
  * **屏幕录制权限** (用于截图功能)

## 🚀 安装

### 方式一：下载预编译版本

1. 从 \[Releases] 页面下载最新版本的 `.dmg` 文件
2. 打开 `.dmg` 文件，将 Blackshot 拖入应用程序文件夹
3. 首次运行时，按照提示授予必要的系统权限

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
3. 使用系统截图工具选择截图区域
4. 截图完成后，颜色会自动反转并复制到剪贴板
5. 在任何应用中按 `⌘V` 粘贴使用

### 菜单选项

* **截图并反色 (⌘⇧6)**: 手动触发截图功能
* **检查权限**: 验证应用所需的系统权限是否已授予
* **退出**: 关闭应用

## 🔐 权限设置

首次运行时，Blackshot 会自动检测并提示授予以下权限：

### 辅助功能权限

1. 打开 **系统设置** > **隐私与安全性** > **辅助功能**
2. 找到并勾选 **Blackshot**

### 屏幕录制权限

1. 打开 **系统设置** > **隐私与安全性** > **屏幕录制**
2. 找到并勾选 **Blackshot**

> 💡 授予权限后，可能需要重启应用才能生效

## 📄 开源协议

本项目采用 MIT 协议 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👤 作者

[@Harmonese](https://github.com/Harmonese)
