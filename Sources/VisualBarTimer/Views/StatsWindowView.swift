import SwiftUI
import AppKit
import EventKit

struct StatsWindowView: View {
    @ObservedObject var logManager = ActivityLogManager.shared
    @ObservedObject var calendarSync = CalendarSyncManager.shared
    @ObservedObject var settings = MainWindowController.shared.settings
    var onClose: (() -> Void)? = nil
    
    @State private var copiedMessage: String? = nil
    @State private var editingDateKey: String? = nil
    @State private var syncStatusMessage: String? = nil
    @State private var deleteTargetDate: String? = nil
    @State private var showDeleteDayConfirm: Bool = false
    @State private var showClearAllConfirm: Bool = false
    
    var body: some View {
        let l10n = settings.l10n
        let lang = settings.language

        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.statsHeaderTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.statsHeaderSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(l10n.close) {
                    onClose?()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            // 今日のサマリーカード
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(l10n.todayTotalFocus)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            openEditor(for: logManager.todayKey)
                        }) {
                            Label(l10n.editTimeButton, systemImage: "pencil")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(logManager.todayFormatted(for: lang))
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.sessionCount)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(l10n.sessionCountDisplay(logManager.dailyLogs[logManager.todayKey]?.sessionCount ?? 0))
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
                        Text(l10n.calendarBannerTitle)
                            .font(.system(size: 12, weight: .bold))
                        Text(l10n.calendarBannerSubtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Button(action: {
                            calendarSync.syncPreviousWeekSummaryIfNeeded(force: true) { success, msg in
                                showToast(msg)
                            }
                        }) {
                            Label(l10n.weeklySummaryRegisterButton, systemImage: "chart.bar.doc.horizontal")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help(l10n.weeklySummaryHelp)
                        
                        Button(action: {
                            syncTodayToCalendar()
                        }) {
                            Label(l10n.recordTodayButton, systemImage: "plus.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.85))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if !calendarSync.availableCalendars.isEmpty {
                    HStack(spacing: 6) {
                        Text(l10n.calendarTargetLabel)
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
                    Text(l10n.dailyHistoryHeader)
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
                                Text(l10n.clearAllHistoryButton)
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help(l10n.clearAllHistoryHelp)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 6) {
                        let sortedDays = logManager.dailyLogs.values.sorted(by: { $0.dateString > $1.dateString })
                        if sortedDays.isEmpty {
                            Text(l10n.noLogsMessage)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(sortedDays) { day in
                                HStack {
                                    Text(day.dateString)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    if day.dateString == logManager.todayKey {
                                        Text(l10n.today)
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                    Spacer()
                                    Text("\(day.sessionCount) \(l10n.timesUnit)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text(day.formattedDuration(for: lang))
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
                                    .help(l10n.syncDayToCalendarHelp)
                                    
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
                                    .help(l10n.editDayLogHelp)
                                    
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
                                    .help(l10n.deleteDayLogHelp(date: day.dateString))
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
                Text(l10n.fileExportHeader)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    // CSV保存
                    Button(action: {
                        logManager.saveCSVToFile()
                    }) {
                        Label(l10n.exportCSVButton, systemImage: "arrow.down.doc.fill")
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
                        Label(l10n.exportJSONButton, systemImage: "curlybraces")
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
                        showToast(l10n.csvCopiedToast)
                    }) {
                        Label(l10n.copyCSVButton, systemImage: "doc.on.doc")
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
                        Label(l10n.openFolderButton, systemImage: "folder")
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
            EditDurationSheet(dateKey: item.dateKey, language: lang) {
                editingDateKey = nil
            }
        }
        .alert(l10n.deleteDayAlertTitle, isPresented: $showDeleteDayConfirm) {
            Button(l10n.delete, role: .destructive) {
                if let target = deleteTargetDate {
                    logManager.deleteHistory(for: target)
                    showToast("\(target) deleted")
                }
                deleteTargetDate = nil
            }
            Button(l10n.cancel, role: .cancel) {
                deleteTargetDate = nil
            }
        } message: {
            if let target = deleteTargetDate {
                Text(l10n.deleteDayAlertMessage(date: target))
            }
        }
        .alert(l10n.clearAllAlertTitle, isPresented: $showClearAllConfirm) {
            Button(l10n.clearAllConfirmButton, role: .destructive) {
                logManager.clearAllHistory()
                showToast("All history cleared")
            }
            Button(l10n.cancel, role: .cancel) {}
        } message: {
            Text(l10n.clearAllAlertMessage)
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
    var language: AppLanguage = .english
    var onDismiss: () -> Void
    
    @State private var inputMinutes: String = ""
    @ObservedObject var logManager = ActivityLogManager.shared
    
    var body: some View {
        let l10n = L10n(language: language)

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(l10n.editDurationTitle(date: dateKey))
                    .font(.headline)
                Spacer()
                Button(l10n.close) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            Text(l10n.editDurationSubtitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                TextField(l10n.minUnit, text: $inputMinutes)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .frame(width: 100)
                Text(l10n.editDurationUnit)
                    .font(.system(size: 13, weight: .medium))
            }
            
            // クイック微調整ボタン
            HStack(spacing: 6) {
                Text(l10n.fineTuneLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                ForEach([-30, -15, -5, 5, 15, 30], id: \.self) { delta in
                    Button(delta > 0 ? "+\(delta)\(l10n.minUnit)" : "\(delta)\(l10n.minUnit)") {
                        adjustMinutes(by: delta)
                    }
                    .font(.system(size: 10))
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(l10n.cancel) {
                    onDismiss()
                }
                Button(l10n.save) {
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
