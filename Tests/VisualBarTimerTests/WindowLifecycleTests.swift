import AppKit
import SwiftUI
import XCTest
@testable import VisualBarTimer

final class WindowLifecycleTests: XCTestCase {
    func testHideAndRestoreMainWindowKeepsTheSameContent() async throws {
        try await MainActor.run {
            let settings = prepare()
            let controller = MainWindowController.shared
            settings.startHidden = false
            settings.showInMenuBar = false
            controller.setupAndShow()
            let window = try XCTUnwrap(controller.window)
            defer { controller.hide() }
            for _ in 0..<10 {
                controller.hide()
                XCTAssertFalse(window.isVisible)
                controller.show()
                XCTAssertTrue(window.isVisible)
                XCTAssertTrue(controller.window === window)
                XCTAssertTrue(window.contentViewController is NSHostingController<MainTimerView>)
            }
        }
    }

    @MainActor
    private func prepare() -> TimerSettings {
        _ = NSApplication.shared
        // XCTest has its own defaults domain; do not enable calendar writes.
        UserDefaults.standard.set(false, forKey: "saved_auto_calendar_sync")
        UserDefaults.standard.set(false, forKey: "saved_auto_weekly_summary")
        let settings = MainWindowController.shared.settings
        settings.language = .english
        return settings
    }

    func testSettingsReusesWindowAfterBothCloseActions() async throws {
        try await MainActor.run {
            let settings = prepare()
            let manager = SettingsWindowManager.shared
            manager.show(engine: MainWindowController.shared.engine, settings: settings)
            let first = try XCTUnwrap(NSApp.windows.first {
                $0.contentViewController is NSHostingController<SettingsSheet>
            })
            defer { manager.close() }
            for _ in 0..<10 {
                manager.close()
                XCTAssertFalse(first.isVisible)
                manager.show(engine: MainWindowController.shared.engine, settings: settings)
                let visible = try XCTUnwrap(NSApp.windows.first {
                    $0.isVisible && $0.contentViewController is NSHostingController<SettingsSheet>
                })
                XCTAssertTrue(visible === first, "Header close must reuse the same owned window")
                visible.performClose(nil)
                XCTAssertFalse(visible.isVisible)
                manager.show(engine: MainWindowController.shared.engine, settings: settings)
                XCTAssertTrue(visible.isVisible)
                XCTAssertNotNil(visible.contentViewController?.view)
            }
            XCTAssertEqual(NSApp.windows.filter {
                $0.contentViewController is NSHostingController<SettingsSheet>
            }.count, 1)
        }
    }

    func testStatsReusesWindowAfterBothCloseActions() async throws {
        try await MainActor.run {
            _ = prepare()
            let manager = StatsWindowManager.shared
            manager.show()
            let first = try XCTUnwrap(NSApp.windows.first {
                $0.contentViewController is NSHostingController<StatsWindowView>
            })
            defer { manager.close() }
            for _ in 0..<10 {
                manager.close()
                XCTAssertFalse(first.isVisible)
                manager.show()
                let visible = try XCTUnwrap(NSApp.windows.first {
                    $0.isVisible && $0.contentViewController is NSHostingController<StatsWindowView>
                })
                XCTAssertTrue(visible === first, "Header close must reuse the same owned window")
                visible.performClose(nil)
                XCTAssertFalse(visible.isVisible)
                manager.show()
                XCTAssertTrue(visible.isVisible)
                XCTAssertNotNil(visible.contentViewController?.view)
            }
            XCTAssertEqual(NSApp.windows.filter {
                $0.contentViewController is NSHostingController<StatsWindowView>
            }.count, 1)
        }
    }

    func testLanguageUpdatesOpenAndClosedWindowTitles() async throws {
        try await MainActor.run {
            let settings = prepare()
            let manager = SettingsWindowManager.shared
            manager.show(engine: MainWindowController.shared.engine, settings: settings)
            StatsWindowManager.shared.show()
            let settingsWindow = try XCTUnwrap(NSApp.windows.first {
                $0.isVisible && $0.contentViewController is NSHostingController<SettingsSheet>
            })
            let statsWindow = try XCTUnwrap(NSApp.windows.first {
                $0.isVisible && $0.contentViewController is NSHostingController<StatsWindowView>
            })
            defer {
                manager.close()
                StatsWindowManager.shared.close()
            }
            for language in [AppLanguage.japanese, .english, .japanese] {
                settings.language = language
                XCTAssertEqual(settingsWindow.title, settings.l10n.settingsTitle)
                XCTAssertEqual(statsWindow.title, settings.l10n.statsWindowTitle)
            }
            manager.close()
            StatsWindowManager.shared.close()
            settings.language = .english
            manager.show(engine: MainWindowController.shared.engine, settings: settings)
            StatsWindowManager.shared.show()
            XCTAssertTrue(settingsWindow.isVisible)
            XCTAssertTrue(statsWindow.isVisible)
            XCTAssertEqual(settingsWindow.title, settings.l10n.settingsTitle)
            XCTAssertEqual(statsWindow.title, settings.l10n.statsWindowTitle)
        }
    }
}
