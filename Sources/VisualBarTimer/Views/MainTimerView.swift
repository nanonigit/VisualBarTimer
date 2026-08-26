import SwiftUI

struct MainTimerView: View {
    @StateObject private var engine = TimerEngine()
    @StateObject private var settings = TimerSettings()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // 背景ドラッグ移動
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
            setupWindow()
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
            // 上段: 時計 + 操作アイコン
            HStack(spacing: 8) {
                DigitalDisplay(engine: engine, settings: settings)
                
                Spacer()
                
                // 再生 / 停止
                Button(action: {
                    engine.toggle()
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
            // 上段: デジタル時計
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
                // 再生 / 停止
                Button(action: {
                    engine.toggle()
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
                
                // リセット
                Button(action: {
                    engine.reset()
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
                // 最前面ピン
                Button(action: {
                    settings.isAlwaysOnTop.toggle()
                    if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" }) {
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
                
                // 向き切り替え
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
                
                // 設定
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
    
    private func setupWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" }) {
                window.level = settings.isAlwaysOnTop ? .floating : .normal
                window.isOpaque = false
                window.backgroundColor = .clear
                window.isMovableByWindowBackground = true
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                updateWindowFrame()
            }
        }
    }
    
    private func updateWindowFrame() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title != "タイマー設定" }) else { return }
            let dims = settings.size.windowDimensions(orientation: settings.orientation)
            var currentFrame = window.frame
            let oldTop = currentFrame.origin.y + currentFrame.size.height
            currentFrame.size = CGSize(width: dims.width, height: dims.height)
            currentFrame.origin.y = oldTop - dims.height
            window.setFrame(currentFrame, display: true, animate: true)
        }
    }
}
