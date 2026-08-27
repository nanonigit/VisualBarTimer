import SwiftUI

struct DigitalDisplay: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    @ObservedObject var categoryManager = CategoryManager.shared
    
    @State private var isEditing: Bool = false
    @State private var inputMinutes: String = ""
    @State private var showAddCategoryDialog: Bool = false
    @State private var newCategoryIcon: String = "🏷️"
    @State private var newCategoryName: String = ""
    
    var timeString: String {
        let total = (engine.currentMode == .countup) ? engine.elapsedTime : engine.remainingTime
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var modeBadgeText: String {
        switch engine.currentMode {
        case .countdown:
            return "COUNTDOWN"
        case .countup:
            return "COUNTUP"
        case .pomodoro:
            return engine.pomodoroPhase == .work ? "POMO・FOCUS" : "POMO・BREAK"
        }
    }
    
    var badgeColor: Color {
        switch engine.currentMode {
        case .countdown:
            return .cyan
        case .countup:
            return .orange
        case .pomodoro:
            return engine.pomodoroPhase == .work ? .red : .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                // モードバッジ
                Text(modeBadgeText)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())
                
                // 作業カテゴリ選択メニュー
                Menu {
                    ForEach(categoryManager.visibleCategories) { cat in
                        Button(action: {
                            categoryManager.selectCategory(cat)
                        }) {
                            if cat.id == categoryManager.selectedCategoryId {
                                Label(cat.title, systemImage: "checkmark")
                            } else {
                                Text(cat.title)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showAddCategoryDialog = true
                    }) {
                        Label("新しいカテゴリを追加...", systemImage: "plus")
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(categoryManager.currentCategory.title)
                            .font(.system(size: 9, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("作業カテゴリを切り替え (カレンダーの予定名に反映されます)")
                
                // 本日の累計稼働時間
                Button(action: {
                    StatsWindowManager.shared.show()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 8))
                        Text("今日: \(ActivityLogManager.shared.todayFormattedM)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("クリックして本日の統計・履歴ログ・カレンダー同期を開く")
            }
            
            if isEditing {
                HStack(spacing: 4) {
                    TextField("分", text: $inputMinutes)
                        .textFieldStyle(.plain)
                        .font(.system(size: textSize, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .padding(.horizontal, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .onSubmit {
                            submitCustomTime()
                        }
                    
                    Text("分")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Button("決定") {
                        submitCustomTime()
                    }
                    .font(.system(size: 10, weight: .bold))
                    .buttonStyle(.borderedProminent)
                    
                    Button("✕") {
                        isEditing = false
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.plain)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(timeString)
                        .font(.system(size: textSize, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            inputMinutes = "\(Int(round(engine.targetDuration / 60.0)))"
                            isEditing = true
                        }
                        .help("クリックして分数を直接キーボード入力")
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            inputMinutes = "\(Int(round(engine.targetDuration / 60.0)))"
                            isEditing = true
                        }
                }
            }
        }
        .sheet(isPresented: $showAddCategoryDialog) {
            AddCategorySheet {
                showAddCategoryDialog = false
            }
        }
    }
    
    private var textSize: CGFloat {
        switch settings.size {
        case .extraSmall:
            return 17
        case .small:
            return 22
        case .medium:
            return 28
        case .large:
            return 36
        }
    }
    
    private func submitCustomTime() {
        if let mins = Double(inputMinutes), mins > 0 {
            engine.setDuration(mins * 60.0)
        }
        isEditing = false
    }
}

// 新規カスタムカテゴリ追加シート
struct AddCategorySheet: View {
    var onDismiss: () -> Void
    
    @State private var selectedEmoji: String = "🎯"
    @State private var categoryName: String = ""
    @ObservedObject var categoryManager = CategoryManager.shared
    
    let emojiCandidates = ["🎯", "🇬🇧", "📊", "✍️", "🏋️", "☕", "🔬", "🗣️", "🛠️", "📚", "🎮", "🧘"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("新規カテゴリの追加")
                    .font(.headline)
                Spacer()
                Button("閉じる") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            Text("アイコン絵文字を選択:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            HStack(spacing: 6) {
                ForEach(emojiCandidates, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                    }) {
                        Text(emoji)
                            .font(.system(size: 16))
                            .padding(6)
                            .background(selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("カテゴリ名:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("例: 英語学習、確定申告、ブログ", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("キャンセル") {
                    onDismiss()
                }
                Button("追加する") {
                    categoryManager.addCustomCategory(icon: selectedEmoji, name: categoryName)
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360, height: 230)
    }
}
