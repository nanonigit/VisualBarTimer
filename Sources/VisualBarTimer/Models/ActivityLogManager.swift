import Foundation
import AppKit

struct SessionLog: Codable, Identifiable {
    var id: UUID = UUID()
    let startTime: Date
    let endTime: Date
    let durationSeconds: TimeInterval
    let mode: String
}

struct DayLog: Codable, Identifiable {
    var id: String { dateString } // "yyyy-MM-dd"
    let dateString: String
    var totalSeconds: TimeInterval
    var sessionCount: Int
    var sessions: [SessionLog]
    
    var formattedDuration: String {
        let total = Int(totalSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

@MainActor
final class ActivityLogManager: ObservableObject {
    static let shared = ActivityLogManager()
    
    @Published var dailyLogs: [String: DayLog] = [:] // key: "yyyy-MM-dd"
    @Published var todayTotalSeconds: TimeInterval = 0
    
    private var sessionStartTime: Date?
    private var activeAccumulatedDelta: TimeInterval = 0
    private let fileManager = FileManager.default
    
    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VisualBarTimer", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("activity_logs.json")
    }
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    private init() {
        loadLogs()
        updateTodayTotal()
    }
    
    var todayKey: String {
        Self.dateFormatter.string(from: Date())
    }
    
    var todayFormattedDuration: String {
        let total = Int(todayTotalSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // タイマー開始時
    func onTimerStarted() {
        sessionStartTime = Date()
    }
    
    // タイマー停止・リセット・終了時
    func onTimerStopped(mode: String, elapsedDelta: TimeInterval) {
        guard let start = sessionStartTime, elapsedDelta > 1.0 else {
            sessionStartTime = nil
            return
        }
        
        let end = Date()
        let session = SessionLog(startTime: start, endTime: end, durationSeconds: elapsedDelta, mode: mode)
        recordSession(session)
        sessionStartTime = nil
    }
    
    // 進行中の加算（1秒ごとなど）
    func addRunningTime(seconds: TimeInterval) {
        todayTotalSeconds += seconds
        let key = todayKey
        var day = dailyLogs[key] ?? DayLog(dateString: key, totalSeconds: 0, sessionCount: 0, sessions: [])
        day.totalSeconds += seconds
        dailyLogs[key] = day
        saveLogs()
        MenuBarManager.shared.updateTitle()
    }
    
    private func recordSession(_ session: SessionLog) {
        let key = todayKey
        var day = dailyLogs[key] ?? DayLog(dateString: key, totalSeconds: 0, sessionCount: 0, sessions: [])
        day.sessions.append(session)
        day.sessionCount += 1
        dailyLogs[key] = day
        updateTodayTotal()
        saveLogs()
    }
    
    /// 特定の日付の総稼働時間を手動修正
    func updateDayTotal(dateKey: String, newTotalSeconds: TimeInterval) {
        let clamped = max(0, newTotalSeconds)
        var day = dailyLogs[dateKey] ?? DayLog(dateString: dateKey, totalSeconds: 0, sessionCount: 0, sessions: [])
        day.totalSeconds = clamped
        if day.sessionCount == 0 && clamped > 0 {
            day.sessionCount = 1
        }
        dailyLogs[dateKey] = day
        if dateKey == todayKey {
            todayTotalSeconds = clamped
        }
        saveLogs()
        MenuBarManager.shared.updateTitle()
    }
    
    private func updateTodayTotal() {
        todayTotalSeconds = dailyLogs[todayKey]?.totalSeconds ?? 0
    }
    
    // MARK: - 永続化 (JSON)
    private func loadLogs() {
        guard fileManager.fileExists(atPath: storageURL.path),
              let data = try? Data(contentsOf: storageURL),
              let logs = try? JSONDecoder().decode([String: DayLog].self, from: data) else {
            return
        }
        self.dailyLogs = logs
    }
    
    private func saveLogs() {
        guard let data = try? JSONEncoder().encode(dailyLogs) else { return }
        try? data.write(to: storageURL)
    }
    
    // MARK: - エクスポート & 連携機能
    
    /// CSV形式の文字列を生成
    func exportCSV() -> String {
        var csv = "Date,TotalMinutes,TotalSeconds,SessionCount\n"
        let sortedKeys = dailyLogs.keys.sorted(by: >)
        for key in sortedKeys {
            if let log = dailyLogs[key] {
                let mins = String(format: "%.1f", log.totalSeconds / 60.0)
                let secs = Int(log.totalSeconds)
                csv += "\(log.dateString),\(mins),\(secs),\(log.sessionCount)\n"
            }
        }
        return csv
    }
    
    /// JSON形式の文字列を生成
    func exportJSON() -> String {
        guard let data = try? JSONEncoder().encode(dailyLogs),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }
    
    /// CSVファイルとして保存
    func saveCSVToFile() {
        let panel = NSSavePanel()
        panel.title = "タイマー稼働ログをCSVとして書き出し"
        panel.nameFieldStringValue = "VisualBarTimer_Logs_\(todayKey).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        
        if panel.runModal() == .OK, let url = panel.url {
            let csv = exportCSV()
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    /// JSONファイルとして保存
    func saveJSONToFile() {
        let panel = NSSavePanel()
        panel.title = "タイマー稼働ログをJSONとして書き出し"
        panel.nameFieldStringValue = "VisualBarTimer_Logs_\(todayKey).json"
        panel.allowedContentTypes = [.json]
        
        if panel.runModal() == .OK, let url = panel.url {
            let json = exportJSON()
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    /// Finderでログファイルを開く
    func openLogFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([storageURL])
    }
}
