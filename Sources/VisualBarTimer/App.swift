import SwiftUI
import AppKit

@main
struct VisualBarTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class MainWindowController {
    static let shared = MainWindowController()
    
    var window: NSWindow?
    let engine = TimerEngine()
    let settings = TimerSettings()
    
    func setupAndShow() {
        if window != nil {
            show()
            return
        }
        
        let dims = settings.size.windowDimensions(orientation: settings.orientation)
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        
        var targetX: CGFloat
        var targetY: CGFloat
        
        if UserDefaults.standard.object(forKey: "saved_window_x") != nil,
           UserDefaults.standard.object(forKey: "saved_window_y") != nil {
            targetX = CGFloat(UserDefaults.standard.double(forKey: "saved_window_x"))
            targetY = CGFloat(UserDefaults.standard.double(forKey: "saved_window_y"))
            
            targetX = max(visible.minX - dims.width + 50, min(visible.maxX - 50, targetX))
            targetY = max(visible.minY + 20, min(visible.maxY - dims.height, targetY))
        } else {
            targetX = visible.origin.x + (visible.size.width - dims.width) / 2.0
            targetY = visible.origin.y + (visible.size.height - dims.height) * 0.65
        }
        
        let contentView = MainTimerView(engine: engine, settings: settings)
        let hostingController = NSHostingController(rootView: contentView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: targetX, y: targetY, width: dims.width, height: dims.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "VisualBarTimer"
        newWindow.contentViewController = hostingController
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.isMovableByWindowBackground = true
        newWindow.level = settings.isAlwaysOnTop ? .floating : .normal
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.isReleasedWhenClosed = false
        
        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: newWindow, queue: .main) { notif in
            if let win = notif.object as? NSWindow {
                UserDefaults.standard.set(Double(win.frame.origin.x), forKey: "saved_window_x")
                UserDefaults.standard.set(Double(win.frame.origin.y), forKey: "saved_window_y")
            }
        }
        
        self.window = newWindow
        MenuBarManager.shared.setup(engine: engine, settings: settings)
        
        if settings.startHidden && settings.showInMenuBar {
            newWindow.orderOut(nil)
        } else {
            newWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func show() {
        guard let win = window else {
            setupAndShow()
            return
        }
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func toggleVisibility() {
        guard let win = window else {
            setupAndShow()
            return
        }
        if win.isVisible && NSApp.isActive {
            hide()
        } else {
            show()
        }
    }
    
    func updateFrame(animate: Bool = true) {
        guard let win = window else { return }
        let dims = settings.size.windowDimensions(orientation: settings.orientation)
        var currentFrame = win.frame
        let oldTop = currentFrame.origin.y + currentFrame.size.height
        
        currentFrame.size = CGSize(width: dims.width, height: dims.height)
        currentFrame.origin.y = oldTop - dims.height
        
        if let screen = win.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            if currentFrame.maxX > visible.maxX + (dims.width - 40) {
                currentFrame.origin.x = visible.maxX - currentFrame.size.width
            }
            if currentFrame.minX < visible.minX - (dims.width - 40) {
                currentFrame.origin.x = visible.minX
            }
        }
        
        win.setFrame(currentFrame, display: true, animate: animate)
        UserDefaults.standard.set(Double(currentFrame.origin.x), forKey: "saved_window_x")
        UserDefaults.standard.set(Double(currentFrame.origin.y), forKey: "saved_window_y")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MainWindowController.shared.setupAndShow()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindowController.shared.show()
        return true
    }
}
