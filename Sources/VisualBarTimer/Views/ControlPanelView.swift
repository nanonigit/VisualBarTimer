import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    @Binding var showSettings: Bool
    @State private var customMinText: String = ""
    
    private let presets: [(label: String, seconds: TimeInterval)] = [
        ("3m", 180),
        ("5m", 300),
        ("10m", 600),
        ("15m", 900),
        ("25m", 1500),
        ("30m", 1800),
        ("60m", 3600)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // プリセットボタン ＋ 直接分数入力
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(presets, id: \.label) { preset in
                            Button(action: {
                                engine.setDuration(preset.seconds)
                            }) {
                                Text(preset.label)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(engine.targetDuration == preset.seconds ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // 直接分数入力 (クイックセット)
                HStack(spacing: 2) {
                    TextField("分", text: $customMinText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .onSubmit {
                            submitCustomTime()
                        }
                    
                    Text("m")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        submitCustomTime()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(4)
                            .background(Color.cyan)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("入力した分数をセット")
                }
                .padding(.leading, 4)
            }
            
            // 操作ボタン & クイック設定
            HStack(spacing: 8) {
                // 再生 / 一時停止
                Button(action: {
                    engine.toggle()
                }) {
                    Label(engine.isRunning ? "一時停止" : "スタート", systemImage: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(engine.isRunning ? Color.orange.opacity(0.85) : Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                
                // リセット
                Button(action: {
                    engine.reset()
                }) {
                    Label("リセット", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("r", modifiers: [])
                
                Spacer()
                
                // 最前面ピン留めトグル
                Button(action: {
                    settings.isAlwaysOnTop.toggle()
                    if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" }) {
                        window.level = settings.isAlwaysOnTop ? .floating : .normal
                    }
                }) {
                    Image(systemName: settings.isAlwaysOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 11))
                        .foregroundColor(settings.isAlwaysOnTop ? .yellow : .secondary)
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(settings.isAlwaysOnTop ? "常に最前面: ON" : "常に最前面: OFF")
                
                // 向き切り替え
                Button(action: {
                    withAnimation {
                        settings.orientation = (settings.orientation == .horizontal) ? .vertical : .horizontal
                    }
                }) {
                    Image(systemName: settings.orientation.icon)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("縦向き/横向き切り替え")
                
                // 詳細設定
                Button(action: {
                    SettingsWindowManager.shared.show(engine: engine, settings: settings)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("設定")
            }
        }
    }
    
    private func submitCustomTime() {
        if let mins = Double(customMinText), mins > 0 {
            engine.setDuration(mins * 60)
            customMinText = ""
        }
    }
}
