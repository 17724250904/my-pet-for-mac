//
//  AppDelegate.swift
//  DesktopPet
//
//  Created by 李瑞华 on 2025/7/4.
//
//  这个文件负责应用程序的生命周期和主窗口的创建/管理。
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow! // 声明一个变量来持有我们的宠物窗口实例

    // 当应用程序启动完成时调用
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. 获取主屏幕的尺寸
        let screenFrame = NSScreen.main?.frame ?? .zero // 如果获取不到主屏幕，则默认使用 (0,0,0,0) 的矩形

        // 2. 创建一个全屏的窗口矩形
        let windowRect = NSRect(x: 0, y: 0, width: screenFrame.width, height: screenFrame.height)

        // 3. 初始化 NSWindow
        window = NSWindow(contentRect: windowRect, // 窗口内容区域的尺寸和位置
                          styleMask: .borderless, // 设置窗口样式为“无边框”
                          backing: .buffered, // 缓冲区类型
                          defer: false) // 是否延迟创建后备存储

        // 4. 设置窗口的透明度属性
        window.backgroundColor = .clear // 设置窗口背景色为完全透明，这是实现透明窗口的关键

        // 5. 设置窗口的层级，使其始终在其他应用程序之上
        // .floating 是一个常见的选择，它会浮动在普通窗口之上
        // 你也可以尝试更高的层级，例如 .popover 或直接使用 Int(CGWindowLevelKey.overlayWindow.rawValue) + 1
        window.level = .floating

        // 6. 设置窗口的集合行为，使其在所有桌面空间中可见且不激活
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        // .canJoinAllSpaces: 窗口可以在所有桌面空间（Spaces）中显示
        // .stationary: 窗口不会在 Mission Control 中随其他窗口移动
        // .ignoresCycle: 防止窗口在应用程序之间切换时被激活，这有助于实现点击穿透
        
        window.canHide = false // 防止用户通过 Cmd+H 隐藏应用窗口

        // 7. 设置窗口默认不忽略鼠标事件（这样我们自定义的 hitTest 方法才能生效）
        // 我们需要窗口能够接收事件，然后在 hitTest 中决定是否让事件穿透
        window.ignoresMouseEvents = false

        // 8. 创建一个自定义的 NSView (TransparentDrawingView) 并将其设置为窗口的内容视图
        // TransparentDrawingView 负责宠物的绘制、动画和精确点击穿透逻辑
        let customView = TransparentDrawingView(frame: windowRect)
        window.contentView = customView

        // 9. 显示窗口并使其成为关键窗口（接收键盘事件）和前台窗口
        window.makeKeyAndOrderFront(nil)
        
        // 10. 强制应用程序激活并置于最前（确保我们的窗口被看到）
        NSApp.activate(ignoringOtherApps: true)

        // --- 隐藏可能存在的默认（带标题栏）窗口 ---
        // 理论上，如果 Info.plist 配置正确，这里不会有其他窗口。
        // 但作为额外保障，这个逻辑会在应用程序启动后短暂延迟执行，隐藏任何非我们创建的可见窗口。
        DispatchQueue.main.async {
            for appWindow in NSApp.windows {
                // 如果这个窗口不是我们刚刚创建的桌宠窗口，并且它当前是可见的
                if appWindow != self.window && appWindow.isVisible {
                    appWindow.orderOut(nil) // 隐藏这个窗口
                    print("AppDelegate: 隐藏了不需要的窗口: \(appWindow.title ?? "无标题窗口")") // 调试信息
                }
            }
        }
    }

    // 当应用程序的所有窗口都关闭后，是否应该终止应用程序
    // 这里设置为 true，表示当用户关闭我们的宠物窗口时，应用就退出
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
