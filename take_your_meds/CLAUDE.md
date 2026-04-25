# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Regenerate Hive adapters (required after modifying any data model class)
flutter pub run build_runner build --delete-conflicting-outputs

# Lint / analyze
flutter analyze

# Format
dart format lib/ test/

# Run (connected device or emulator)
flutter run

# Run tests
flutter test
```

## Architecture

Take Your Meds is a Flutter app for scheduling medication dose reminders and tracking active doses. No state management library is used — state flows through the widget hierarchy via constructor parameters and callbacks.

### Three-tier data model

1. **`Meds`** — base medication: name, dosage unit (`MedsDoseRange`: ug/mg/g), duration the medication lasts
2. **`DosePreset`** — links a `Meds` with a specific dosage amount for quick selection
3. **`ActiveMeds`** — a `DosePreset` dose that was taken, with `takenAt` (UTC), `remindAt`, and `remindAgainAt` timestamps

### Key modules

**`lib/db.dart`** — Hive CE database layer with three boxes (`meds`, `dose`, `timers`). Maintains in-memory caches (`cachedMeds`, `cachedDoses`, `cachedActiveMeds`) loaded at startup and updated after every write. All multi-step writes use `boxCollection.transaction()`.

**`lib/notifications.dart`** — Schedules alarms and notifications. Uses the `alarm` package for device alarm sounds on Android; falls back to `flutter_local_notifications` for standard notifications. Timezone detection is platform-specific: Android uses `FlutterTimezone`, Linux reads `/etc/timezone`.

**`lib/time.dart`** — Runs a 1-second `Timer.periodic()` that fires registered callbacks. Home widget registers/deregisters its tick callback via `didUpdateWidget()` / `deactivate()` — critical for avoiding memory leaks. Also provides `getRemindAt()` and `getRemindAgainAt()` helpers.

**`lib/settings.dart`** — Typed `Setting<T>` wrappers. Key values: `cancelWarningWithConsumePercentage` (0.5 — after 50% of reminder duration, med appears eligible for retake) and `remindAgainAtFrequencyInMins` (5).

**`lib/home.dart`** — Main screen. Displays dose preset buttons and active medications with real-time color-coded urgency (white → yellow via `HSVColor.lerp()` in a 30-second window). Dose preset tap → Consume dialog (new dose); active med tap → Consume dialog (resolve/extend); long-press "Active Meds" header → clear all.

**`lib/consume.dart`** — Modal dialog for taking a new dose or resolving/extending an active dose. Returns a `TakeMeds` object.

**`lib/hive/hive_adapters.dart`** — Hive adapter generation annotations. `hive_adapters.g.dart` is auto-generated; do not edit it manually.

### Notification/alarm flow

1. User records a dose → `ActiveMeds` created with `takenAt = DateTime.now().toUtc()`
2. `remindAt = takenAt + meds.duration`
3. `remindAgainAt = remindAt + Settings.remindAgainAtFrequencyInMins`
4. `Notifications.scheduleAlarm(activeMeds)` schedules the device alarm for `remindAt`

### Initialization order (in `main.dart`)

`Database.init()` → `Notifications.init()` → `Time.init()` — all awaited before `runApp()`.

### Time handling

All timestamps stored as UTC. Displayed times converted to local timezone via `TZDateTime.from()` from the `timezone` package.
