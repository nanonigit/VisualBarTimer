import SwiftUI
import Combine
import AppKit

enum MenuBarDisplayFormat: String, CaseIterable, Identifiable, Codable {
    case english = "m 表示 (⏱️ 45m)"
    case japanese = "分 表示 (⏱️ 45分)"
    case numberOnly = "数字のみ (アイコンなし: 45)"
    case iconOnly = "アイコンのみ (⏱️)"
    
    var id: String { rawValue }
}

enum CloseAction: String, CaseIterable, Identifiable, Codable {
    case hideToMenuBar = "メニューバーに隠す (バックグラウンド常駐)"
    case quit = "アプリを完全に終了"
    
    var id: String { rawValue }
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
}

enum PomodoroPhase: String {
    case work = "集中 (Work)"
    case rest = "休憩 (Break)"
}

@MainActor
class TimerSettings: ObservableObject {
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
    @Published var isAlwaysOnTop: Bool {
        didSet { UserDefaults.standard.set(isAlwaysOnTop, forKey: "saved_always_on_top") }
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
        if let rawClose = UserDefaults.standard.string(forKey: "saved_close_action"),
           let action = CloseAction(rawValue: rawClose) {
            self.closeAction = action
        } else {
            self.closeAction = .hideToMenuBar
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
        
        if UserDefaults.standard.object(forKey: "saved_always_on_top") != nil {
            self.isAlwaysOnTop = UserDefaults.standard.bool(forKey: "saved_always_on_top")
        } else {
            self.isAlwaysOnTop = true
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
    
    func updateDockPolicy() {
        DispatchQueue.main.async {
            let policy: NSApplication.ActivationPolicy = self.showInDock ? .regular : .accessory
            NSApp.setActivationPolicy(policy)
        }
    }
}
