import SwiftUI
import AppKit

@MainActor
final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private weak var engine: TimerEngine?
    private weak var settings: TimerSettings?
    private var contextMenu: NSMenu?
    
    override private init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTitle()
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTitle()
            }
        }
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
                setupStatusItemButton()
                buildContextMenu()
            }
            updateTitle()
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }
    
    private func setupStatusItemButton() {
        guard let button = statusItem?.button else { return }
        button.target = self
        button.action = #selector(onMenuBarItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc private func onMenuBarItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            MainWindowController.shared.toggleVisibility()
            return
        }
        
        if event.type == .rightMouseUp {
            // 右クリック時はサブメニューを表示
            if let menu = contextMenu {
                statusItem?.menu = menu
                statusItem?.button?.performClick(nil)
                statusItem?.menu = nil // 次回左クリックのために即座に解除
            }
        } else {
            // 左クリック時はアプリ本体ウィンドウをそのまま開く/トグル
            MainWindowController.shared.toggleVisibility()
        }
    }
    
    func updateTitle() {
        guard let button = statusItem?.button, let settings = settings else { return }
        let logManager = ActivityLogManager.shared
        
        let isRunning = engine?.isRunning ?? false
        let progress = CGFloat(engine?.progress ?? 1.0)
        let theme = settings.theme
        let iconName = isRunning ? "timer" : "stopwatch"
        
        switch settings.menuBarFormat {
        case .pieChartOnly:
            button.image = generatePieChartImage(progress: progress, theme: theme, isRunning: isRunning)
            button.imagePosition = .imageOnly
            button.title = ""
            
        case .pieChartWithRemaining:
            button.image = generatePieChartImage(progress: progress, theme: theme, isRunning: isRunning)
            button.imagePosition = .imageLeading
            let remSecs = Int(engine?.remainingTime ?? 0)
            let mins = remSecs / 60
            let secs = remSecs % 60
            button.title = String(format: " %02d:%02d", mins, secs)
            
        case .english:
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VisualBarTimer")
            button.imagePosition = .imageLeading
            button.title = " \(logManager.todayFormattedM)"
            
        case .japanese:
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VisualBarTimer")
            button.imagePosition = .imageLeading
            button.title = " \(logManager.todayFormattedMin)"
            
        case .numberOnly:
            button.image = nil
            button.title = logManager.todayFormattedNumeric
            
        case .iconOnly:
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VisualBarTimer")
            button.imagePosition = .imageOnly
            button.title = ""
        }
        
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
    }
    
    /// リアルタイム円グラフ（プログレスサークル）の動的描画
    private func generatePieChartImage(progress: CGFloat, theme: TimerTheme, isRunning: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { dstRect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            
            let center = CGPoint(x: dstRect.midX, y: dstRect.midY)
            let radius: CGFloat = 7.0
            let lineWidth: CGFloat = 2.4
            
            // 1. 背景消灯トラック (未点灯の薄いリング枠)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.22).cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
            ctx.strokePath()
            
            // 2. 残り時間の円弧（カラー連動）
            let clampedProgress = max(0, min(1.0, progress))
            if clampedProgress > 0.005 {
                let color: NSColor
                if theme == .monochrome {
                    color = .white
                } else {
                    // LEDバーと同じ割合で色変化 (緑 -> 黄 -> 赤)
                    if clampedProgress > 0.5 {
                        color = NSColor(red: 0.2, green: 0.88, blue: 0.45, alpha: 1.0) // 鮮やかな緑
                    } else if clampedProgress > 0.2 {
                        color = NSColor(red: 1.0, green: 0.82, blue: 0.2, alpha: 1.0)  // 鮮やかな黄
                    } else {
                        color = NSColor(red: 1.0, green: 0.28, blue: 0.28, alpha: 1.0) // 鮮やかな赤
                    }
                }
                
                // 12時の位置 (pi / 2) から時計回りに progress 分の円弧
                let startAngle: CGFloat = CGFloat.pi / 2.0
                let endAngle: CGFloat = startAngle - (CGFloat.pi * 2.0 * clampedProgress)
                
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.round)
                ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                ctx.strokePath()
                
                // 扇形の内側を薄く発光塗りつぶし
                let fillPath = CGMutablePath()
                fillPath.move(to: center)
                fillPath.addArc(center: center, radius: radius - lineWidth / 2.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                fillPath.closeSubpath()
                ctx.setFillColor(color.withAlphaComponent(0.28).cgColor)
                ctx.addPath(fillPath)
                ctx.fillPath()
            }
            return true
        }
        
        image.isTemplate = false // カラーを正確に表示
        return image
    }
    
    private func buildContextMenu() {
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
        
        self.contextMenu = menu
    }
    
    @objc private func showMainWindow() {
        MainWindowController.shared.show()
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
