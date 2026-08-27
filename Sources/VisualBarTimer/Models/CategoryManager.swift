import Foundation
import SwiftUI

struct ActivityCategory: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var icon: String
    var name: String
    var isPreset: Bool = false
    
    var title: String {
        if icon.isEmpty {
            return name
        }
        return "\(icon) \(name)"
    }
}

@MainActor
final class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    static let defaultPresets: [ActivityCategory] = [
        ActivityCategory(icon: "💼", name: "仕事", isPreset: true),
        ActivityCategory(icon: "✏️", name: "勉強", isPreset: true),
        ActivityCategory(icon: "💻", name: "開発", isPreset: true),
        ActivityCategory(icon: "📖", name: "読書", isPreset: true),
        ActivityCategory(icon: "🎨", name: "創作", isPreset: true),
        ActivityCategory(icon: "🧘", name: "休憩", isPreset: true),
        ActivityCategory(icon: "⏱️", name: "集中作業", isPreset: true),
    ]
    
    @Published var customCategories: [ActivityCategory] = [] {
        didSet {
            saveCustomCategories()
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
    
    var currentCategory: ActivityCategory {
        if let found = allCategories.first(where: { $0.id.uuidString == selectedCategoryId || $0.title == selectedCategoryId }) {
            return found
        }
        return Self.defaultPresets[0] // 💼 仕事
    }
    
    private init() {
        loadCustomCategories()
        if let savedId = UserDefaults.standard.string(forKey: "saved_selected_category_id") {
            self.selectedCategoryId = savedId
        } else {
            self.selectedCategoryId = Self.defaultPresets[0].id.uuidString
        }
    }
    
    func selectCategory(_ category: ActivityCategory) {
        self.selectedCategoryId = category.id.uuidString
    }
    
    func addCustomCategory(icon: String, name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newCat = ActivityCategory(icon: icon.isEmpty ? "🏷️" : icon, name: name.trimmingCharacters(in: .whitespaces), isPreset: false)
        customCategories.append(newCat)
        selectCategory(newCat)
    }
    
    func deleteCustomCategory(id: UUID) {
        customCategories.removeAll(where: { $0.id == id })
        if selectedCategoryId == id.uuidString {
            selectCategory(Self.defaultPresets[0])
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
