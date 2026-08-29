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
    
    /// リアルタイム円グラフ（デスクトップLEDバーと同じ赤・黄・緑の3色ゾーン ＆ 時計回り減衰）
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
            
            // 2. LEDバーと同一のマルチカラー円弧描画 (緑 -> 黄 -> 赤 の順に時計回りで消灯)
            let clampedProgress = max(0, min(1.0, progress))
            
            // 角度変換ヘルパー: 比率 r (0.0=終了12時 ... 1.0=開始12時)
            func angle(forRatio r: CGFloat) -> CGFloat {
                return (CGFloat.pi / 2.0) - (CGFloat.pi * 2.0 * (1.0 - r))
            }
            
            func drawSegment(from rStart: CGFloat, to rEnd: CGFloat, color: NSColor) {
                guard rEnd > rStart else { return }
                let aStart = angle(forRatio: rStart)
                let aEnd = angle(forRatio: rEnd)
                
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.butt)
                ctx.addArc(center: center, radius: radius, startAngle: aStart, endAngle: aEnd, clockwise: false)
                ctx.strokePath()
                
                // 内側の薄い発光
                let fillPath = CGMutablePath()
                fillPath.move(to: center)
                fillPath.addArc(center: center, radius: radius - lineWidth / 2.0, startAngle: aStart, endAngle: aEnd, clockwise: false)
                fillPath.closeSubpath()
                ctx.setFillColor(color.withAlphaComponent(centerText != nil ? 0.12 : 0.22).cgColor)
                ctx.addPath(fillPath)
                ctx.fillPath()
            }
            
            if clampedProgress > 0.005 {
                let redColor = (theme == .monochrome) ? NSColor.white : NSColor(red: 0.98, green: 0.22, blue: 0.22, alpha: 1.0)
                let yellowColor = (theme == .monochrome) ? NSColor.white : NSColor(red: 0.98, green: 0.76, blue: 0.12, alpha: 1.0)
                let greenColor = (theme == .monochrome) ? NSColor.white : NSColor(red: 0.18, green: 0.88, blue: 0.48, alpha: 1.0)
                
                // ① 赤ゾーン (0% 〜 20%): 最後に消えるゾーン (9時36分 〜 12時)
                let redEnd = min(clampedProgress, 0.20)
                drawSegment(from: 0.0, to: redEnd, color: redColor)
                
                // ② 黄ゾーン (20% 〜 50%): 中盤に消えるゾーン (6時 〜 9時36分)
                if clampedProgress > 0.20 {
                    let yellowEnd = min(clampedProgress, 0.50)
                    drawSegment(from: 0.20, to: yellowEnd, color: yellowColor)
                }
                
                // ③ 緑ゾーン (50% 〜 100%): 最初に消えるゾーン (12時 〜 6時)
                if clampedProgress > 0.50 {
                    let greenEnd = min(clampedProgress, 1.0)
                    drawSegment(from: 0.50, to: greenEnd, color: greenColor)
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
