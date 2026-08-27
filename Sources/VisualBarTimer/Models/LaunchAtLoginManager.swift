import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool = false
    
    private init() {
        checkStatus()
    }
    
    func checkStatus() {
        if #available(macOS 13.0, *) {
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }
                    try SMAppService.mainApp.register()
                    self.isEnabled = true
                } else {
                    try SMAppService.mainApp.unregister()
                    self.isEnabled = false
                }
            } catch {
                print("Failed to update LaunchAtLogin: \(error)")
                checkStatus()
            }
        }
    }
}
