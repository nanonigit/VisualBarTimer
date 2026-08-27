import SwiftUI

struct MainTimerView: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    @State private var showSettings = false
    
    var body: some View {
        let dims = settings.size.windowDimensions(orientation: settings.orientation)
        
        ZStack(alignment: .topLeading) {
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
            
            // 左上: ✕ボタン ＋ サイズ切替トグルボタン
            HStack(spacing: 5) {
                // 赤い✕ボタン
                Button(action: {
                    handleCloseButton()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: 11, height: 11)
                        Image(systemName: "xmark")
                            .font(.system(size: 6, weight: .heavy))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                .help(settings.closeAction == .quit ? "アプリを終了" : "メニューバーに隠す")
                
                // サイズ切り替えトグルボタン (緑 / ⤢)
                Button(action: {
                    cycleNextSize()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.85))
                            .frame(width: 11, height: 11)
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                .help("サイズを切り替え (現在: \(settings.size.rawValue))")
            }
            .padding(.top, 8)
            .padding(.leading, 8)
        }
        .frame(width: dims.width, height: dims.height)
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
        .onChange(of: settings.size) { _ in
            MainWindowController.shared.updateFrame()
        }
        .onChange(of: settings.orientation) { _ in
            MainWindowController.shared.updateFrame()
        }
    }
    
    private func cycleNextSize() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch settings.size {
            case .extraSmall:
                settings.size = .small
            case .small:
                settings.size = .medium
            case .medium:
                settings.size = .large
            case .large:
                settings.size = .extraSmall
            }
        }
    }
    
    private func handleCloseButton() {
        if settings.closeAction == .quit {
            NSApp.terminate(nil)
        } else {
            if !settings.showInMenuBar {
                settings.showInMenuBar = true
            }
            MenuBarManager.shared.updateTitle()
            MainWindowController.shared.hide()
        }
    }
    
    // MARK: - 極小モード (Mini) 横向きスリムバー
    private var miniHorizontalContent: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // 左上ボタン用の余白
                Spacer().frame(width: 24)
                
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
                
                // 歯車メニュー
                Menu {
                    Button(action: {
                        SettingsWindowManager.shared.show(engine: engine, settings: settings)
                    }) {
                        Label("設定...", systemImage: "gearshape")
                    }
                    Button(action: {
                        StatsWindowManager.shared.show()
                    }) {
                        Label("稼働統計・ログ...", systemImage: "chart.bar.doc.horizontal")
                    }
                    Divider()
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Label("VisualBarTimer を終了", systemImage: "power")
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .padding(5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
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
                // 左上ボタン用の余白
                Spacer().frame(width: 26)
                
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
            HStack {
                // 左上ボタン用の余白
                Spacer().frame(width: 24)
                Spacer()
            }
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
                    MainWindowController.shared.window?.level = settings.isAlwaysOnTop ? .floating : .normal
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
                
                Menu {
                    Button(action: {
                        SettingsWindowManager.shared.show(engine: engine, settings: settings)
                    }) {
                        Label("設定...", systemImage: "gearshape")
                    }
                    Button(action: {
                        StatsWindowManager.shared.show()
                    }) {
                        Label("稼働統計・ログ...", systemImage: "chart.bar.doc.horizontal")
                    }
                    Divider()
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Label("VisualBarTimer を終了", systemImage: "power")
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .menuStyle(.borderlessButton)
            }
        }
    }
}
