import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    @ObservedObject var calendarSync = CalendarSyncManager.shared
    @ObservedObject var categoryManager = CategoryManager.shared
    var onClose: (() -> Void)? = nil
    
    @State private var categoryEditor: CategoryEditorRequest? = nil
    
    @State private var selectedSection: SettingsSection = .timer

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(settings.l10n.settingsTitle)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(settings.l10n.close) { onClose?() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Picker(settings.l10n.settingsSectionLabel, selection: $selectedSection) {
                ForEach(SettingsSection.allCases) { section in
                    Text(section.title(for: settings.language)).tag(section)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                Group {
                    switch selectedSection {
                    case .timer: timerSection
                    case .app: appSection
                    case .calendar: calendarSection
                    case .categories: categoriesSection
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(AlwaysShowVerticalScrollBar())
            }
            .id(selectedSection)
            .scrollIndicators(.visible)
        }
        .frame(width: 480, height: 620)
        .onAppear { calendarSync.checkAuthorization() }
        .sheet(item: $categoryEditor) { request in
            CategoryEditSheet(categoryToEdit: request.category, language: settings.language) {
                categoryEditor = nil
            }
        }
    }

    private var timerSection: some View {
        let l10n = settings.l10n
        let lang = settings.language
        return VStack(alignment: .leading, spacing: 18) {
            // 言語設定 (Language)
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.languageSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { langItem in
                        Text(langItem.displayName).tag(langItem)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Divider()

            // タイマーモード
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.timerModeSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $settings.mode) {
                    ForEach(TimerMode.allCases) { mode in
                        Text(mode.title(for: lang)).tag(mode)
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
                Text(l10n.barOrientationSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $settings.orientation) {
                    ForEach(TimerOrientation.allCases) { orient in
                        Text(orient.title(for: lang)).tag(orient)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            // カラーテーマ
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.colorThemeSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $settings.theme) {
                    ForEach(TimerTheme.allCases) { theme in
                        Text(theme.title(for: lang)).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            // ウィンドウサイズ
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.windowSizeSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $settings.size) {
                    ForEach(TimerSize.allCases) { size in
                        Text(size.title(for: lang)).tag(size)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Divider()

            // サウンド・通知
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n.notificationsSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Toggle(isOn: $settings.isSoundEnabled) {
                    Text(l10n.playAlarmSound)
                        .font(.system(size: 13))
                }

                Toggle(isOn: $settings.isFlashEnabled) {
                    Text(l10n.flashBarOnFinish)
                        .font(.system(size: 13))
                }
            }
            .toggleStyle(.switch)

            Divider()
        }
        .toggleStyle(.switch)
    }

    private var appSection: some View {
        let l10n = settings.l10n
        let lang = settings.language
        return VStack(alignment: .leading, spacing: 18) {
            // ウィンドウ & メニューバー・Dock設定
            VStack(alignment: .leading, spacing: 10) {
                Text(l10n.windowAndMenuBarSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                // ✕ボタンの動作
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.closeActionHeader)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.closeAction) {
                        ForEach(CloseAction.allCases) { action in
                            Text(action.title(for: lang)).tag(action)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }
                .padding(.bottom, 4)

                Toggle(isOn: $settings.showInMenuBar) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(l10n.showInMenuBar)
                            .font(.system(size: 13))
                        Text(l10n.showInMenuBarDesc)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                if settings.showInMenuBar {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.menuBarFormatHeader)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Picker("", selection: $settings.menuBarFormat) {
                            ForEach(MenuBarDisplayFormat.allCases) { fmt in
                                Text(fmt.title(for: lang)).tag(fmt)
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
                        Text(l10n.showInDock)
                            .font(.system(size: 13))
                        Text(l10n.showInDockDesc)
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
                        Text(l10n.launchAtLogin)
                            .font(.system(size: 13))
                        Text(l10n.launchAtLoginDesc)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                // 起動時にウィンドウを隠す
                Toggle(isOn: $settings.startHidden) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(l10n.startHidden)
                            .font(.system(size: 13))
                        Text(l10n.startHiddenDesc)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                // ウィンドウ配置モード
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.windowPlacementHeader)
                        .font(.system(size: 13, weight: .medium))

                    Picker("", selection: $settings.windowPlacement) {
                        ForEach(WindowPlacement.allCases) { placement in
                            Label(placement.title(for: lang), systemImage: placement.icon).tag(placement)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }
                .padding(.vertical, 2)
            }
            .toggleStyle(.switch)

            Divider()
        }
        .toggleStyle(.switch)
    }

    private var calendarSection: some View {
        let l10n = settings.l10n
        let lang = settings.language
        return VStack(alignment: .leading, spacing: 18) {
            // カレンダー自動同期 (日別)
            Toggle(isOn: Binding<Bool>(
                get: { calendarSync.autoSyncEnabled },
                set: { calendarSync.autoSyncEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(l10n.calendarSyncDaily)
                        .font(.system(size: 13))
                    Text(l10n.calendarSyncDailyDesc)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            // カレンダー自動同期 (週間サマリー)
            Toggle(isOn: Binding<Bool>(
                get: { calendarSync.autoWeeklySummaryEnabled },
                set: { calendarSync.autoWeeklySummaryEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(l10n.calendarSyncWeekly)
                        .font(.system(size: 13))
                    Text(l10n.calendarSyncWeeklyDesc)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            if calendarSync.autoWeeklySummaryEnabled {
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.weekStartDayHeader)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Picker("", selection: Binding<WeekStartDay>(
                        get: { calendarSync.weekStartDay },
                        set: { calendarSync.weekStartDay = $0 }
                    )) {
                        ForEach(WeekStartDay.allCases) { opt in
                            Text(opt.title(for: lang)).tag(opt)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }
                .padding(.leading, 12)
                .padding(.vertical, 2)
            }

            // 書き込み先カレンダーの選択 & 権限リクエスト
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.targetCalendarHeader)
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
                        Text(l10n.calendarSyncStyleHeader)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Picker("", selection: $calendarSync.syncStyle) {
                            ForEach(CalendarSyncStyle.allCases) { style in
                                Text(style.title(for: lang)).tag(style)
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
                            Text(l10n.requestCalendarAccess)
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
        }
        .toggleStyle(.switch)
    }

    private var categoriesSection: some View {
        let l10n = settings.l10n
        let lang = settings.language
        return VStack(alignment: .leading, spacing: 18) {
            // 作業カテゴリ管理
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(l10n.categoryManagementHeader)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(l10n.categoryManagementDesc)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                // カテゴリ一覧
                Button {
                    categoryEditor = CategoryEditorRequest(category: nil)
                } label: {
                    Label(l10n.addNewCategoryButton, systemImage: "plus")
                }
                .controlSize(.regular)

                VStack(spacing: 4) {
                    ForEach(categoryManager.allCategories) { cat in
                        let isVisible = !categoryManager.isHidden(cat)
                        HStack {
                            Text(cat.localizedTitle(for: lang))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isVisible ? .white : .secondary.opacity(0.6))

                            if cat.isPreset {
                                Text(l10n.preset)
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
                            .help(l10n.categoryVisibleHelp(isVisible))

                            // カスタムカテゴリの編集・削除ボタン
                            if !cat.isPreset {
                                Button(action: {
                                categoryEditor = CategoryEditorRequest(category: cat)
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue.opacity(0.85))
                                        .padding(4)
                                        .background(Color.blue.opacity(0.12))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .help(l10n.editCategoryHelp)

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
                                .help(l10n.deleteCategoryHelp)
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
                Text(l10n.activityLogsHeader)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Button(action: {
                    StatsWindowManager.shared.show()
                }) {
                    HStack {
                        Label(l10n.activityLogsButton, systemImage: "chart.bar.doc.horizontal")
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
        .toggleStyle(.switch)
    }

}

enum SettingsSection: String, CaseIterable, Identifiable {
    case timer, app, calendar, categories
    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        let l10n = L10n(language: language)
        switch self {
        case .timer: return l10n.settingsTabTimer
        case .app: return l10n.settingsTabApp
        case .calendar: return l10n.settingsTabCalendar
        case .categories: return l10n.settingsTabCategories
        }
    }
}

struct AlwaysShowVerticalScrollBar: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = false
                scrollView.scrollerStyle = .legacy
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = nsView.enclosingScrollView {
                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = false
                scrollView.scrollerStyle = .legacy
            }
        }
    }
}
