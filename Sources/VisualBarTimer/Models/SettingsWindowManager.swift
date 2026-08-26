import SwiftUI
import AppKit

final class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?
    
    private init() {}
    
    func show(engine: TimerEngine, settings: TimerSettings) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = SettingsSheet(engine: engine, settings: settings) { [weak self] in
            self?.close()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 510),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "タイマー設定"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.level = .floating
        newWindow.isMovableByWindowBackground = true
        newWindow.titleVisibility = .visible
        newWindow.titlebarAppearsTransparent = false
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.orderOut(nil)
        window = nil
    }
}
