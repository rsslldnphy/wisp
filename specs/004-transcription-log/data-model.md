# Data Model: Transcription Log

**Feature**: 004-transcription-log
**Date**: 2026-03-28

## Entities

### TranscriptionLogEntry

Represents a single completed transcription event.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | UUID | unique, non-nil | Stable identifier; generated at creation |
| `text` | String | non-empty | Final cleaned transcription text delivered to user |
| `timestamp` | Date | non-nil | Wall-clock time when transcription completed |

**Serialisation**: `Codable` (JSON). Stored as an array of entry objects in a single file.

**Identity rule**: Each entry is independently identified by UUID. Duplicate text values with different timestamps are distinct entries (same phrase dictated twice = two separate entries).

### TranscriptionLogStore

Manages the in-memory and on-disk state of the log.

| Concern | Behaviour |
|---------|-----------|
| Capacity cap | Maximum 500 entries; when the cap is exceeded, the oldest entry (lowest `timestamp`) is removed before adding the new one |
| Ordering | Entries stored internally in insertion order; sorted descending by `timestamp` on read for display |
| Persistence path | `~/Library/Application Support/Wisp/transcription-log.json` |
| Write strategy | Full array rewrite after each `append(_:)` call; no incremental append to avoid corruption risk |
| Corrupt/missing file | Silently initialise with empty array; overwrite corrupt file on next write |
| Thread safety | All mutations on `@MainActor` (matching existing AppDelegate patterns) |

## State Transitions

```
(app launch)
     │
     ▼
TranscriptionLogStore.load()
  ├─ Success → entries populated from JSON
  └─ Failure (corrupt / missing) → entries = []

(transcription completes)
     │
     ▼
TranscriptionLogStore.append(entry)
  ├─ count ≤ 499 → append, save
  └─ count = 500 → remove oldest, append, save

(user opens log window)
     │
     ▼
LogView reads entries (snapshot at open time)
  ├─ entries.count > 0 → display list, newest first
  └─ entries.count = 0 → display empty state
```

## Persistence Layout

```
~/Library/Application Support/Wisp/
└── transcription-log.json    ← JSON array of TranscriptionLogEntry objects
```

**JSON shape example**:
```json
[
  {
    "id": "A1B2C3D4-...",
    "text": "The quick brown fox",
    "timestamp": 762220800.0
  }
]
```

(`timestamp` stored as `timeIntervalSinceReferenceDate` — standard Swift `Date` Codable behaviour.)
