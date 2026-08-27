import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
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
                
                // ウィンドウ & メニューバー・Dock設定
                VStack(alignment: .leading, spacing: 10) {
                    Text("ウィンドウ・Dock・メニューバー")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    // ✕ボタンの動作
                    VStack(alignment: .leading, spacing: 4) {
                        Text("左上「✕」ボタンを押したときの動作")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Picker("", selection: $settings.closeAction) {
                            ForEach(CloseAction.allCases) { action in
                                Text(action.rawValue).tag(action)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.radioGroup)
                    }
                    .padding(.bottom, 4)
                    
                    Toggle(isOn: $settings.showInMenuBar) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("メニューバーにアイコンを表示")
                                .font(.system(size: 13))
                            Text("クリックでウィンドウの再表示やスタート/停止が可能")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if settings.showInMenuBar {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("メニューバーの分数表示スタイル")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Picker("", selection: $settings.menuBarFormat) {
                                ForEach(MenuBarDisplayFormat.allCases) { fmt in
                                    Text(fmt.rawValue).tag(fmt)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.radioGroup)
                        }
                        .padding(.leading, 12)
                        .padding(.vertical, 2)
                    }
                    
                    Toggle(isOn: $settings.showInDock) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Dockにアプリアイコンを表示")
                                .font(.system(size: 13))
                            Text("OFFにするとメニューバー常駐専用アプリになります")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // ログイン時自動起動
                    Toggle(isOn: Binding<Bool>(
                        get: { LaunchAtLoginManager.shared.isEnabled },
                        set: { LaunchAtLoginManager.shared.setEnabled($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Macログイン時に自動起動")
                                .font(.system(size: 13))
                            Text("Macの起動・ログインと同時にタイマーを起動します")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.isAlwaysOnTop) {
                        Text("常に最前面に表示")
                            .font(.system(size: 13))
                    }
                    .onChange(of: settings.isAlwaysOnTop) { isOn in
                        if let window = NSApp.windows.first(where: { $0.title != "タイマー設定" && $0.title != "タイマー稼働統計・ログエクスポート" }) {
                            window.level = isOn ? .floating : .normal
                        }
                    }
                }
                .toggleStyle(.switch)
                
                Divider()
                
                // サウンド・通知
                VStack(alignment: .leading, spacing: 8) {
                    Text("通知 & アラーム")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
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
                
                Divider()
                
                // 稼働ログ・統計
                VStack(alignment: .leading, spacing: 6) {
                    Text("タイマー稼働ログ・外部連携")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        StatsWindowManager.shared.show()
                    }) {
                        HStack {
                            Label("稼働統計・CSV/JSONエクスポート", systemImage: "chart.bar.doc.horizontal")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(width: 460, height: 560)
    }
}
