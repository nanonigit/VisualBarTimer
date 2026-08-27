import SwiftUI
import AppKit

@MainActor
final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private weak var engine: TimerEngine?
    private weak var settings: TimerSettings?
    
    override private init() {
        super.init()
    }
    
    func setup(engine: TimerEngine, settings: TimerSettings) {
        self.engine = engine
        self.settings = settings
        updateVisibility()
    }
    
    func updateVisibility() {
        guard let settings = settings else { return }
        
        if settings.showInMenuBar {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                buildMenu()
            }
            updateTitle()
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }
    
    func updateTitle() {
        guard let button = statusItem?.button else { return }
        let logManager = ActivityLogManager.shared
        let todayText = logManager.todayFormattedDuration
        
        // 左右の余白を抑えたコンパクトな表示
        let isRunning = engine?.isRunning ?? false
        let iconName = isRunning ? "timer" : "stopwatch"
        
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VisualBarTimer")
        button.imagePosition = .imageLeading
        button.title = " \(todayText)"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
    }
    
    private func buildMenu() {
        let menu = NSMenu()
        
        let showItem = NSMenuItem(title: "タイマーを表示 / 最前面", action: #selector(showMainWindow), keyEquivalent: "t")
        showItem.target = self
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: "スタート / 一時停止", action: #selector(toggleTimer), keyEquivalent: " ")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let resetItem = NSMenuItem(title: "リセット", action: #selector(resetTimer), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let statsItem = NSMenuItem(title: "本日の稼働統計・ログ...", action: #selector(openStats), keyEquivalent: "s")
        statsItem.target = self
        menu.addItem(statsItem)
        
        let settingsItem = NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "VisualBarTimer を終了", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func showMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" && $0.title != "タイマー稼働統計・ログエクスポート" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func toggleTimer() {
        engine?.toggle()
        updateTitle()
    }
    
    @objc private func resetTimer() {
        engine?.reset()
        updateTitle()
    }
    
    @objc private func openStats() {
        StatsWindowManager.shared.show()
    }
    
    @objc private func openSettings() {
        if let eng = engine, let set = settings {
            SettingsWindowManager.shared.show(engine: eng, settings: set)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
