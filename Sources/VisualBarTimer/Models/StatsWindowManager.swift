import SwiftUI
import AppKit

@MainActor
final class StatsWindowManager {
    static let shared = StatsWindowManager()
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = StatsWindowView { [weak self] in
            self?.close()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "タイマー稼働統計・ログエクスポート"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.level = .floating
        newWindow.isMovableByWindowBackground = true
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.orderOut(nil)
        window = nil
    }
}
