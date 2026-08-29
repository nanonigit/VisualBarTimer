import SwiftUI
import AppKit
import EventKit

struct StatsWindowView: View {
    @ObservedObject var logManager = ActivityLogManager.shared
    @ObservedObject var calendarSync = CalendarSyncManager.shared
    var onClose: (() -> Void)? = nil
    
    @State private var copiedMessage: String? = nil
    @State private var editingDateKey: String? = nil
    @State private var syncStatusMessage: String? = nil
    @State private var deleteTargetDate: String? = nil
    @State private var showDeleteDayConfirm: Bool = false
    @State private var showClearAllConfirm: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("タイマー稼働ログ・統計")
                        .font(.system(size: 16, weight: .bold))
                    Text("日々の集中・タイマー稼働時間を記録・修正・カレンダー連携")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("閉じる") {
                    onClose?()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            // 今日のサマリーカード
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("本日の総タイマー稼働")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            openEditor(for: logManager.todayKey)
                        }) {
                            Label("時間を修正", systemImage: "pencil")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(logManager.todayFormattedMin)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("セッション回数")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(logManager.dailyLogs[logManager.todayKey]?.sessionCount ?? 0) 回")
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // カレンダー直接同期アクションバナー
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Google / Macカレンダーに今日の総時間を記録")
                            .font(.system(size: 12, weight: .bold))
                        Text("Google同期されているカレンダーに予定として自動登録されます")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        syncTodayToCalendar()
                    }) {
                        Label("カレンダーに書き込む", systemImage: "plus.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                
                if !calendarSync.availableCalendars.isEmpty {
                    HStack(spacing: 6) {
                        Text("保存先:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $calendarSync.selectedCalendarId) {
                            ForEach(calendarSync.availableCalendars, id: \.id) { opt in
                                Text(opt.displayName).tag(opt.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .font(.system(size: 10))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(10)
            .background(Color.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // 日別履歴リスト
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("日別履歴 (各日のカレンダー登録・修正・削除)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !logManager.dailyLogs.isEmpty {
                        Button(action: {
                            showClearAllConfirm = true
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "trash")
                                    .font(.system(size: 9))
                                Text("全履歴を消去")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("すべてのタイマー稼働履歴を削除してリセットします")
                    }
                }
                
                ScrollView {
                    VStack(spacing: 6) {
                        let sortedDays = logManager.dailyLogs.values.sorted(by: { $0.dateString > $1.dateString })
                        if sortedDays.isEmpty {
                            Text("まだ記録されたログはありません。タイマーを動かすと自動集計されます。")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(sortedDays) { day in
                                HStack {
                                    Text(day.dateString)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    if day.dateString == logManager.todayKey {
                                        Text("今日")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                    Spacer()
                                    Text("\(day.sessionCount)回")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text(day.formattedDuration)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .trailing)
                                    
                                    // カレンダー追加ボタン
                                    Button(action: {
                                        syncDayToCalendar(day)
                                    }) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 11))
                                            .foregroundColor(.blue.opacity(0.9))
                                            .padding(4)
                                            .background(Color.blue.opacity(0.12))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .help("この日の稼働時間をカレンダーに登録")
                                    
                                    // 修正ボタン
                                    Button(action: {
                                        openEditor(for: day.dateString)
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(4)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .help("この日の稼働時間を修正")
                                    
                                    // 削除ボタン
                                    Button(action: {
                                        deleteTargetDate = day.dateString
                                        showDeleteDayConfirm = true
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 10))
                                            .foregroundColor(.red.opacity(0.8))
                                            .padding(4)
                                            .background(Color.red.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .help("この日（\(day.dateString)）のログを削除")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
            
            Divider()
            
            // エクスポート & 連携アクション
            VStack(alignment: .leading, spacing: 10) {
                Text("ファイル書き出し & 外部連携")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    // CSV保存
                    Button(action: {
                        logManager.saveCSVToFile()
                    }) {
                        Label("CSV書き出し", systemImage: "arrow.down.doc.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    // JSON保存
                    Button(action: {
                        logManager.saveJSONToFile()
                    }) {
                        Label("JSON書き出し", systemImage: "curlybraces")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    // CSVコピー
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(logManager.exportCSV(), forType: .string)
                        showToast("CSVをコピーしました")
                    }) {
                        Label("CSVコピー", systemImage: "doc.on.doc")
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    // ログフォルダを開く
                    Button(action: {
                        logManager.openLogFolder()
                    }) {
                        Label("保存フォルダを開く", systemImage: "folder")
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                
                if let msg = syncStatusMessage ?? copiedMessage {
                    Text(msg)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
        }
        .padding(20)
        .frame(width: 520, height: 560)
        .sheet(item: Binding<IdentifiableDate?>(
            get: { editingDateKey.map { IdentifiableDate(dateKey: $0) } },
            set: { editingDateKey = $0?.dateKey }
        )) { item in
            EditDurationSheet(dateKey: item.dateKey) {
                editingDateKey = nil
            }
        }
        .alert("この日の履歴を削除しますか？", isPresented: $showDeleteDayConfirm) {
            Button("削除", role: .destructive) {
                if let target = deleteTargetDate {
                    logManager.deleteHistory(for: target)
                    showToast("\(target) のログを削除しました")
                }
                deleteTargetDate = nil
            }
            Button("キャンセル", role: .cancel) {
                deleteTargetDate = nil
            }
        } message: {
            if let target = deleteTargetDate {
                Text("\(target) の集中タイマー稼働ログとセッション履歴を完全に削除します。")
            }
        }
        .alert("全履歴を消去しますか？", isPresented: $showClearAllConfirm) {
            Button("すべて消去", role: .destructive) {
                logManager.clearAllHistory()
                showToast("すべての稼働履歴を削除しました")
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("これまでに記録されたすべてのタイマー稼働ログが完全に削除され、今日の稼働時間も0分にリセットされます。この操作は取り消せません。")
        }
    }
    
    private func syncTodayToCalendar() {
        let key = logManager.todayKey
        let dayLog = logManager.dailyLogs[key] ?? DayLog(dateString: key, totalSeconds: logManager.todayTotalSeconds, sessionCount: 1, sessions: [])
        syncDayToCalendar(dayLog)
    }
    
    private func syncDayToCalendar(_ dayLog: DayLog) {
        calendarSync.syncDayLogToCalendar(dayLog: dayLog) { success, message in
            showToast(message)
        }
    }
    
    private func openEditor(for dateKey: String) {
        editingDateKey = dateKey
    }
    
    private func showToast(_ text: String) {
        syncStatusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            syncStatusMessage = nil
        }
    }
}

struct IdentifiableDate: Identifiable {
    var id: String { dateKey }
    let dateKey: String
}

// 稼働時間編集シート
struct EditDurationSheet: View {
    let dateKey: String
    var onDismiss: () -> Void
    
    @State private var inputMinutes: String = ""
    @ObservedObject var logManager = ActivityLogManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("稼働時間の修正: \(dateKey)")
                    .font(.headline)
                Spacer()
                Button("閉じる") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            Text("止め忘れや手動調整したい分数を直接入力してください：")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                TextField("分数", text: $inputMinutes)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .frame(width: 100)
                Text("分 に修正する")
                    .font(.system(size: 13, weight: .medium))
            }
            
            // クイック微調整ボタン
            HStack(spacing: 6) {
                Text("微調整:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                ForEach([-30, -15, -5, 5, 15, 30], id: \.self) { delta in
                    Button(delta > 0 ? "+\(delta)分" : "\(delta)分") {
                        adjustMinutes(by: delta)
                    }
                    .font(.system(size: 10))
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("キャンセル") {
                    onDismiss()
                }
                Button("保存する") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380, height: 230)
        .onAppear {
            let currentSecs = logManager.dailyLogs[dateKey]?.totalSeconds ?? 0
            let currentMins = Int(round(currentSecs / 60.0))
            inputMinutes = "\(currentMins)"
        }
    }
    
    private func adjustMinutes(by delta: Int) {
        let current = Int(inputMinutes) ?? 0
        let updated = max(0, current + delta)
        inputMinutes = "\(updated)"
    }
    
    private func saveChanges() {
        if let mins = Double(inputMinutes) {
            logManager.updateDayTotal(dateKey: dateKey, newTotalSeconds: mins * 60.0)
        }
        onDismiss()
    }
}
