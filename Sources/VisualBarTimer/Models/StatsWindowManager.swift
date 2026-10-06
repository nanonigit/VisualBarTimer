import SwiftUI
import AppKit

@MainActor
final class StatsWindowManager {
    static let shared = StatsWindowManager()
    private var window: NSWindow?
    
    private init() {}
    
    private var currentTitle: String {
        let rawLang = UserDefaults.standard.string(forKey: "saved_language")
        let lang = rawLang.flatMap { AppLanguage(rawValue: $0) } ?? .english
        return L10n(language: lang).statsWindowTitle
    }

    func show() {
        if let existing = window {
            existing.title = currentTitle
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = StatsWindowView { [weak self] in
            self?.close()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = currentTitle
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.level = .floating
        newWindow.isMovableByWindowBackground = true
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateTitle() {
        window?.title = currentTitle
    }

    func close() {
        // Match the title-bar close action and retain ownership for reopening.
        window?.close()
    }
}
