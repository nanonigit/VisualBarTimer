import SwiftUI
import Combine
import AppKit

enum WindowPlacement: String, CaseIterable, Identifiable, Codable {
    case floating = "常に最前面 (Float on Top)"
    case normal = "標準ウィンドウ (Normal)"
    case desktopWidget = "デスクトップに貼り付け (壁紙最背面ウィジェット)"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .floating: return "pin.fill"
        case .normal: return "macwindow"
        case .desktopWidget: return "desktopcomputer"
        }
    }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.floating, .japanese): return "常に最前面 (Float on Top)"
        case (.floating, .english): return "Always on Top (Floating)"
        case (.normal, .japanese): return "標準ウィンドウ (Normal)"
        case (.normal, .english): return "Normal Window"
        case (.desktopWidget, .japanese): return "デスクトップに貼り付け (壁紙最背面ウィジェット)"
        case (.desktopWidget, .english): return "Desktop Widget (Behind windows)"
        }
    }
}

enum MenuBarDisplayFormat: String, CaseIterable, Identifiable, Codable {
    case pieChartWithCenterTotal = "円グラフ（中央に本日累計分を表示）"
    case pieChartOnly = "リアルタイム円グラフ (アイコンのみ)"
    case pieChartWithRemaining = "リアルタイム円グラフ ＋ 残り時間 (⏱️ 08:30)"
    case english = "m 表示 (⏱️ 45m)"
    case japanese = "分 表示 (⏱️ 45分)"
    case numberOnly = "数字のみ (45)"
    case iconOnly = "固定アイコンのみ (⏱️)"
    
    var id: String { rawValue }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.pieChartWithCenterTotal, .japanese): return "円グラフ（中央に本日累計分を表示）"
        case (.pieChartWithCenterTotal, .english): return "Pie chart (Total focus in center)"
        case (.pieChartOnly, .japanese): return "リアルタイム円グラフ (アイコンのみ)"
        case (.pieChartOnly, .english): return "Live pie chart (Icon only)"
        case (.pieChartWithRemaining, .japanese): return "リアルタイム円グラフ ＋ 残り時間 (⏱️ 08:30)"
        case (.pieChartWithRemaining, .english): return "Live pie chart + Remaining (⏱️ 08:30)"
        case (.english, .japanese): return "m 表示 (⏱️ 45m)"
        case (.english, .english): return "Minutes display (⏱️ 45m)"
        case (.japanese, .japanese): return "分 表示 (⏱️ 45分)"
        case (.japanese, .english): return "Japanese min display (⏱️ 45分)"
        case (.numberOnly, .japanese): return "数字のみ (45)"
        case (.numberOnly, .english): return "Number only (45)"
        case (.iconOnly, .japanese): return "固定アイコンのみ (⏱️)"
        case (.iconOnly, .english): return "Static icon only (⏱️)"
        }
    }
}

enum CloseAction: String, CaseIterable, Identifiable, Codable {
    case hideToMenuBar = "メニューバーに隠す (バックグラウンド常駐)"
    case quit = "アプリを完全に終了"
    
    var id: String { rawValue }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.hideToMenuBar, .japanese): return "メニューバーに隠す (バックグラウンド常駐)"
        case (.hideToMenuBar, .english): return "Hide to Menu Bar (Run in background)"
        case (.quit, .japanese): return "アプリを完全に終了"
        case (.quit, .english): return "Quit application completely"
        }
    }
}

enum TimerOrientation: String, CaseIterable, Identifiable, Codable {
    case horizontal = "横向き (Horizontal)"
    case vertical = "縦向き (Vertical)"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .horizontal: return "rectangle.split.3x1"
        case .vertical: return "rectangle.split.1x3"
        }
    }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.horizontal, .japanese): return "横向き (Horizontal)"
        case (.horizontal, .english): return "Horizontal"
        case (.vertical, .japanese): return "縦向き (Vertical)"
        case (.vertical, .english): return "Vertical"
        }
    }
}

enum TimerTheme: String, CaseIterable, Identifiable, Codable {
    case color = "カラー (Green/Yellow/Red)"
    case monochrome = "白黒 (Monochrome)"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .color: return "paintpalette.fill"
        case .monochrome: return "circle.lefthalf.filled"
        }
    }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.color, .japanese): return "カラー (Green/Yellow/Red)"
        case (.color, .english): return "Color (Green/Yellow/Red)"
        case (.monochrome, .japanese): return "白黒 (Monochrome)"
        case (.monochrome, .english): return "Monochrome"
        }
    }
}

enum TimerSize: String, CaseIterable, Identifiable, Codable {
    case extraSmall = "極小 (Mini)"
    case small = "小 (Small)"
    case medium = "中 (Medium)"
    case large = "大 (Large)"
    
    var id: String { rawValue }
    
    var scale: CGFloat {
        switch self {
        case .extraSmall: return 0.65
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.3
        }
    }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.extraSmall, .japanese): return "極小 (Mini)"
        case (.extraSmall, .english): return "Mini"
        case (.small, .japanese): return "小 (Small)"
        case (.small, .english): return "Small"
        case (.medium, .japanese): return "中 (Medium)"
        case (.medium, .english): return "Medium"
        case (.large, .japanese): return "大 (Large)"
        case (.large, .english): return "Large"
        }
    }
    
    func windowDimensions(orientation: TimerOrientation) -> (width: CGFloat, height: CGFloat) {
        switch orientation {
        case .horizontal:
            switch self {
            case .extraSmall: return (278, 92)
            case .small: return (370, 160)
            case .medium: return (480, 195)
            case .large: return (600, 235)
            }
        case .vertical:
            switch self {
            case .extraSmall: return (110, 260)
            case .small: return (140, 340)
            case .medium: return (180, 440)
            case .large: return (220, 560)
            }
        }
    }
}

enum TimerMode: String, CaseIterable, Identifiable, Codable {
    case countdown = "カウントダウン"
    case countup = "カウントアップ"
    case pomodoro = "ポモドーロ"
    
    var id: String { rawValue }

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.countdown, .japanese): return "カウントダウン"
        case (.countdown, .english): return "Countdown"
        case (.countup, .japanese): return "カウントアップ"
        case (.countup, .english): return "Count Up"
        case (.pomodoro, .japanese): return "ポモドーロ"
        case (.pomodoro, .english): return "Pomodoro"
        }
    }
}

enum PomodoroPhase: String {
    case work = "集中 (Work)"
    case rest = "休憩 (Break)"

    func title(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.work, .japanese): return "集中 (Work)"
        case (.work, .english): return "Focus (Work)"
        case (.rest, .japanese): return "休憩 (Break)"
        case (.rest, .english): return "Break"
        }
    }
}

@MainActor
class TimerSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "saved_language")
            MenuBarManager.shared.updateContextMenu()
            MenuBarManager.shared.updateTitle()
            SettingsWindowManager.shared.updateTitle(settings: self)
            StatsWindowManager.shared.updateTitle()
        }
    }

    var l10n: L10n {
        L10n(language: language)
    }

    @Published var orientation: TimerOrientation {
        didSet { UserDefaults.standard.set(orientation.rawValue, forKey: "saved_orientation") }
    }
    @Published var theme: TimerTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "saved_theme") }
    }
    @Published var size: TimerSize {
        didSet { UserDefaults.standard.set(size.rawValue, forKey: "saved_size") }
    }
    @Published var mode: TimerMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "saved_mode") }
    }
    
    // ウィンドウ配置レイヤー (最前面 / 標準 / デスクトップ貼り付けウィジェット)
    @Published var windowPlacement: WindowPlacement {
        didSet {
            UserDefaults.standard.set(windowPlacement.rawValue, forKey: "saved_window_placement")
            isAlwaysOnTop = (windowPlacement == .floating)
            MainWindowController.shared.updateWindowPlacement()
        }
    }
    
    @Published var isAlwaysOnTop: Bool {
        didSet {
            UserDefaults.standard.set(isAlwaysOnTop, forKey: "saved_always_on_top")
        }
    }
    
    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "saved_sound_enabled") }
    }
    @Published var isFlashEnabled: Bool {
        didSet { UserDefaults.standard.set(isFlashEnabled, forKey: "saved_flash_enabled") }
    }
    
    // ✕ボタン挙動
    @Published var closeAction: CloseAction {
        didSet { UserDefaults.standard.set(closeAction.rawValue, forKey: "saved_close_action") }
    }
    
    // 起動時にウィンドウを隠す (メニューバー常駐起動)
    @Published var startHidden: Bool {
        didSet { UserDefaults.standard.set(startHidden, forKey: "saved_start_hidden") }
    }
    
    // Dock表示
    @Published var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "saved_show_in_dock")
            updateDockPolicy()
        }
    }
    
    // メニューバー表示
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "saved_show_in_menubar")
            MenuBarManager.shared.updateVisibility()
        }
    }
    
    // メニューバーのテキスト表示スタイル
    @Published var menuBarFormat: MenuBarDisplayFormat {
        didSet {
            UserDefaults.standard.set(menuBarFormat.rawValue, forKey: "saved_menubar_format")
            MenuBarManager.shared.updateTitle()
        }
    }
    
    init() {
        if let rawLang = UserDefaults.standard.string(forKey: "saved_language"),
           let lang = AppLanguage(rawValue: rawLang) {
            self.language = lang
        } else {
            self.language = .english
        }

        if let rawClose = UserDefaults.standard.string(forKey: "saved_close_action"),
           let action = CloseAction(rawValue: rawClose) {
            self.closeAction = action
        } else {
            self.closeAction = .hideToMenuBar
        }
        
        if UserDefaults.standard.object(forKey: "saved_start_hidden") != nil {
            self.startHidden = UserDefaults.standard.bool(forKey: "saved_start_hidden")
        } else {
            self.startHidden = false
        }
        
        if UserDefaults.standard.object(forKey: "saved_show_in_dock") != nil {
            self.showInDock = UserDefaults.standard.bool(forKey: "saved_show_in_dock")
        } else {
            self.showInDock = true
        }
        
        if UserDefaults.standard.object(forKey: "saved_show_in_menubar") != nil {
            self.showInMenuBar = UserDefaults.standard.bool(forKey: "saved_show_in_menubar")
        } else {
            self.showInMenuBar = true
        }
        
        if let rawFormat = UserDefaults.standard.string(forKey: "saved_menubar_format"),
           let format = MenuBarDisplayFormat(rawValue: rawFormat) {
            self.menuBarFormat = format
        } else {
            self.menuBarFormat = .english
        }
        
        if let rawOrient = UserDefaults.standard.string(forKey: "saved_orientation"),
           let orient = TimerOrientation(rawValue: rawOrient) {
            self.orientation = orient
        } else {
            self.orientation = .horizontal
        }
        
        if let rawTheme = UserDefaults.standard.string(forKey: "saved_theme"),
           let theme = TimerTheme(rawValue: rawTheme) {
            self.theme = theme
        } else {
            self.theme = .color
        }
        
        if let rawSize = UserDefaults.standard.string(forKey: "saved_size"),
           let size = TimerSize(rawValue: rawSize) {
            self.size = size
        } else {
            self.size = .medium
        }
        
        if let rawMode = UserDefaults.standard.string(forKey: "saved_mode"),
           let mode = TimerMode(rawValue: rawMode) {
            self.mode = mode
        } else {
            self.mode = .countdown
        }
        
        if let rawPlacement = UserDefaults.standard.string(forKey: "saved_window_placement"),
           let placement = WindowPlacement(rawValue: rawPlacement) {
            self.windowPlacement = placement
            self.isAlwaysOnTop = (placement == .floating)
        } else {
            if UserDefaults.standard.object(forKey: "saved_always_on_top") != nil {
                let onTop = UserDefaults.standard.bool(forKey: "saved_always_on_top")
                self.isAlwaysOnTop = onTop
                self.windowPlacement = onTop ? .floating : .normal
            } else {
                self.isAlwaysOnTop = true
                self.windowPlacement = .floating
            }
        }
        
        if UserDefaults.standard.object(forKey: "saved_sound_enabled") != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: "saved_sound_enabled")
        } else {
            self.isSoundEnabled = true
        }
        
        if UserDefaults.standard.object(forKey: "saved_flash_enabled") != nil {
            self.isFlashEnabled = UserDefaults.standard.bool(forKey: "saved_flash_enabled")
        } else {
            self.isFlashEnabled = true
        }
        
        updateDockPolicy()
    }
    
    func cycleNextPlacement() {
        switch windowPlacement {
        case .floating:
            windowPlacement = .normal
        case .normal:
            windowPlacement = .desktopWidget
        case .desktopWidget:
            windowPlacement = .floating
        }
    }
    
    func updateDockPolicy() {
        DispatchQueue.main.async {
            let policy: NSApplication.ActivationPolicy = self.showInDock ? .regular : .accessory
            NSApp.setActivationPolicy(policy)
        }
    }
}
