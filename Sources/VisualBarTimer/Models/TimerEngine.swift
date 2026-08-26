import SwiftUI
import Combine
import UserNotifications

@MainActor
class TimerEngine: ObservableObject {
    @Published var targetDuration: TimeInterval = 600 // 10分
    @Published var remainingTime: TimeInterval = 600
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false
    @Published var isFlashing: Bool = false
    @Published var pomodoroPhase: PomodoroPhase = .work
    
    private var timer: Timer?
    private var flashTimer: Timer?
    private var startTime: Date?
    private var pausedRemainingTime: TimeInterval = 600
    private var pausedElapsedTime: TimeInterval = 0
    
    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        switch currentMode {
        case .countdown:
            return max(0, min(1, remainingTime / targetDuration))
        case .countup:
            return max(0, min(1, elapsedTime / targetDuration))
        case .pomodoro:
            return max(0, min(1, remainingTime / targetDuration))
        }
    }
    
    var currentMode: TimerMode = .countdown {
        didSet {
            reset()
        }
    }
    
    init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func start() {
        guard !isRunning else { return }
        stopFlashing()
        isFinished = false
        isRunning = true
        startTime = Date()
        
        SoundManager.shared.playStart()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        pausedRemainingTime = remainingTime
        pausedElapsedTime = elapsedTime
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    func reset() {
        pause()
        stopFlashing()
        isFinished = false
        
        if currentMode == .pomodoro {
            targetDuration = pomodoroPhase == .work ? (25 * 60) : (5 * 60)
        }
        
        remainingTime = targetDuration
        elapsedTime = 0
        pausedRemainingTime = targetDuration
        pausedElapsedTime = 0
    }
    
    func setDuration(_ duration: TimeInterval) {
        let isWasRunning = isRunning
        pause()
        stopFlashing()
        isFinished = false
        targetDuration = max(10, duration)
        remainingTime = targetDuration
        elapsedTime = 0
        pausedRemainingTime = targetDuration
        pausedElapsedTime = 0
        
        if isWasRunning {
            start()
        }
    }
    
    func setProgressRatio(_ ratio: Double) {
        let clamped = max(0.01, min(1.0, ratio))
        // 10秒単位に丸める
        var seconds = targetDuration * clamped
        if targetDuration > 60 {
            seconds = round(seconds / 10.0) * 10.0
        }
        setDuration(seconds)
    }
    
    private func tick() {
        guard let start = startTime else { return }
        let delta = Date().timeIntervalSince(start)
        
        switch currentMode {
        case .countdown, .pomodoro:
            let newRemaining = pausedRemainingTime - delta
            if newRemaining <= 0 {
                remainingTime = 0
                elapsedTime = targetDuration
                timerFinished()
            } else {
                remainingTime = newRemaining
                elapsedTime = targetDuration - newRemaining
            }
        case .countup:
            let newElapsed = pausedElapsedTime + delta
            if newElapsed >= targetDuration {
                elapsedTime = targetDuration
                remainingTime = 0
                timerFinished()
            } else {
                elapsedTime = newElapsed
                remainingTime = max(0, targetDuration - newElapsed)
            }
        }
    }
    
    private func timerFinished() {
        pause()
        isFinished = true
        startFlashing()
        SoundManager.shared.playAlarm()
        sendNotification()
        
        if currentMode == .pomodoro {
            // ポモドーロの自動フェーズ切り替え
            pomodoroPhase = (pomodoroPhase == .work) ? .rest : .work
            targetDuration = (pomodoroPhase == .work) ? (25 * 60) : (5 * 60)
            remainingTime = targetDuration
            elapsedTime = 0
            pausedRemainingTime = targetDuration
            pausedElapsedTime = 0
        }
    }
    
    private func startFlashing() {
        isFlashing = true
        var count = 0
        flashTimer?.invalidate()
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            Task { @MainActor in
                self.isFlashing.toggle()
                count += 1
                if count >= 16 { // 約5.5秒点滅
                    self.stopFlashing()
                }
            }
        }
    }
    
    private func stopFlashing() {
        flashTimer?.invalidate()
        flashTimer = nil
        isFlashing = false
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        if currentMode == .pomodoro {
            content.title = pomodoroPhase == .work ? "休憩時間終了！" : "集中タイム終了！"
            content.body = pomodoroPhase == .work ? "次の作業セッションを始めましょう。" : "5分間の休憩を取りましょう。"
        } else {
            content.title = "タイマー終了"
            content.body = "\(formatTime(targetDuration))が経過しました。"
        }
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 && seconds == 0 {
            return "\(minutes)分"
        } else if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}
