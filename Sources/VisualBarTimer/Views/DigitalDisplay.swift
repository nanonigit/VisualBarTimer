import SwiftUI

struct DigitalDisplay: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    @ObservedObject var categoryManager = CategoryManager.shared
    
    @State private var isEditing: Bool = false
    @State private var inputMinutes: String = ""
    @FocusState private var isFieldFocused: Bool
    @State private var categoryEditor: CategoryEditorRequest? = nil
    
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
        let l10n = settings.l10n
        let lang = settings.language

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
                                Label(cat.localizedTitle(for: lang), systemImage: "checkmark")
                            } else {
                                Text(cat.localizedTitle(for: lang))
                            }
                        }
                    }
                    
                    Divider()
                    
                    if !categoryManager.currentCategory.isPreset {
                        Button(action: {
                            categoryEditor = CategoryEditorRequest(category: categoryManager.currentCategory)
                        }) {
                            Label(l10n.editCategoryButton(name: categoryManager.currentCategory.name), systemImage: "pencil")
                        }
                    }
                    
                    Button(action: {
                        categoryEditor = CategoryEditorRequest(category: nil)
                    }) {
                        Label(l10n.addNewCategoryButton, systemImage: "plus")
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(categoryManager.currentCategory.localizedTitle(for: lang))
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
                .help(l10n.switchCategoryHelp)
                
                // 本日の累計稼働時間
                Button(action: {
                    StatsWindowManager.shared.show()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 8))
                        Text("\(l10n.today): \(ActivityLogManager.shared.todayFormatted(for: lang))")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help(l10n.openStatsHelp)
            }
            
            if isEditing {
                // コンパクトなインライン編集バー（極小Miniモードでも絶対に溢れないスリム設計）
                HStack(spacing: 3) {
                    TextField(l10n.quickMinPlaceholder, text: $inputMinutes)
                        .textFieldStyle(.plain)
                        .font(.system(size: max(14, textSize - 2), weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 50)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .focused($isFieldFocused)
                        .onSubmit {
                            submitCustomTime()
                        }
                    
                    Text(l10n.minUnit)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    // 決定ボタン
                    Button(action: {
                        submitCustomTime()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.black)
                            .padding(4)
                            .background(Color.cyan)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(l10n.confirmReturnHelp)
                    
                    // キャンセルボタン
                    Button(action: {
                        isEditing = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(4)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(l10n.cancel)
                }
                .padding(.top, 1)
                .onAppear {
                    isFieldFocused = true
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(timeString)
                        .font(.system(size: textSize, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startEditing()
                        }
                        .help(l10n.editDurationHelp)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startEditing()
                        }
                }
            }
        }
        .sheet(item: $categoryEditor) { request in
            CategoryEditSheet(categoryToEdit: request.category, language: settings.language) {
                categoryEditor = nil
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
    
    private func startEditing() {
        let currentMins = Int(round(engine.targetDuration / 60.0))
        inputMinutes = "\(currentMins)"
        isEditing = true
        NSApp.activate(ignoringOtherApps: true)
        MainWindowController.shared.window?.makeKeyAndOrderFront(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isFieldFocused = true
        }
    }
    
    private func submitCustomTime() {
        if let mins = Double(inputMinutes), mins > 0 {
            engine.setDuration(mins * 60.0)
        }
        isEditing = false
    }
}

// Carry the presentation and its data together so the first sheet render has
// the selected category, rather than capturing a stale nil value.
struct CategoryEditorRequest: Identifiable {
    let id = UUID()
    let category: ActivityCategory?
}

// カスタムカテゴリ追加・編集シート
struct CategoryEditSheet: View {
    var categoryToEdit: ActivityCategory? = nil
    var language: AppLanguage = .english
    var onDismiss: () -> Void
    
    @State private var selectedEmoji: String = "🎯"
    @State private var categoryName: String = ""
    @ObservedObject var categoryManager = CategoryManager.shared
    
    let emojiCandidates = ["🎯", "🇬🇧", "📊", "✍️", "🏋️", "☕", "🔬", "🗣️", "🛠️", "📚", "🎮", "🧘"]
    
    var isEditing: Bool {
        categoryToEdit != nil
    }
    
    var body: some View {
        let l10n = L10n(language: language)

        VStack(alignment: .leading, spacing: 14) {
            // 上部ヘッダー
            HStack {
                Text(isEditing ? l10n.editCategoryTitle : l10n.addCategoryTitle)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(l10n.close) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 4)
            
            Divider()
            
            Text(l10n.selectEmojiPrompt)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(emojiCandidates, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                    }) {
                        Text(emoji)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
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
            
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.categoryNamePrompt)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                TextField(l10n.categoryPlaceholder, text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }
            
            Spacer(minLength: 12)
            
            // 下部アクションバー
            HStack {
                Spacer()
                Button(l10n.cancel) {
                    onDismiss()
                }
                Button(isEditing ? l10n.save : l10n.add) {
                    let trimmed = categoryName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    if let target = categoryToEdit {
                        categoryManager.updateCustomCategory(id: target.id, icon: selectedEmoji, name: trimmed)
                    } else {
                        categoryManager.addCustomCategory(icon: selectedEmoji, name: trimmed)
                    }
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: 370, height: 320)
        .onAppear {
            if let cat = categoryToEdit {
                selectedEmoji = cat.icon.isEmpty ? "🎯" : cat.icon
                categoryName = cat.name
            }
        }
    }
}
