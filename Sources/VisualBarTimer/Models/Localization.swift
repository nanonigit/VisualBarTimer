import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case japanese = "ja"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
}

public struct L10n {
    public let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = language
    }

    private var isJa: Bool { language == .japanese }

    public var settingsSectionLabel: String { isJa ? "設定項目" : "Settings section" }
    public var settingsTabTimer: String { isJa ? "タイマー" : "Timer" }
    public var settingsTabApp: String { isJa ? "アプリ" : "App" }
    public var settingsTabCalendar: String { isJa ? "カレンダー" : "Calendar" }
    public var settingsTabCategories: String { isJa ? "カテゴリ" : "Categories" }

    // MARK: - General Actions & Labels
    public var close: String { isJa ? "閉じる" : "Close" }
    public var cancel: String { isJa ? "キャンセル" : "Cancel" }
    public var save: String { isJa ? "保存する" : "Save" }
    public var add: String { isJa ? "追加する" : "Add" }
    public var reset: String { isJa ? "リセット" : "Reset" }
    public var start: String { isJa ? "スタート" : "Start" }
    public var pause: String { isJa ? "一時停止" : "Pause" }
    public var delete: String { isJa ? "削除" : "Delete" }
    public var edit: String { isJa ? "編集" : "Edit" }
    public var today: String { isJa ? "今日" : "Today" }
    public var preset: String { isJa ? "プリセット" : "Preset" }
    public var minUnit: String { isJa ? "分" : "m" }
    public var secUnit: String { isJa ? "秒" : "s" }
    public var hourUnit: String { isJa ? "時間" : "h" }
    public var timesUnit: String { isJa ? "回" : "sessions" }
    public var quitApp: String { isJa ? "VisualBarTimer を終了" : "Quit VisualBarTimer" }
    public var settingsMenu: String { isJa ? "設定..." : "Settings..." }
    public var statsMenu: String { isJa ? "本日の稼働統計・ログ..." : "Today's Stats & Logs..." }

    // MARK: - Settings Window / Sheet
    public var settingsTitle: String { isJa ? "タイマー設定" : "Timer Settings" }
    public var languageSection: String { isJa ? "表示言語 (Language)" : "Language" }
    public var timerModeSection: String { isJa ? "タイマーモード" : "Timer Mode" }
    public var barOrientationSection: String { isJa ? "バーの向き" : "Bar Orientation" }
    public var colorThemeSection: String { isJa ? "カラーテーマ" : "Color Theme" }
    public var windowSizeSection: String { isJa ? "ウィンドウサイズ" : "Window Size" }

    public var windowAndMenuBarSection: String { isJa ? "ウィンドウ・Dock・メニューバー" : "Window, Dock & Menu Bar" }
    public var closeActionHeader: String { isJa ? "左上「✕」ボタンを押したときの動作" : "Action when clicking \"✕\" button" }
    public var showInMenuBar: String { isJa ? "メニューバーにアイコンを表示" : "Show icon in menu bar" }
    public var showInMenuBarDesc: String { isJa ? "クリックでウィンドウの再表示やスタート/停止が可能" : "Click to toggle window visibility or start/pause timer" }
    public var menuBarFormatHeader: String { isJa ? "メニューバーの分数表示スタイル" : "Menu bar display format" }
    public var showInDock: String { isJa ? "Dockにアプリアイコンを表示" : "Show app icon in Dock" }
    public var showInDockDesc: String { isJa ? "OFFにするとメニューバー常駐専用アプリになります" : "Runs as menu bar accessory app when turned off" }
    public var launchAtLogin: String { isJa ? "Macログイン時に自動起動" : "Launch automatically at Mac login" }
    public var launchAtLoginDesc: String { isJa ? "Macの起動・ログインと同時にタイマーを起動します" : "Automatically launches timer when Mac starts up" }
    public var startHidden: String { isJa ? "起動時にウィンドウを隠す（メニューバーのみで起動）" : "Start minimized to menu bar" }
    public var startHiddenDesc: String { isJa ? "起動時に画面を邪魔せず、メニューバー常駐として静かに起動します" : "Launches quietly in background without opening main window" }

    public var calendarSyncDaily: String { isJa ? "日が変わった時に前日の稼働時間をカレンダーに自動記録" : "Auto-record daily focus time to calendar at midnight" }
    public var calendarSyncDailyDesc: String { isJa ? "日付変更時または翌朝起動時に、前日の実績をカレンダーへ自動登録します" : "Automatically registers previous day's activity on calendar" }
    public var calendarSyncWeekly: String { isJa ? "週が変わった時に前週の集中サマリーを終日予定として自動記録" : "Auto-record weekly focus summary to calendar" }
    public var calendarSyncWeeklyDesc: String { isJa ? "週明けに前週の総集中時間・セッション数・内訳をカレンダーの終日欄に登録します" : "Logs total focus time, sessions, and breakdown as an all-day event" }
    public var weekStartDayHeader: String { isJa ? "週の始まり曜日" : "Week starts on" }
    public var targetCalendarHeader: String { isJa ? "書き込み先カレンダー" : "Target Calendar" }
    public var requestCalendarAccess: String { isJa ? "カレンダーへのアクセスを許可して一覧を読み込む" : "Allow calendar access to load list" }
    public var calendarSyncStyleHeader: String { isJa ? "カレンダー記録スタイル" : "Calendar record style" }
    public var windowPlacementHeader: String { isJa ? "ウィンドウ配置・固定レイヤー" : "Window Placement & Layer" }

    public var notificationsSection: String { isJa ? "通知 & アラーム" : "Notifications & Alarms" }
    public var playAlarmSound: String { isJa ? "アラームサウンドを鳴らす" : "Play alarm sound" }
    public var flashBarOnFinish: String { isJa ? "終了時にバーを点滅" : "Flash bar on finish" }

    public var categoryManagementHeader: String { isJa ? "作業カテゴリ管理 (カレンダー予定名)" : "Activity Categories (Calendar Event Title)" }
    public var categoryManagementDesc: String { isJa ? "スイッチOFFでタイマーメニューから隠せます" : "Toggle off to hide from timer menu" }
    public var editCategoryHelp: String { isJa ? "カテゴリ名・アイコンを編集" : "Edit category name and icon" }
    public var deleteCategoryHelp: String { isJa ? "このカスタムカテゴリを完全に削除" : "Delete this custom category permanently" }
    public func categoryVisibleHelp(_ visible: Bool) -> String {
        if isJa {
            return visible ? "タイマーメニューに表示中（クリックで非表示）" : "タイマーメニューから非表示中（クリックで表示）"
        } else {
            return visible ? "Shown in timer menu (click to hide)" : "Hidden from timer menu (click to show)"
        }
    }

    public var activityLogsHeader: String { isJa ? "タイマー稼働ログ・外部連携" : "Activity Logs & Integrations" }
    public var activityLogsButton: String { isJa ? "稼働統計・CSV/JSONエクスポート" : "Activity Stats & CSV/JSON Export" }

    // MARK: - Category Edit Sheet
    public var editCategoryTitle: String { isJa ? "カテゴリの編集" : "Edit Category" }
    public var addCategoryTitle: String { isJa ? "新規カテゴリの追加" : "Add New Category" }
    public var selectEmojiPrompt: String { isJa ? "アイコン絵文字を選択:" : "Select an icon emoji:" }
    public var categoryNamePrompt: String { isJa ? "カテゴリ名:" : "Category Name:" }
    public var categoryPlaceholder: String { isJa ? "例: 英語学習、確定申告、ブログ" : "e.g. Study, Taxes, Blog" }

    // MARK: - Control Panel
    public var quickMinPlaceholder: String { isJa ? "分" : "m" }
    public var quickMinHelp: String { isJa ? "入力した分数をセット" : "Set entered minutes" }
    public var windowPlacementMenu: String { isJa ? "ウィンドウ配置モード" : "Window Placement Mode" }
    public var toggleOrientationHelp: String { isJa ? "縦向き/横向き切り替え" : "Toggle Horizontal / Vertical" }
    public var menuAndSettingsHelp: String { isJa ? "メニュー & 設定" : "Menu & Settings" }

    // MARK: - Main Timer View
    public var quitHelp: String { isJa ? "アプリを終了" : "Quit App" }
    public var hideHelp: String { isJa ? "メニューバーに隠す" : "Hide to Menu Bar" }
    public func cycleSizeHelp(current: String) -> String {
        isJa ? "サイズを切り替え (現在: \(current))" : "Cycle size (Current: \(current))"
    }

    // MARK: - Digital Display
    public var switchCategoryHelp: String { isJa ? "作業カテゴリを切り替え (カレンダーの予定名に反映されます)" : "Switch activity category (reflects in calendar event title)" }
    public var openStatsHelp: String { isJa ? "クリックして本日の統計・履歴ログ・カレンダー同期を開く" : "Click to open today's stats, logs, and calendar sync" }
    public var editDurationHelp: String { isJa ? "クリックして分数を直接入力" : "Click to edit minutes directly" }
    public var confirmReturnHelp: String { isJa ? "確定 (Returnキー)" : "Confirm (Return key)" }
    public func editCategoryButton(name: String) -> String {
        isJa ? "「\(name)」を編集..." : "Edit \"\(name)\"..."
    }
    public var addNewCategoryButton: String { isJa ? "新しいカテゴリを追加..." : "Add New Category..." }

    // MARK: - Stats Window
    public var statsWindowTitle: String { isJa ? "タイマー稼働統計・ログエクスポート" : "Activity Logs & Statistics" }
    public var statsHeaderTitle: String { isJa ? "タイマー稼働ログ・統計" : "Activity Logs & Statistics" }
    public var statsHeaderSubtitle: String { isJa ? "日々の集中・タイマー稼働時間を記録・修正・カレンダー連携" : "Record, edit, and sync daily focus time with calendars" }
    public var todayTotalFocus: String { isJa ? "本日の総タイマー稼働" : "Today's Total Focus" }
    public var editTimeButton: String { isJa ? "時間を修正" : "Edit Time" }
    public var sessionCount: String { isJa ? "セッション回数" : "Sessions" }
    public func sessionCountDisplay(_ count: Int) -> String {
        isJa ? "\(count) 回" : "\(count) times"
    }

    public var calendarBannerTitle: String { isJa ? "Google / Macカレンダーに今日の総時間を記録" : "Record Today's Focus in Google / Mac Calendar" }
    public var calendarBannerSubtitle: String { isJa ? "Google同期されているカレンダーに予定として自動登録されます" : "Automatically created as an event in your synced calendar" }
    public var weeklySummaryRegisterButton: String { isJa ? "前週サマリー登録" : "Log Last Week's Summary" }
    public var weeklySummaryHelp: String { isJa ? "前週の集中時間を集計し、終日イベントとして登録します" : "Aggregates last week's focus time as an all-day event" }
    public var recordTodayButton: String { isJa ? "今日の分を記録" : "Log Today's Focus" }
    public var calendarTargetLabel: String { isJa ? "保存先:" : "Target:" }

    public var dailyHistoryHeader: String { isJa ? "日別履歴 (各日のカレンダー登録・修正・削除)" : "Daily History (Sync, Edit, Delete)" }
    public var clearAllHistoryButton: String { isJa ? "全履歴を消去" : "Clear All History" }
    public var clearAllHistoryHelp: String { isJa ? "すべてのタイマー稼働履歴を削除してリセットします" : "Deletes all focus history and resets records" }
    public var noLogsMessage: String { isJa ? "まだ記録されたログはありません。タイマーを動かすと自動集計されます。" : "No logs recorded yet. Daily activity will be tracked automatically as you use the timer." }

    public var syncDayToCalendarHelp: String { isJa ? "この日の稼働時間をカレンダーに登録" : "Sync this day's focus time to calendar" }
    public var editDayLogHelp: String { isJa ? "この日の稼働時間を修正" : "Edit this day's focus time" }
    public func deleteDayLogHelp(date: String) -> String {
        isJa ? "この日（\(date)）のログを削除" : "Delete logs for this day (\(date))"
    }

    public var fileExportHeader: String { isJa ? "ファイル書き出し & 外部連携" : "File Export & Data" }
    public var exportCSVButton: String { isJa ? "CSV書き出し" : "Export CSV" }
    public var exportJSONButton: String { isJa ? "JSON書き出し" : "Export JSON" }
    public var copyCSVButton: String { isJa ? "CSVコピー" : "Copy CSV" }
    public var openFolderButton: String { isJa ? "保存フォルダを開く" : "Open Log Folder" }
    public var csvCopiedToast: String { isJa ? "CSVをコピーしました" : "CSV copied to clipboard" }

    public var deleteDayAlertTitle: String { isJa ? "この日の履歴を削除しますか？" : "Delete history for this day?" }
    public func deleteDayAlertMessage(date: String) -> String {
        isJa ? "\(date) の集中タイマー稼働ログとセッション履歴を完全に削除します。" : "Permanently deletes timer logs and session records for \(date)."
    }
    public var clearAllAlertTitle: String { isJa ? "全履歴を消去しますか？" : "Clear all history?" }
    public var clearAllAlertMessage: String { isJa ? "これまでに記録されたすべてのタイマー稼働ログが完全に削除され、今日の稼働時間も0分にリセットされます。この操作は取り消せません。" : "All recorded timer logs will be permanently deleted, and today's total will reset to 0. This action cannot be undone." }
    public var clearAllConfirmButton: String { isJa ? "すべて消去" : "Clear All" }

    // MARK: - Edit Duration Sheet
    public func editDurationTitle(date: String) -> String {
        isJa ? "稼働時間の修正: \(date)" : "Edit Focus Duration: \(date)"
    }
    public var editDurationSubtitle: String { isJa ? "止め忘れや手動調整したい分数を直接入力してください：" : "Enter the adjusted duration in minutes:" }
    public var editDurationUnit: String { isJa ? "分 に修正する" : "minutes" }
    public var fineTuneLabel: String { isJa ? "微調整:" : "Adjust:" }

    // MARK: - Menu Bar Context Menu
    public var menuBarShowTimer: String { isJa ? "タイマーを表示 / 最前面" : "Show Timer / Bring to Front" }
    public var menuBarToggle: String { isJa ? "スタート / 一時停止" : "Start / Pause" }
    public var menuBarReset: String { isJa ? "リセット" : "Reset" }
    public var menuBarStats: String { isJa ? "本日の稼働統計・ログ..." : "Today's Stats & Logs..." }
    public var menuBarSettings: String { isJa ? "設定..." : "Settings..." }
    public var menuBarQuit: String { isJa ? "VisualBarTimer を終了" : "Quit VisualBarTimer" }

    // MARK: - Notifications
    public var notifTimerFinishedTitle: String { isJa ? "タイマー終了" : "Timer Finished" }
    public func notifTimerFinishedBody(time: String) -> String {
        isJa ? "\(time)が経過しました。" : "\(time) has elapsed."
    }
    public var notifBreakFinishedTitle: String { isJa ? "休憩時間終了！" : "Break Time Finished!" }
    public var notifBreakFinishedBody: String { isJa ? "次の作業セッションを始めましょう。" : "Let's start the next focus session." }
    public var notifFocusFinishedTitle: String { isJa ? "集中タイム終了！" : "Focus Time Finished!" }
    public var notifFocusFinishedBody: String { isJa ? "5分間の休憩を取りましょう。" : "Take a 5-minute break." }
}
