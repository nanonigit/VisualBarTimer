import SwiftUI
import Combine
import UserNotifications

@MainActor
class TimerEngine: ObservableObject {
    @Published var targetDuration: TimeInterval = 600 {
        didSet {
            saveCurrentDuration()
        }
    }
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
    private var lastRecordedTime: Date?
    
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
            loadDurationForCurrentMode()
            reset()
        }
    }
    
    init() {
        if let rawMode = UserDefaults.standard.string(forKey: "saved_mode"),
           let mode = TimerMode(rawValue: rawMode) {
            self.currentMode = mode
        }
        
        loadDurationForCurrentMode()
        self.remainingTime = self.targetDuration
        self.pausedRemainingTime = self.targetDuration
        
        requestNotificationPermission()
    }
    
    private func saveCurrentDuration() {
        switch currentMode {
        case .countdown:
            UserDefaults.standard.set(targetDuration, forKey: "saved_countdown_duration")
        case .countup:
            UserDefaults.standard.set(targetDuration, forKey: "saved_countup_duration")
        case .pomodoro:
            if pomodoroPhase == .work {
                UserDefaults.standard.set(targetDuration, forKey: "saved_pomo_work_duration")
            } else {
                UserDefaults.standard.set(targetDuration, forKey: "saved_pomo_break_duration")
            }
        }
        UserDefaults.standard.set(targetDuration, forKey: "saved_target_duration")
    }
    
    private func loadDurationForCurrentMode() {
        let key: String
        let fallback: TimeInterval
        
        switch currentMode {
        case .countdown:
            key = "saved_countdown_duration"
            fallback = 600
        case .countup:
            key = "saved_countup_duration"
            fallback = 1800
        case .pomodoro:
            if pomodoroPhase == .work {
                key = "saved_pomo_work_duration"
                fallback = 1500
            } else {
                key = "saved_pomo_break_duration"
                fallback = 300
            }
        }
        
        let saved = UserDefaults.standard.double(forKey: key)
        if saved > 0 {
            self.targetDuration = saved
        } else {
            let globalSaved = UserDefaults.standard.double(forKey: "saved_target_duration")
            self.targetDuration = globalSaved > 0 ? globalSaved : fallback
        }
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
        lastRecordedTime = Date()
        
        ActivityLogManager.shared.onTimerStarted()
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
        
        let now = Date()
        if let last = lastRecordedTime {
            let remainingStep = now.timeIntervalSince(last)
            if remainingStep > 0 {
                ActivityLogManager.shared.addRunningTime(seconds: remainingStep)
            }
        }
        
        if let start = startTime {
            let delta = now.timeIntervalSince(start)
            ActivityLogManager.shared.onTimerStopped(mode: currentMode.rawValue, elapsedDelta: delta)
        }
        startTime = nil
        lastRecordedTime = nil
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    func reset() {
        if isRunning {
            pause()
        }
        stopFlashing()
        isFinished = false
        
        remainingTime = targetDuration
        elapsedTime = 0
        pausedRemainingTime = targetDuration
        pausedElapsedTime = 0
        MenuBarManager.shared.updateTitle()
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
        MenuBarManager.shared.updateTitle()
        
        if isWasRunning {
            start()
        }
    }
    
    func setProgressRatio(_ ratio: Double) {
        let clamped = max(0.01, min(1.0, ratio))
        var seconds = targetDuration * clamped
        if targetDuration > 60 {
            seconds = round(seconds / 10.0) * 10.0
        }
        setDuration(seconds)
    }
    
    private func tick() {
        guard let start = startTime else { return }
        let now = Date()
        let delta = now.timeIntervalSince(start)
        
        // 稼働時間のログ加算
        if let last = lastRecordedTime {
            let stepDelta = now.timeIntervalSince(last)
            if stepDelta >= 1.0 {
                ActivityLogManager.shared.addRunningTime(seconds: stepDelta)
                lastRecordedTime = now
            }
        }
        
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
        
        MenuBarManager.shared.updateTitle()
    }
    
    private func timerFinished() {
        if let start = startTime {
            let delta = Date().timeIntervalSince(start)
            ActivityLogManager.shared.onTimerStopped(mode: currentMode.rawValue, elapsedDelta: delta)
        }
        startTime = nil
        lastRecordedTime = nil
        
        pause()
        isFinished = true
        startFlashing()
        SoundManager.shared.playAlarm()
        sendNotification()
        
        if currentMode == .pomodoro {
            pomodoroPhase = (pomodoroPhase == .work) ? .rest : .work
            loadDurationForCurrentMode()
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
                if count >= 16 {
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
