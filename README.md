# 🐟 macOS 桌面宠物项目文档 | DesktopPet

> 让你的 Mac 桌面从此不再孤单！快来拥有自己的数字萌宠吧 🪟✨

---

## 1. 项目概述

这是一个基于 **Swift** 和 **Apple AppKit** 框架开发的 macOS 桌面宠物应用。  
它旨在为开发者和 Mac 爱好者提供一个**超轻量、交互性强**的桌面伴侣，  
让你的电脑屏幕瞬间活泼起来，不影响日常工作，超级治愈 😍！

---

### 🚀 主要特性

- 🪟 **无边框、全屏、透明窗口**：宠物完美融入你的桌面，像贴纸一样悬浮。
- 👀 **始终置顶**：总能看到它的身影，再也不怕被别的窗口“欺负”。
- 🦾 **像素级鼠标穿透**：只有你“真的点到”宠物，它才会理你；透明处随你操作桌面。
- 🐾 **流畅动画**：高性能 Core Graphics + CVDisplayLink，帧率拉满不卡顿。
- 🖱️ **自由拖动**：抓住宠物，带它遨游屏幕每一个角落。
- 🏎️ **性能优化**：批量图形绘制，15000点也能高效低耗能运行。

---

## 2. 技术栈

|         |         |
| ------- | ------- |
| **语言** | Swift |
| **开发环境** | Xcode |
| **框架** | AppKit / Core Graphics / Core Services |
| **数学库** | Foundation / CoreGraphics 内置函数 |

---

## 3. 核心功能实现原理

### 🪟 3.1 透明、无边框、置顶窗口

- `.borderless` NSWindow，彻底无边框。
- `window.backgroundColor = .clear`，`window.isOpaque = false`，透明到底。
- `window.level = .floating`，永远在最上层。
- `window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]`，多桌面、多空间永不丢失。
- **绝无 Storyboard**！`AppDelegate` 代码动态创建主窗口，避免莫名其妙的多余界面。
- 遇到 Xcode 不听话？`DispatchQueue.main.async` 兜底隐藏残留窗口。

---

### 🦾 3.2 像素级鼠标点击穿透（行业天花板！）

- `NSTrackingArea` 捕捉鼠标每次移动，实时响应。
- 智能切换 `window.ignoresMouseEvents`：
  - 🎯 点在宠物身体：宠物响应（可拖拽、交互）。
  - 🕳️ 点在透明区：事件秒穿透，桌面随便点。
- `hitTest(_:)` 精确判断事件归属，`isPixelOpaque(at:in:)` 只看不透明像素。
- 让桌宠**“只在该在的时候在”**，你工作它不打扰，你想撸它它马上到。

---

### 🏎️ 3.3 流畅动画和高性能绘制

- `CVDisplayLink` 保证动画刷新和系统帧率同步，超丝滑。
- `updatePetImageCache()` 图像缓存优化：
  - 15000点的“鱼形”宠物用 `CGMutablePath` 一次性批量绘制，CPU 轻松无压力。
  - 只在状态改变时重绘，其余时候直接复用缓存。
- `draw(_:)` 只管高效渲染预生成 CGImage。
- `cachedPetScreenPoints` 缓存所有点，省时省力不重复运算。

---

## 4. 如何设置和运行

> 📦 **五步即可拥有你的专属桌宠！**

### 🧩 4.1 前提条件

- 🍏 **macOS**（建议最新版）
- 🛠️ **Xcode**（最新版，App Store 免费）

### 📝 4.2 创建新项目

1. 打开 Xcode
2. `Create a new Xcode project` ➡️ **macOS** ➡️ **App** ➡️ Next
3. 配置选项：
    - Product Name: `DesktopPet`（或自定义）
    - Organization Identifier: 如 `com.yourname`
    - **Interface: None**（重点！千万别选 Storyboard！）
    - Life Cycle: AppKit App Delegate
    - Language: Swift
    - Include: 全部取消
4. Next ➡️ 选择保存路径 ➡️ Create

### 🗂️ 4.3 替换代码文件

- 用下方 `AppDelegate.swift` 代码完全替换同名文件。
- 新建 Cocoa Class：  
  - Class: `TransparentDrawingView`  
  - Subclass: `NSView`  
  - 取消 XIB  
  - Language: Swift  
- 用下方 `TransparentDrawingView.swift` 代码完全替换文件内容。


### 🧹 4.4 清理 & 运行

- 保存全部文件
- Product > Clean Build Folder (`Shift + Cmd + K`)
- （可选）Product > Clean (`Cmd + Shift + Option + K`)
- 左上角 ▶️ 运行，见证桌宠奇迹诞生！

---

## 5. 代码结构概览

- **AppDelegate.swift**
    - 程序入口
    - 主窗口透明/置顶/无边框
    - 加载 TransparentDrawingView
    - 隐藏冗余窗口

- **TransparentDrawingView.swift**
    - 继承 `NSView`，负责所有自定义图形、动画、交互
    - draw(_:) 渲染宠物
    - updatePetState() 更新物理状态
    - updatePetImageCache() 图像缓存与优化
    - hitTest(_:)、isPixelOpaque(at:in:) 实现像素级穿透
    - mouseDown/Dragged/Up: 拖动宠物
    - updateTrackingAreas()、mouseMoved(with:) 动态穿透
    - setupDisplayLink() 动画驱动

---

## 6. 常见问题 Q&A

- **🚫 启动后没有桌宠/有标题栏？**  
  通常是 Main Interface 设置未清空，或有遗留 Storyboard。回看 4.4、4.5！

- **🌀 穿透卡顿/有延迟？**  
  极端情况可以调低点数（如 500/1000 测试）。检查代码是不是完整覆盖，updatePetImageCache 是否有误。

- **❌ 拖动无效？**  
  window.ignoresMouseEvents 必须能被正确切换。hitTest(_:) 返回逻辑要正确！

- **🛠️ 编译报错？**  
  - `'isOpaque' is a get-only property`：注释或删掉 self.isOpaque = false。
  - `'cachedPetScreenPoints'` not found：请确保完整替换了 TransparentDrawingView.swift！

---

## 7. 🌈 未来进阶玩法

- 🎨 自定义宠物形象（支持 PNG 头像上传）
- 🤹‍♂️ 更多宠物动作与 AI 互动（点它、拖它有新反应）
- 🛎️ 菜单栏控制（隐藏/退出/设置随时切）
- ⚙️ 偏好设置窗口（自由调节速度、大小、行为）
- 🖥️ 多桌面完美支持

---

> 🏁 **用代码点亮生活，桌宠与你常在！**  
> _喜欢本项目？欢迎 star 🌟、fork 🍴、提出你的奇思妙想！_

---


