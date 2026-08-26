import SwiftUI
import Combine

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
    
    init() {
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
    }
}
