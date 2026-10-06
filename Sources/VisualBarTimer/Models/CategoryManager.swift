import Foundation
import SwiftUI

struct ActivityCategory: Codable, Identifiable, Hashable {
    var id: String // "preset_work" などの固定キーまたは UUID文字列
    var icon: String
    var name: String
    var isPreset: Bool = false
    
    var title: String {
        if icon.isEmpty {
            return name
        }
        return "\(icon) \(name)"
    }

    func localizedName(for lang: AppLanguage) -> String {
        if isPreset {
            switch (id, lang) {
            case ("preset_work", .english): return "Work"
            case ("preset_work", .japanese): return "仕事"
            case ("preset_study", .english): return "Study"
            case ("preset_study", .japanese): return "勉強"
            case ("preset_dev", .english): return "Development"
            case ("preset_dev", .japanese): return "開発"
            case ("preset_reading", .english): return "Reading"
            case ("preset_reading", .japanese): return "読書"
            case ("preset_creative", .english): return "Creative"
            case ("preset_creative", .japanese): return "創作"
            case ("preset_break", .english): return "Break"
            case ("preset_break", .japanese): return "休憩"
            case ("preset_focus", .english): return "Deep Work"
            case ("preset_focus", .japanese): return "集中作業"
            default: return name
            }
        }
        return name
    }

    func localizedTitle(for lang: AppLanguage) -> String {
        let n = localizedName(for: lang)
        if icon.isEmpty {
            return n
        }
        return "\(icon) \(n)"
    }
}

@MainActor
final class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    static let defaultPresets: [ActivityCategory] = [
        ActivityCategory(id: "preset_work", icon: "💼", name: "仕事", isPreset: true),
        ActivityCategory(id: "preset_study", icon: "✏️", name: "勉強", isPreset: true),
        ActivityCategory(id: "preset_dev", icon: "💻", name: "開発", isPreset: true),
        ActivityCategory(id: "preset_reading", icon: "📖", name: "読書", isPreset: true),
        ActivityCategory(id: "preset_creative", icon: "🎨", name: "創作", isPreset: true),
        ActivityCategory(id: "preset_break", icon: "🧘", name: "休憩", isPreset: true),
        ActivityCategory(id: "preset_focus", icon: "⏱️", name: "集中作業", isPreset: true),
    ]
    
    @Published var customCategories: [ActivityCategory] = [] {
        didSet {
            saveCustomCategories()
        }
    }
    
    @Published var hiddenCategoryIds: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(hiddenCategoryIds), forKey: "saved_hidden_category_ids")
        }
    }
    
    @Published var selectedCategoryId: String = "" {
        didSet {
            UserDefaults.standard.set(selectedCategoryId, forKey: "saved_selected_category_id")
        }
    }
    
    var allCategories: [ActivityCategory] {
        return Self.defaultPresets + customCategories
    }
    
    var visibleCategories: [ActivityCategory] {
        return allCategories.filter { !hiddenCategoryIds.contains($0.id) }
    }
    
    var currentCategory: ActivityCategory {
        if let found = allCategories.first(where: { $0.id == selectedCategoryId || $0.title == selectedCategoryId }) {
            return found
        }
        return visibleCategories.first ?? Self.defaultPresets[0]
    }
    
    private init() {
        loadCustomCategories()
        if let hiddenArray = UserDefaults.standard.stringArray(forKey: "saved_hidden_category_ids") {
            self.hiddenCategoryIds = Set(hiddenArray)
        }
        
        if let savedId = UserDefaults.standard.string(forKey: "saved_selected_category_id") {
            self.selectedCategoryId = savedId
        } else {
            self.selectedCategoryId = Self.defaultPresets[0].id
        }
    }
    
    func isHidden(_ category: ActivityCategory) -> Bool {
        return hiddenCategoryIds.contains(category.id)
    }
    
    func toggleVisibility(for category: ActivityCategory) {
        if hiddenCategoryIds.contains(category.id) {
            hiddenCategoryIds.remove(category.id)
        } else {
            // 全て非表示にされるのを防止
            if visibleCategories.count > 1 {
                hiddenCategoryIds.insert(category.id)
                if selectedCategoryId == category.id, let firstVisible = visibleCategories.first {
                    selectCategory(firstVisible)
                }
            }
        }
    }
    
    func selectCategory(_ category: ActivityCategory) {
        self.selectedCategoryId = category.id
    }
    
    func addCustomCategory(icon: String, name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newCat = ActivityCategory(
            id: UUID().uuidString,
            icon: icon.isEmpty ? "🏷️" : icon,
            name: name.trimmingCharacters(in: .whitespaces),
            isPreset: false
        )
        customCategories.append(newCat)
        selectCategory(newCat)
    }
    
    func updateCustomCategory(id: String, icon: String, name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if let idx = customCategories.firstIndex(where: { $0.id == id }) {
            customCategories[idx].icon = icon.isEmpty ? "🏷️" : icon
            customCategories[idx].name = name.trimmingCharacters(in: .whitespaces)
        }
    }
    
    func deleteCustomCategory(id: String) {
        customCategories.removeAll(where: { $0.id == id })
        hiddenCategoryIds.remove(id)
        if selectedCategoryId == id {
            selectCategory(visibleCategories.first ?? Self.defaultPresets[0])
        }
    }
    
    private func loadCustomCategories() {
        guard let data = UserDefaults.standard.data(forKey: "saved_custom_categories"),
              let decoded = try? JSONDecoder().decode([ActivityCategory].self, from: data) else {
            return
        }
        self.customCategories = decoded
    }
    
    private func saveCustomCategories() {
        guard let data = try? JSONEncoder().encode(customCategories) else { return }
        UserDefaults.standard.set(data, forKey: "saved_custom_categories")
    }
}
