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
    @Published var orientation: TimerOrientation = .horizontal
    @Published var theme: TimerTheme = .color
    @Published var size: TimerSize = .medium
    @Published var mode: TimerMode = .countdown
    @Published var isAlwaysOnTop: Bool = true
    @Published var isSoundEnabled: Bool = true
    @Published var isFlashEnabled: Bool = true
    @Published var showControls: Bool = true
}
