import SwiftUI

struct MainTimerView: View {
    @StateObject private var engine = TimerEngine()
    @StateObject private var settings = TimerSettings()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // 背景ドラッグ移動（アプリ本体どこでも掴んで移動可能）
            WindowDraggableView()
            
            // メインコンテンツ
            Group {
                if settings.orientation == .horizontal {
                    if settings.size == .extraSmall {
                        miniHorizontalContent
                    } else {
                        horizontalContent
                    }
                } else {
                    verticalContent
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            ZStack {
                VisualEffectBackground()
                Color.black.opacity(0.75)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        .onAppear {
            setupInitialWindow()
            MenuBarManager.shared.setup(engine: engine, settings: settings)
        }
        .onChange(of: settings.size) { _ in
            updateWindowFrame()
        }
        .onChange(of: settings.orientation) { _ in
            updateWindowFrame()
        }
    }
    
    // MARK: - 極小モード (Mini) 横向きスリムバー
    private var miniHorizontalContent: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                DigitalDisplay(engine: engine, settings: settings)
                
                Spacer()
                
                // 再生 / 停止
                Button(action: {
                    engine.toggle()
                    MenuBarManager.shared.updateTitle()
                }) {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(engine.isRunning ? Color.orange.opacity(0.85) : Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                
                // リセット
                Button(action: {
                    engine.reset()
                    MenuBarManager.shared.updateTitle()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                        .padding(5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("r", modifiers: [])
                
                // 設定
                Button(action: {
                    SettingsWindowManager.shared.show(engine: engine, settings: settings)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .padding(5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // 下段: スリムLEDバー
            VisualBarView(engine: engine, settings: settings)
                .frame(height: 16)
        }
        .frame(width: 250, height: 68)
    }
    
    // MARK: - 通常横向きレイアウト (Small / Medium / Large)
    private var horizontalContent: some View {
        let dims = settings.size.windowDimensions(orientation: .horizontal)
        
        return VStack(alignment: .leading, spacing: 10) {
            // 上段: デジタル時計 + ドラッグインジケータ
            HStack(alignment: .center) {
                DigitalDisplay(engine: engine, settings: settings)
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            // 中段: 横向きLEDバー
            VisualBarView(engine: engine, settings: settings)
                .frame(height: settings.size == .small ? 24 : (settings.size == .medium ? 30 : 38))
            
            // 下段: コントロールパネル
            ControlPanelView(engine: engine, settings: settings, showSettings: $showSettings)
        }
        .frame(width: dims.width - 28, height: dims.height - 24)
    }
    
    // MARK: - 縦向きレイアウト
    private var verticalContent: some View {
        let dims = settings.size.windowDimensions(orientation: .vertical)
        
        return VStack(spacing: 8) {
            DigitalDisplay(engine: engine, settings: settings)
            
            // 中段: 縦向きLEDバー
            VisualBarView(engine: engine, settings: settings)
                .frame(maxHeight: .infinity)
            
            // 下段: 縦向き用コンパクトコントロール
            verticalControls
        }
        .frame(width: dims.width - 28, height: dims.height - 24)
    }
    
    // 縦向き専用のコンパクトコントロール
    private var verticalControls: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Button(action: {
                    engine.toggle()
                    MenuBarManager.shared.updateTitle()
                }) {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(engine.isRunning ? Color.orange.opacity(0.85) : Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                
                Button(action: {
                    engine.reset()
                    MenuBarManager.shared.updateTitle()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("r", modifiers: [])
            }
            
            HStack(spacing: 4) {
                Button(action: {
                    settings.isAlwaysOnTop.toggle()
                    if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" && $0.title != "タイマー稼働統計・ログエクスポート" }) {
                        window.level = settings.isAlwaysOnTop ? .floating : .normal
                    }
                }) {
                    Image(systemName: settings.isAlwaysOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 10))
                        .foregroundColor(settings.isAlwaysOnTop ? .yellow : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation {
                        settings.orientation = .horizontal
                    }
                }) {
                    Image(systemName: "rectangle.split.3x1")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    SettingsWindowManager.shared.show(engine: engine, settings: settings)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func setupInitialWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title != "タイマー設定" && $0.title != "タイマー稼働統計・ログエクスポート" }) else { return }
            
            window.level = settings.isAlwaysOnTop ? .floating : .normal
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            
            // 3つの信号機ボタンを完全非表示
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            let dims = settings.size.windowDimensions(orientation: settings.orientation)
            let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
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
            
            let newFrame = NSRect(x: targetX, y: targetY, width: dims.width, height: dims.height)
            window.setFrame(newFrame, display: true, animate: false)
            
            NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { notif in
                if let win = notif.object as? NSWindow, win.title != "タイマー設定" && win.title != "タイマー稼働統計・ログエクスポート" {
                    UserDefaults.standard.set(Double(win.frame.origin.x), forKey: "saved_window_x")
                    UserDefaults.standard.set(Double(win.frame.origin.y), forKey: "saved_window_y")
                }
            }
        }
    }
    
    private func updateWindowFrame() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title != "タイマー設定" && $0.title != "タイマー稼働統計・ログエクスポート" }) else { return }
            let dims = settings.size.windowDimensions(orientation: settings.orientation)
            var currentFrame = window.frame
            let oldTop = currentFrame.origin.y + currentFrame.size.height
            
            currentFrame.size = CGSize(width: dims.width, height: dims.height)
            currentFrame.origin.y = oldTop - dims.height
            
            if let screen = window.screen ?? NSScreen.main {
                let visible = screen.visibleFrame
                if currentFrame.maxX > visible.maxX + (dims.width - 40) {
                    currentFrame.origin.x = visible.maxX - currentFrame.size.width
                }
                if currentFrame.minX < visible.minX - (dims.width - 40) {
                    currentFrame.origin.x = visible.minX
                }
            }
            
            window.setFrame(currentFrame, display: true, animate: true)
            
            UserDefaults.standard.set(Double(currentFrame.origin.x), forKey: "saved_window_x")
            UserDefaults.standard.set(Double(currentFrame.origin.y), forKey: "saved_window_y")
        }
    }
}
