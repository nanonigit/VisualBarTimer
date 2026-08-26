import SwiftUI

struct DigitalDisplay: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    
    @State private var isEditing: Bool = false
    @State private var inputMinutes: String = ""
    @FocusState private var isFocused: Bool
    
    var timeString: String {
        let time = engine.currentMode == .countup ? engine.elapsedTime : engine.remainingTime
        let totalSeconds = max(0, Int(ceil(time)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var modeBadgeText: String {
        switch engine.currentMode {
        case .countdown:
            return "COUNTDOWN"
        case .countup:
            return "COUNTUP"
        case .pomodoro:
            return engine.pomodoroPhase == .work ? "POMO • WORK" : "POMO • BREAK"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(modeBadgeText)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(badgeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeColor.opacity(0.15))
                .clipShape(Capsule())
            
            if isEditing {
                HStack(spacing: 4) {
                    TextField("分", text: $inputMinutes)
                        .textFieldStyle(.plain)
                        .font(.system(size: settings.size == .extraSmall ? 16 : (settings.size == .small ? 20 : (settings.size == .medium ? 26 : 32)), weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: settings.size == .extraSmall ? 55 : 75)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.cyan, lineWidth: 1.5)
                        )
                        .focused($isFocused)
                        .onSubmit {
                            applyInput()
                        }
                    
                    Text("分")
                        .font(.system(size: settings.size == .extraSmall ? 11 : 13, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Button("決定") {
                        applyInput()
                    }
                    .font(.system(size: settings.size == .extraSmall ? 9 : 11, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.8))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 6) {
                    Text(timeString)
                        .font(.system(size: settings.size == .extraSmall ? 17 : (settings.size == .small ? 22 : (settings.size == .medium ? 28 : 36)), weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2)
                    
                    if !engine.isRunning {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !engine.isRunning {
                        startEditing()
                    }
                }
                .help("クリックして分数を直接入力")
            }
        }
    }
    
    private func startEditing() {
        let currentMins = max(1, Int(round(engine.targetDuration / 60)))
        inputMinutes = "\(currentMins)"
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isFocused = true
        }
    }
    
    private func applyInput() {
        if let mins = Double(inputMinutes), mins > 0 {
            engine.setDuration(mins * 60)
        }
        isEditing = false
    }
    
    private var badgeColor: Color {
        if engine.currentMode == .pomodoro {
            return engine.pomodoroPhase == .work ? .orange : .green
        }
        return .cyan
    }
}
