import SwiftUI
import AppKit

@MainActor
final class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?
    
    private init() {}
    
    func show(engine: TimerEngine, settings: TimerSettings) {
        if let existing = window {
            existing.title = settings.l10n.settingsTitle
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = SettingsSheet(engine: engine, settings: settings) { [weak self] in
            self?.close()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = settings.l10n.settingsTitle
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
    
    func updateTitle(settings: TimerSettings) {
        window?.title = settings.l10n.settingsTitle
    }

    func close() {
        // Match the title-bar close action and retain ownership for reopening.
        window?.close()
    }
}
