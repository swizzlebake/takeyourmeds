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

Take Your Meds is a Flutter app for scheduling medication dose reminders and tracking active doses. State is managed with **flutter_riverpod** — `AsyncNotifierProvider` for the three data collections, a `NotifierProvider` for theme mode, and a `StreamProvider<DateTime>` for the 1-second UI tick.

### Three-tier data model

1. **`Meds`** — base medication: name, dosage unit (`MedsDoseRange`: ug/mg/g), duration the medication lasts
2. **`DosePreset`** — links a `Meds` with a specific dosage amount for quick selection
3. **`ActiveMeds`** — a `DosePreset` dose that was taken, with `takenAt` (UTC), `remindAt`, and `remindAgainAt` timestamps

### File structure

```
lib/
  models/
    meds.dart                 — Meds, MedsDoseRange
    dose_preset.dart          — DosePreset
    active_meds.dart          — ActiveMeds, TakeMeds, TakeMedsTimerResolution, TakeMedsAction
  providers.dart              — all Riverpod providers (theme, tick, meds, doses, activeMeds)
  db.dart                     — Hive database layer
  notifications.dart          — alarm & notification scheduling
  time.dart                   — getRemindAt / getRemindAgainAt helpers
  settings.dart               — Setting<T> typed wrappers (cancelWarningWithConsumePercentage, remindAgainAtFrequencyInMins)
  main.dart                   — app entry point, ProviderScope, MyApp (ConsumerWidget)
  home.dart                   — Home screen, ActiveMedsWidget, theme toggle helpers
  meds_overview.dart          — MedsOverview, MedsCard, CreateMedsWidget
  dose_presets_overview.dart  — DosePresetsOverview, DoseCard, CreateDosePresetWidget
  consume.dart                — Consume dialog (take / resolve a dose)
  navigation.dart             — TYMNavigation bottom bar
  hive/                       — auto-generated Hive adapters (do not edit .g.dart files)
```

### Key modules

**`lib/providers.dart`** — central Riverpod hub. `medsProvider`, `dosesProvider`, `activeMedsProvider` are `AsyncNotifierProvider`s whose notifiers call `Database.save*()` and update state. `themeModeProvider` is a sync `NotifierProvider` pre-seeded from `Database.cachedThemeMode`. `tickProvider` is a `StreamProvider<DateTime>` emitting every second (replaces the old manual timer callback).

**`lib/db.dart`** — Hive CE database with four boxes: `meds`, `dose`, `timers`, `settings`. Caches (`cachedMeds`, `cachedDoses`, `cachedActiveMeds`, `cachedThemeMode`) are loaded once in `init()`. All multi-step writes use `boxCollection.transaction()`. `ThemeMode` is persisted as its int index in the `settings` box.

**`lib/notifications.dart`** — Schedules alarms. Uses the `alarm` package for device alarm sounds on Android; falls back to `flutter_local_notifications`. Timezone detection is platform-specific: Android uses `FlutterTimezone`, Linux reads `/etc/timezone`. `Notifications.location` (static) is used by `ActiveMeds.getLabel()` and `Home`.

**`lib/home.dart`** — `ConsumerWidget`. Watches `dosesProvider`, `activeMedsProvider`, `tickProvider`, and `themeModeProvider`. Theme cycles system → light → dark via an AppBar icon button. `ActiveMedsWidget` (also in this file) color-codes urgency white → yellow via `HSVColor.lerp()` in a 30-second window after `remindAt`.

**`lib/consume.dart`** — `ConsumerStatefulWidget` dialog. Reads `dosesProvider` and `activeMedsProvider` in `initState()` (not `build()`) to avoid resetting the user's dropdown selections on each rebuild. Exposes date/time pickers so `takenAt` can be set retroactively; `takenAt` is passed into `ActiveMeds.fromDose()`.

### Notification/alarm flow

1. User records a dose → `ActiveMeds.fromDose(dose, takenAt)` created
2. `remindAt = takenAt + meds.duration` (truncated to the minute)
3. `remindAgainAt = remindAt + Settings.remindAgainAtFrequencyInMins`
4. `Notifications.scheduleAlarm(activeMeds)` sets the device alarm for `remindAt`

### Initialization order (in `main.dart`)

`Database.init()` → `Notifications.init()` — both awaited before `runApp(ProviderScope(...))`. `Time.init()` is no longer called (the tick is handled by `tickProvider`).

### Time handling

All timestamps stored as UTC. Displayed times converted to local timezone via `TZDateTime.from(dt, Notifications.location)` from the `timezone` package.

### Hive adapters

`lib/hive/hive_adapters.dart` declares `@GenerateAdapters` for `Meds`, `DosePreset`, `MedsDoseRange`, and `ActiveMeds`. After moving or modifying any of these classes, re-run `build_runner` to regenerate `hive_adapters.g.dart` and `hive_registrar.g.dart`.
