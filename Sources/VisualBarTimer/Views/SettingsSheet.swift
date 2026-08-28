import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    @ObservedObject var calendarSync = CalendarSyncManager.shared
    @ObservedObject var categoryManager = CategoryManager.shared
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
                    
                    // 起動時にウィンドウを隠す
                    Toggle(isOn: $settings.startHidden) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("起動時にウィンドウを隠す（メニューバーのみで起動）")
                                .font(.system(size: 13))
                            Text("起動時に画面を邪魔せず、メニューバー常駐として静かに起動します")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // カレンダー自動同期
                    Toggle(isOn: Binding<Bool>(
                        get: { calendarSync.autoSyncEnabled },
                        set: { calendarSync.autoSyncEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("日が変わった時に前日の稼働時間をカレンダーに自動記録")
                                .font(.system(size: 13))
                            Text("日付変更時または翌朝起動時に、前日の総集中時間をGoogle/Macカレンダーへ自動登録します")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 書き込み先カレンダーの選択 & 権限リクエスト
                    VStack(alignment: .leading, spacing: 6) {
                        Text("書き込み先カレンダー")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        if calendarSync.isAuthorized && !calendarSync.availableCalendars.isEmpty {
                            Picker("", selection: $calendarSync.selectedCalendarId) {
                                ForEach(calendarSync.availableCalendars, id: \.id) { option in
                                    Text(option.displayName).tag(option.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            
                            // 登録スタイル
                            VStack(alignment: .leading, spacing: 3) {
                                Text("カレンダー記録スタイル")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $calendarSync.syncStyle) {
                                    ForEach(CalendarSyncStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.radioGroup)
                            }
                            .padding(.top, 4)
                        } else {
                            Button(action: {
                                calendarSync.requestAccess()
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("カレンダーへのアクセスを許可して一覧を読み込む")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.vertical, 4)
                    
                    // ウィンドウ配置モード
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ウィンドウ配置・固定レイヤー")
                            .font(.system(size: 13, weight: .medium))
                        
                        Picker("", selection: $settings.windowPlacement) {
                            ForEach(WindowPlacement.allCases) { placement in
                                Label(placement.rawValue, systemImage: placement.icon).tag(placement)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.radioGroup)
                    }
                    .padding(.vertical, 2)
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
                
                // 作業カテゴリ管理
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("作業カテゴリ管理 (カレンダー予定名)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("スイッチOFFでタイマーメニューから隠せます")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    // カテゴリ一覧
                    VStack(spacing: 4) {
                        ForEach(categoryManager.allCategories) { cat in
                            let isVisible = !categoryManager.isHidden(cat)
                            HStack {
                                Text(cat.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(isVisible ? .white : .secondary.opacity(0.6))
                                
                                if cat.isPreset {
                                    Text("プリセット")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(Capsule())
                                }
                                
                                Spacer()
                                
                                // 表示 / 非表示 トグルスイッチ
                                Toggle("", isOn: Binding<Bool>(
                                    get: { !categoryManager.isHidden(cat) },
                                    set: { _ in categoryManager.toggleVisibility(for: cat) }
                                ))
                                .toggleStyle(.switch)
                                .controlSize(.mini)
                                .help(isVisible ? "タイマーメニューに表示中（クリックで非表示）" : "タイマーメニューから非表示中（クリックで表示）")
                                
                                // カスタムカテゴリのみ削除ボタン
                                if !cat.isPreset {
                                    Button(action: {
                                        categoryManager.deleteCustomCategory(id: cat.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 10))
                                            .foregroundColor(.red.opacity(0.8))
                                            .padding(4)
                                            .background(Color.red.opacity(0.12))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .help("このカスタムカテゴリを完全に削除")
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(isVisible ? 0.05 : 0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
                
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
        .scrollIndicators(.visible)
        .frame(width: 480, height: 600)
        .onAppear {
            calendarSync.checkAuthorization()
        }
    }
}
