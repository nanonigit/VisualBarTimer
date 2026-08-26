import SwiftUI
import AppKit

struct StatsWindowView: View {
    @ObservedObject var logManager = ActivityLogManager.shared
    var onClose: (() -> Void)? = nil
    @State private var copiedMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("タイマー稼働ログ・統計")
                        .font(.system(size: 16, weight: .bold))
                    Text("日々の集中・タイマー稼働時間を記録・書き出し")
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
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本日の総タイマー稼働")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(logManager.todayFormattedDuration)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
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
            
            // 日別履歴リスト
            VStack(alignment: .leading, spacing: 8) {
                Text("日別履歴 (最近の日付)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
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
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
            
            Divider()
            
            // エクスポート & 連携アクション
            VStack(alignment: .leading, spacing: 10) {
                Text("エクスポート & 外部ソリューション連携")
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
                    .help("Obsidianやスクリプト等で直接連携できるJSONファイルの場所を開きます")
                }
                
                if let msg = copiedMessage {
                    Text(msg)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(20)
        .frame(width: 480, height: 490)
    }
    
    private func showToast(_ text: String) {
        copiedMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedMessage = nil
        }
    }
}

final class StatsWindowManager {
    static let shared = StatsWindowManager()
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = StatsWindowView { [weak self] in
            self?.close()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 490),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "タイマー稼働統計・ログエクスポート"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.level = .floating
        newWindow.isMovableByWindowBackground = true
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.orderOut(nil)
        window = nil
    }
}
