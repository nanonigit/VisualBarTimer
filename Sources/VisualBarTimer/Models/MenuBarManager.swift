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
                updateContextMenu()
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
        case .pieChartWithCenterTotal:
            button.image = generatePieChartImage(progress: progress, theme: theme, isRunning: isRunning, centerText: logManager.todayFormattedNumeric)
            button.imagePosition = .imageOnly
            button.title = ""
            
        case .pieChartOnly:
            button.image = generatePieChartImage(progress: progress, theme: theme, isRunning: isRunning, centerText: nil)
            button.imagePosition = .imageOnly
            button.title = ""
            
        case .pieChartWithRemaining:
            button.image = generatePieChartImage(progress: progress, theme: theme, isRunning: isRunning, centerText: nil)
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
    
    /// リアルタイム円グラフ（タイムタイマー方式: 12時から時計回りに緑が減る -> 黄が減る -> 赤が減って終了）
    private func generatePieChartImage(progress: CGFloat, theme: TimerTheme, isRunning: Bool, centerText: String?) -> NSImage {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size, flipped: false) { dstRect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            
            let center = CGPoint(x: dstRect.midX, y: dstRect.midY)
            let radius: CGFloat = 8.0
            let lineWidth: CGFloat = 2.0
            
            // 1. 背景消灯トラック (未点灯の薄いリング枠)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.20).cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
            ctx.strokePath()
            
            // 2. 時計回りマルチカラー残量円弧描画 (緑: 12時〜6時, 黄: 6時〜9時36分, 赤: 9時36分〜12時)
            let clampedProgress = max(0, min(1.0, progress))
            
            if clampedProgress > 0.005 {
                let redColor = (theme == .monochrome) ? NSColor.white : NSColor(red: 0.98, green: 0.22, blue: 0.22, alpha: 1.0)
                let yellowColor = (theme == .monochrome) ? NSColor.white : NSColor(red: 0.98, green: 0.76, blue: 0.12, alpha: 1.0)
                let greenColor = (theme == .monochrome) ? NSColor.white : NSColor(red: 0.18, green: 0.88, blue: 0.48, alpha: 1.0)
                
                // 時計回りの角度変換: fraction (0.0 = 12時, 0.5 = 6時, 1.0 = 12時)
                // Quartz座標系: 12時は pi/2, 時計回り(decreasing angle)に 2*pi*f を引く
                func angle(forFraction f: CGFloat) -> CGFloat {
                    return (CGFloat.pi / 2.0) - (CGFloat.pi * 2.0 * f)
                }
                
                func drawSegment(from fStart: CGFloat, to fEnd: CGFloat, color: NSColor) {
                    guard fEnd > fStart else { return }
                    let aStart = angle(forFraction: fStart)
                    let aEnd = angle(forFraction: fEnd)
                    
                    ctx.setStrokeColor(color.cgColor)
                    ctx.setLineWidth(lineWidth)
                    ctx.setLineCap(.butt)
                    // CoreGraphics: clockwise: true は角度減少（時計回り）
                    ctx.addArc(center: center, radius: radius, startAngle: aStart, endAngle: aEnd, clockwise: true)
                    ctx.strokePath()
                    
                    // 内側の薄い発光
                    let fillPath = CGMutablePath()
                    fillPath.move(to: center)
                    fillPath.addArc(center: center, radius: radius - lineWidth / 2.0, startAngle: aStart, endAngle: aEnd, clockwise: true)
                    fillPath.closeSubpath()
                    ctx.setFillColor(color.withAlphaComponent(centerText != nil ? 0.12 : 0.22).cgColor)
                    ctx.addPath(fillPath)
                    ctx.fillPath()
                }
                
                // 経過分（消灯開始位置）
                let elapsedFraction = 1.0 - clampedProgress
                
                // ① 緑ゾーン (0.0 〜 0.50): 12時 〜 6時 (最初に消える)
                if elapsedFraction < 0.50 {
                    let greenStart = max(0.0, elapsedFraction)
                    drawSegment(from: greenStart, to: 0.50, color: greenColor)
                }
                
                // ② 黄ゾーン (0.50 〜 0.80): 6時 〜 9時36分 (中盤に消える)
                if elapsedFraction < 0.80 {
                    let yellowStart = max(0.50, elapsedFraction)
                    drawSegment(from: yellowStart, to: 0.80, color: yellowColor)
                }
                
                // ③ 赤ゾーン (0.80 〜 1.00): 9時36分 〜 12時 (最後に消えて終了)
                if elapsedFraction < 1.00 {
                    let redStart = max(0.80, elapsedFraction)
                    drawSegment(from: redStart, to: 1.00, color: redColor)
                }
            }
            
            // 3. 円の中央に本日の累計分数を描画（指定時）
            if let text = centerText, !text.isEmpty {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                
                let fontSize: CGFloat = text.count > 2 ? 6.5 : 8.0
                let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .heavy)
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white,
                    .paragraphStyle: paragraphStyle
                ]
                
                let attrString = NSAttributedString(string: text, attributes: attributes)
                let textSize = attrString.size()
                let textRect = CGRect(
                    x: center.x - (textSize.width / 2.0),
                    y: center.y - (textSize.height / 2.0) + 0.5,
                    width: textSize.width,
                    height: textSize.height
                )
                attrString.draw(in: textRect)
            }
            
            return true
        }
        
        image.isTemplate = false // カラーを正確に表示
        return image
    }
    
    func updateContextMenu() {
        let l10n = settings?.l10n ?? L10n(language: .english)
        let menu = NSMenu()
        
        let showItem = NSMenuItem(title: l10n.menuBarShowTimer, action: #selector(showMainWindow), keyEquivalent: "t")
        showItem.target = self
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: l10n.menuBarToggle, action: #selector(toggleTimer), keyEquivalent: " ")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let resetItem = NSMenuItem(title: l10n.menuBarReset, action: #selector(resetTimer), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let statsItem = NSMenuItem(title: l10n.menuBarStats, action: #selector(openStats), keyEquivalent: "s")
        statsItem.target = self
        menu.addItem(statsItem)
        
        let settingsItem = NSMenuItem(title: l10n.menuBarSettings, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: l10n.menuBarQuit, action: #selector(quitApp), keyEquivalent: "q")
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
