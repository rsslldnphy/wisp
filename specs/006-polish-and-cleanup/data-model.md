# Data Model: Polish and Cleanup

**Branch**: `006-polish-and-cleanup` | **Date**: 2026-03-29

---

## Changed Entities

### PreferencesStore (modified)

Existing model at `Wisp/Models/PreferencesStore.swift`. One new persisted property added:

| Property | Type | Storage Key | Default | Notes |
|----------|------|-------------|---------|-------|
| `launchOnStartup` | `Bool` | `"launchOnStartup"` | `false` | Synced bidirectionally with SMAppService status on app launch |

**State transitions**:

```
launchOnStartup == false
    → user enables toggle
    → SMAppService.mainApp.register() called
    → on success: launchOnStartup = true, menu item state = .on
    → on failure: revert to false, show NSAlert

launchOnStartup == true
    → user disables toggle
    → SMAppService.mainApp.unregister() called
    → on success: launchOnStartup = false, menu item state = .off
    → on failure: retain true, show NSAlert

App launches
    → read SMAppService.mainApp.status
    → if .enabled and stored == false: set stored = true (external enable)
    → if !enabled and stored == true: set stored = false (external disable, e.g. from System Settings)
```

---

## New Assets

### StatusBarIcon (new image asset)

| Property | Value |
|----------|-------|
| Asset name | `StatusBarIcon` |
| Format | PDF or SVG |
| Render mode | Template Image |
| Usage | Idle state icon in `MenuBarController` |
| Dimensions | ~18×18 pt (menu bar standard) |

The ghost design is purely a visual asset — no structured data model.

---

## No New Persistent Entities

The beep timing fix and icon replacement involve no new stored data. The startup preference is the only data model change.
