import Foundation
import EventKit
import AppKit

@MainActor
final class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()
    
    private let eventStore = EKEventStore()
    @Published var isAuthorized: Bool = false
    @Published var availableCalendars: [EKCalendar] = []
    @Published var selectedCalendarId: String = ""
    @Published var autoSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "saved_auto_calendar_sync")
            if autoSyncEnabled {
                checkAndAutoSyncPreviousDays()
            }
        }
    }
    @Published var lastSyncMessage: String? = nil
    
    private var syncedDateKeys: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: "saved_synced_calendar_dates") ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "saved_synced_calendar_dates")
        }
    }
    
    private init() {
        if UserDefaults.standard.object(forKey: "saved_auto_calendar_sync") != nil {
            self.autoSyncEnabled = UserDefaults.standard.bool(forKey: "saved_auto_calendar_sync")
        } else {
            self.autoSyncEnabled = true
        }
        
        if let savedId = UserDefaults.standard.string(forKey: "saved_calendar_id") {
            self.selectedCalendarId = savedId
        }
        
        checkAuthorization()
        setupDayChangeObserver()
    }
    
    private func setupDayChangeObserver() {
        // 日付が変わった瞬間に自動同期
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndAutoSyncPreviousDays()
            }
        }
    }
    
    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            self.isAuthorized = (status == .fullAccess || status == .authorized)
        } else {
            self.isAuthorized = (status == .authorized)
        }
        if self.isAuthorized {
            loadCalendars()
            if autoSyncEnabled {
                checkAndAutoSyncPreviousDays()
            }
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor in
                    self?.isAuthorized = granted
                    if granted {
                        self?.loadCalendars()
                        if self?.autoSyncEnabled == true {
                            self?.checkAndAutoSyncPreviousDays()
                        }
                    }
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                Task { @MainActor in
                    self?.isAuthorized = granted
                    if granted {
                        self?.loadCalendars()
                        if self?.autoSyncEnabled == true {
                            self?.checkAndAutoSyncPreviousDays()
                        }
                    }
                    completion(granted)
                }
            }
        }
    }
    
    func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)
        self.availableCalendars = calendars
        if selectedCalendarId.isEmpty, let first = calendars.first {
            selectedCalendarId = first.calendarIdentifier
            UserDefaults.standard.set(selectedCalendarId, forKey: "saved_calendar_id")
        }
    }
    
    func selectCalendar(id: String) {
        selectedCalendarId = id
        UserDefaults.standard.set(id, forKey: "saved_calendar_id")
    }
    
    // MARK: - 日付変更時の前日自動同期
    func checkAndAutoSyncPreviousDays() {
        guard autoSyncEnabled else { return }
        let logManager = ActivityLogManager.shared
        let todayKey = logManager.todayKey
        var currentSynced = syncedDateKeys
        
        for (dateKey, dayLog) in logManager.dailyLogs {
            // 今日以外の過去の日付で、未同期かつ1分以上稼働があるもの
            if dateKey < todayKey && !currentSynced.contains(dateKey) && dayLog.totalSeconds >= 60 {
                syncDayLogToCalendar(dayLog: dayLog) { [weak self] success, _ in
                    if success {
                        currentSynced.insert(dateKey)
                        self?.syncedDateKeys = currentSynced
                    }
                }
            }
        }
    }
    
    /// 特定の日の総タイマー稼働時間をカレンダーにイベントとして追加
    func syncDayLogToCalendar(dayLog: DayLog, completion: ((Bool, String) -> Void)? = nil) {
        guard dayLog.totalSeconds >= 60 else {
            let msg = "稼働時間が1分未満のためカレンダーに登録しませんでした"
            lastSyncMessage = msg
            completion?(false, msg)
            return
        }
        
        let proceed = { [weak self] in
            guard let self = self else { return }
            self.createEvent(for: dayLog) { success, msg in
                if success {
                    var set = self.syncedDateKeys
                    set.insert(dayLog.dateString)
                    self.syncedDateKeys = set
                }
                completion?(success, msg)
            }
        }
        
        if !isAuthorized {
            requestAccess { granted in
                if granted {
                    proceed()
                } else {
                    let msg = "カレンダーアクセスが未許可です"
                    self.lastSyncMessage = msg
                    completion?(false, msg)
                }
            }
        } else {
            proceed()
        }
    }
    
    private func createEvent(for dayLog: DayLog, completion: ((Bool, String) -> Void)? = nil) {
        let targetCalendar: EKCalendar?
        if !selectedCalendarId.isEmpty,
           let found = availableCalendars.first(where: { $0.calendarIdentifier == selectedCalendarId }) {
            targetCalendar = found
        } else {
            targetCalendar = eventStore.defaultCalendarForNewEvents
        }
        
        guard let calendar = targetCalendar else {
            let msg = "登録先カレンダーが見つかりませんでした"
            lastSyncMessage = msg
            completion?(false, msg)
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        
        let formattedTime = dayLog.formattedDuration
        event.title = "⏱️ タイマー集中作業 (\(formattedTime))"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dayLog.dateString) else {
            let msg = "日付形式が不正です"
            lastSyncMessage = msg
            completion?(false, msg)
            return
        }
        
        let calendarCalc = Calendar.current
        let isToday = calendarCalc.isDateInToday(date)
        let duration = dayLog.totalSeconds
        
        if isToday {
            let now = Date()
            event.endDate = now
            event.startDate = now.addingTimeInterval(-duration)
        } else {
            // 前日の場合は最初のセッション開始時刻、または前日10:00を開始とする
            if let firstSession = dayLog.sessions.first {
                event.startDate = firstSession.startTime
                event.endDate = firstSession.startTime.addingTimeInterval(duration)
            } else {
                let start = calendarCalc.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
                event.startDate = start
                event.endDate = start.addingTimeInterval(duration)
            }
        }
        
        var notes = "【VisualBarTimer 稼働実績】\n"
        notes += "・総タイマー時間: \(formattedTime)\n"
        notes += "・セッション回数: \(dayLog.sessionCount)回\n"
        if !dayLog.sessions.isEmpty {
            notes += "\n【セッション内訳】\n"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            for (i, session) in dayLog.sessions.enumerated() {
                let sStart = timeFormatter.string(from: session.startTime)
                let sEnd = timeFormatter.string(from: session.endTime)
                let mins = Int(round(session.durationSeconds / 60.0))
                notes += "\(i + 1). \(sStart)〜\(sEnd) (\(mins)分 - \(session.mode))\n"
            }
        }
        event.notes = notes
        
        do {
            try eventStore.save(event, span: .thisEvent)
            let msg = "カレンダーに『\(event.title ?? "")』を自動登録しました！"
            self.lastSyncMessage = msg
            completion?(true, msg)
        } catch {
            let msg = "カレンダー保存エラー: \(error.localizedDescription)"
            self.lastSyncMessage = msg
            completion?(false, msg)
        }
    }
}
