# Design

Current managers use native `NSWindow.close()` for the title-bar cross but `orderOut()` followed by dropping ownership for header Close/Escape. Unify dismissal with native close while retaining the window for reuse. This avoids repeatedly creating hosting controllers and unowned hidden windows. Use 480×620 for settings and 520×560 for stats to match existing roots. Retain the application delegate explicitly across the AppKit run loop, whose delegate property is weak.

Lazyweb research: https://www.lazyweb.com/agentic-search/6ce00b30-ef30-44cf-b126-df680c540029 (language settings modal). Keep the existing picker and explicit close affordances; the change repairs native lifecycle, without visual redesign.

Tests initialize AppKit and isolate UserDefaults from the installed application. Assert identity, visibility, populated content, title updates and bounded window counts across both close paths. No timer sessions or calendar writes are performed.

UI follow-up: Extract existing controls into four sections selected by a localized segmented picker. Keep the header outside the ScrollView. Calendar controls move out of the Dock/menu bar group; notification controls move alongside timer controls. Preserve bindings and existing behavior.

Installed UI testing reproduced an additional issue: the first category edit opened an empty Add sheet. Replace separate Boolean/data sheet state with an identifiable presentation payload; use sheet(item:) for atomic presentation in SettingsSheet and DigitalDisplay.

Add a localized plus button above the category list. Reuse the same CategoryEditorRequest(nil) sheet as the timer menu, preserving validation and persistence.
