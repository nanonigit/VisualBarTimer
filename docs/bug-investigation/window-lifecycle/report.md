# Investigation and prevention

## Evidence
- User report: intermittent blank/black windows after settings/management and × actions following bilingual work.
- Before repair: three regression tests produced 26 assertion failures. After ten header-close/reopen cycles, NSApp retained 11 settings windows and 11 statistics windows rather than one each.
- After repair and tab organization: four XCTest tests passed with zero failures. Ten iterations cover header/native dismissal for each secondary window, main hide/restore, and live/closed title updates in both languages.
- The exact intermittent blank/black appearance was not captured before repair. The accumulating-window defect is reproducible and independently established; do not claim every possible rendering issue has been proven eliminated.

## Timeline
1. Existing uncommitted Antigravity changes preserved in a source archive and patch.
2. Existing English/Japanese UI and both dismissal paths inspected.
3. Regression tests reproduced unowned hidden windows.
4. Native close/reuse fixed, roots/window sizes aligned, delegate lifetime retained.
5. Settings reorganized into four tabs with a persistent header.
6. Tests passed; installed-app verification recorded below.

## 5 Whys
1. Why can stale UI remain? Secondary windows survive a header dismissal.
2. Why do they survive? orderOut hides but does not close the native window.
3. Why are they no longer controlled? Managers immediately set their window reference to nil.
4. Why are new windows created? show treats nil as no existing window while AppKit retains the old one.
5. Why was this missed? No repeated open/close test bounded NSApp's window count; header and native close used different paths.

## Fishbone
- Lifecycle: hide versus close; ownership dropped while AppKit retained windows.
- UI: header Close inside long scroll content; mixed calendar/system controls.
- Localization: increases view updates, but original close code already had the ownership defect before localization. Temporal association alone does not prove localization introduced it.
- Initialization: weak NSApplication delegate lifetime; UserNotifications raises an exception in unbundled test hosts (guard both request and delivery).
- Verification: previous package had no test target or close/reopen regression suite.

## Repair and prevention
Use native close for both secondary-manager dismissals while retaining one reusable window. Preserve all existing localization/data bindings. Keep four-tab settings and persistent Close. Require `swift test` plus installed bilingual close/reopen checks for subsequent UI changes. Review completed; the notification-delivery guard was added following review.

## Additional runtime finding: category editor
Clicking the first custom category pencil reproduced an empty “Add New Category” sheet rather than “Edit Category” with the existing name. Both SettingsSheet and DigitalDisplay used an independent Boolean plus optional category. A Boolean-driven sheet closure could capture the old nil payload. Replaced them with one identifiable CategoryEditorRequest and sheet(item:), providing the selected category in the presentation closure. Each presentation has a fresh UUID. Code review passed without remaining findings; final tests again passed (4/4).

5 Whys: wrong editor mode → nil category → stale first sheet payload → presentation Boolean independent of data → no first-open populated-editor verification. Prevention: verify first Edit, cancel/reopen, and Edit then Add without saving test data.

## Installed-app checks
- Four settings tabs inspected in English and Japanese; App-tab scrolling leaves the header/Close visible.
- Japanese statistics: native × → settings, reopen → populated stats, header Close → settings, all verified.
- Settings native × → populated timer verified.
- Category edit first-open: the first custom category prefilled with its saved icon/name; cancel then the second custom category edit prefilled correctly. Timer-menu Add opens empty Add mode.
- User follow-up: added a localized Add New Category button directly above the management category list.
- Final scoped code review: no remaining findings. Final XCTest: 4 tests, 0 failures.
- Activity log checksum is identical to the pre-install backup; no test categories or calendar events were saved.

Final install verified: /Applications/VisualBarTimer.app binary SHA-256 matches the release build. Management Categories → Add New Category opens an empty localized creation sheet; left open for the user.
