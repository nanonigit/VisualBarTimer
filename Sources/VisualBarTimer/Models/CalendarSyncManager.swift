import Foundation
import EventKit
import AppKit

enum CalendarSyncStyle: String, CaseIterable, Identifiable, Codable {
    case actualTimeSlots = "実際に動いていた時間帯にそれぞれ記録 (タイムログ)"
    case allDaySummary = "その日の終日予定として1つにまとめて記録"
    
    var id: String { rawValue }
}

struct CalendarOption: Identifiable, Hashable {
    var id: String { calendar.calendarIdentifier }
    let calendar: EKCalendar
    
    var displayName: String {
        let sourceTitle = calendar.source.title
        return "\(calendar.title) (\(sourceTitle))"
    }
}

@MainActor
final class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()
    
    private let eventStore = EKEventStore()
    @Published var isAuthorized: Bool = false
    @Published var availableCalendars: [CalendarOption] = []
    @Published var selectedCalendarId: String = "" {
        didSet {
            UserDefaults.standard.set(selectedCalendarId, forKey: "saved_calendar_id")
        }
    }
    @Published var autoSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "saved_auto_calendar_sync")
            if autoSyncEnabled {
                checkAndAutoSyncPreviousDays()
            }
        }
    }
    @Published var syncStyle: CalendarSyncStyle {
        didSet {
            UserDefaults.standard.set(syncStyle.rawValue, forKey: "saved_calendar_sync_style")
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
        
        if let rawStyle = UserDefaults.standard.string(forKey: "saved_calendar_sync_style"),
           let style = CalendarSyncStyle(rawValue: rawStyle) {
            self.syncStyle = style
        } else {
            self.syncStyle = .actualTimeSlots
        }
        
        if let savedId = UserDefaults.standard.string(forKey: "saved_calendar_id") {
            self.selectedCalendarId = savedId
        }
        
        checkAuthorization()
        setupDayChangeObserver()
    }
    
    private func setupDayChangeObserver() {
        // 1. システムの日付変更通知
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndAutoSyncPreviousDays()
            }
        }
        
        // 2. Macのスリープ復帰時にも未同期の前日データをチェック
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndAutoSyncPreviousDays()
            }
        }
        
        // 3. アプリが前面に復帰した時
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
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
    
    func requestAccess(completion: ((Bool) -> Void)? = nil) {
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
                    completion?(granted)
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
                    completion?(granted)
                }
            }
        }
    }
    
    func loadCalendars() {
        let rawCalendars = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
        self.availableCalendars = rawCalendars.map { CalendarOption(calendar: $0) }
        
        if selectedCalendarId.isEmpty || !availableCalendars.contains(where: { $0.id == selectedCalendarId }) {
            if let defaultCal = eventStore.defaultCalendarForNewEvents {
                selectedCalendarId = defaultCal.calendarIdentifier
            } else if let first = availableCalendars.first {
                selectedCalendarId = first.id
            }
        }
    }
    
    func selectCalendar(id: String) {
        selectedCalendarId = id
    }
    
    var selectedCalendarName: String {
        if let found = availableCalendars.first(where: { $0.id == selectedCalendarId }) {
            return found.displayName
        }
        return "デフォルトカレンダー"
    }
    
    // MARK: - 日付変更時の前日自動同期
    func checkAndAutoSyncPreviousDays() {
        guard autoSyncEnabled else { return }
        
        let executeSync = { [weak self] in
            guard let self = self else { return }
            let logManager = ActivityLogManager.shared
            let todayKey = logManager.todayKey
            var currentSynced = self.syncedDateKeys
            
            for (dateKey, dayLog) in logManager.dailyLogs {
                if dateKey < todayKey && !currentSynced.contains(dateKey) && dayLog.totalSeconds >= 60 {
                    self.syncDayLogToCalendar(dayLog: dayLog) { [weak self] success, _ in
                        if success {
                            currentSynced.insert(dateKey)
                            self?.syncedDateKeys = currentSynced
                        }
                    }
                }
            }
        }
        
        if isAuthorized {
            executeSync()
        } else {
            requestAccess { granted in
                if granted {
                    executeSync()
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
            self.createEvents(for: dayLog) { success, msg in
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
    
    private func createEvents(for dayLog: DayLog, completion: ((Bool, String) -> Void)? = nil) {
        let targetCalendar: EKCalendar?
        if !selectedCalendarId.isEmpty,
           let found = availableCalendars.first(where: { $0.id == selectedCalendarId }) {
            targetCalendar = found.calendar
        } else {
            targetCalendar = eventStore.defaultCalendarForNewEvents
        }
        
        guard let calendar = targetCalendar else {
            let msg = "登録先カレンダーが見つかりませんでした"
            lastSyncMessage = msg
            completion?(false, msg)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dayLog.dateString) else {
            let msg = "日付形式が不正です"
            lastSyncMessage = msg
            completion?(false, msg)
            return
        }
        
        do {
            if syncStyle == .allDaySummary {
                // 終日サマリー形式
                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                let formattedTime = dayLog.formattedDuration
                event.title = "⏱️ タイマー集中作業: \(formattedTime)"
                
                let calendarCalc = Calendar.current
                let startOfDay = calendarCalc.startOfDay(for: date)
                event.isAllDay = true
                event.startDate = startOfDay
                event.endDate = startOfDay
                event.notes = buildNotes(dayLog: dayLog)
                
                try eventStore.save(event, span: .thisEvent)
                let msg = "カレンダー「\(calendar.title)」の終日欄に登録しました！"
                self.lastSyncMessage = msg
                completion?(true, msg)
            } else {
                // 実際に動いていた時間帯にそれぞれ記録 (タイムログ)
                if dayLog.sessions.isEmpty {
                    // セッション詳細がない場合はその日の日中に1つのイベントとして作成
                    let event = EKEvent(eventStore: eventStore)
                    event.calendar = calendar
                    event.title = "⏱️ タイマー集中作業 (\(dayLog.formattedDuration))"
                    let calendarCalc = Calendar.current
                    let start = calendarCalc.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
                    event.startDate = start
                    event.endDate = start.addingTimeInterval(dayLog.totalSeconds)
                    event.notes = buildNotes(dayLog: dayLog)
                    try eventStore.save(event, span: .thisEvent)
                } else {
                    for session in dayLog.sessions {
                        let event = EKEvent(eventStore: eventStore)
                        event.calendar = calendar
                        let mins = max(1, Int(round(session.durationSeconds / 60.0)))
                        let catTitle = session.category.isEmpty ? "⏱️ タイマー集中" : session.category
                        event.title = "\(catTitle) (\(mins)分)"
                        event.startDate = session.startTime
                        event.endDate = session.endTime
                        event.notes = "VisualBarTimer 集中セッション\n・カテゴリ: \(catTitle)\n・モード: \(session.mode)\n・稼働時間: \(mins)分"
                        try eventStore.save(event, span: .thisEvent)
                    }
                }
                
                let msg = "カレンダー「\(calendar.title)」に実際の稼働時間帯（\(dayLog.sessions.count)件）を登録しました！"
                self.lastSyncMessage = msg
                completion?(true, msg)
            }
        } catch {
            let msg = "カレンダー保存エラー: \(error.localizedDescription)"
            self.lastSyncMessage = msg
            completion?(false, msg)
        }
    }
    
    private func buildNotes(dayLog: DayLog) -> String {
        var notes = "【VisualBarTimer 稼働実績】\n"
        notes += "・総タイマー時間: \(dayLog.formattedDuration)\n"
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
        return notes
    }
}
