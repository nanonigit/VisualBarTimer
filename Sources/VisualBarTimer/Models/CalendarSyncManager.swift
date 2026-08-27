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
    @Published var lastSyncMessage: String? = nil
    
    private init() {
        if let savedId = UserDefaults.standard.string(forKey: "saved_calendar_id") {
            self.selectedCalendarId = savedId
        }
        checkAuthorization()
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
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor in
                    self?.isAuthorized = granted
                    if granted {
                        self?.loadCalendars()
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
            self.createEvent(for: dayLog, completion: completion)
        }
        
        if !isAuthorized {
            requestAccess { granted in
                if granted {
                    proceed()
                } else {
                    let msg = "カレンダーへのアクセスが許可されていません（システム設定で許可してください）"
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
        
        // 日付のパース
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dayLog.dateString) else {
            let msg = "日付の形式が不正です"
            lastSyncMessage = msg
            completion?(false, msg)
            return
        }
        
        // 今日の場合は現在時刻を終了時刻、または日中の時間帯に設定
        let calendarCalc = Calendar.current
        let now = Date()
        let isToday = calendarCalc.isDateInToday(date)
        
        let duration = dayLog.totalSeconds
        if isToday {
            event.endDate = now
            event.startDate = now.addingTimeInterval(-duration)
        } else {
            // 過去の日の場合はその日の 10:00 開始とする
            let start = calendarCalc.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
            event.startDate = start
            event.endDate = start.addingTimeInterval(duration)
        }
        
        var notes = "【VisualBarTimer 稼働記録】\n"
        notes += "・総タイマー時間: \(formattedTime)\n"
        notes += "・セッション回数: \(dayLog.sessionCount)回\n"
        if !dayLog.sessions.isEmpty {
            notes += "\n【詳細セッション】\n"
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
            let msg = "カレンダー「\(calendar.title)」に『\(event.title ?? "")』を登録しました！"
            self.lastSyncMessage = msg
            completion?(true, msg)
        } catch {
            let msg = "カレンダー保存エラー: \(error.localizedDescription)"
            self.lastSyncMessage = msg
            completion?(false, msg)
        }
    }
}
