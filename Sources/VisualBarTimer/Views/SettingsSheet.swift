import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // タイトル
                HStack {
                    Text("タイマー設定")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Button("閉じる") {
                        onClose?()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                
                Divider()
                
                // タイマーモード
                VStack(alignment: .leading, spacing: 6) {
                    Text("タイマーモード")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.mode) {
                        ForEach(TimerMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .onChange(of: settings.mode) { newMode in
                        engine.currentMode = newMode
                    }
                }
                
                // バーの向き
                VStack(alignment: .leading, spacing: 6) {
                    Text("バーの向き")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.orientation) {
                        ForEach(TimerOrientation.allCases) { orient in
                            Text(orient.rawValue).tag(orient)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                
                // カラーテーマ
                VStack(alignment: .leading, spacing: 6) {
                    Text("カラーテーマ")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.theme) {
                        ForEach(TimerTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                
                // ウィンドウサイズ
                VStack(alignment: .leading, spacing: 6) {
                    Text("ウィンドウサイズ")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.size) {
                        ForEach(TimerSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // トグル設定群
                VStack(spacing: 12) {
                    Toggle(isOn: $settings.isAlwaysOnTop) {
                        Text("常に最前面に表示")
                            .font(.system(size: 13))
                    }
                    .onChange(of: settings.isAlwaysOnTop) { isOn in
                        if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" }) {
                            window.level = isOn ? .floating : .normal
                        }
                    }
                    
                    Toggle(isOn: $settings.isSoundEnabled) {
                        Text("アラームサウンドを鳴らす")
                            .font(.system(size: 13))
                    }
                    
                    Toggle(isOn: $settings.isFlashEnabled) {
                        Text("終了時にバーを点滅")
                            .font(.system(size: 13))
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(24)
        }
        .frame(width: 440, height: 490)
    }
}
