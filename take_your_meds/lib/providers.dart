import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_your_meds/db.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => Database.cachedThemeMode;

  Future<void> set(ThemeMode mode) async {
    await Database.saveThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final tickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

class MedsNotifier extends AsyncNotifier<List<Meds>> {
  @override
  Future<List<Meds>> build() => Database.getMeds();

  Future<void> save(List<Meds> meds) async {
    await Database.saveMeds(meds);
    state = AsyncValue.data(List.from(meds));
  }
}

final medsProvider = AsyncNotifierProvider<MedsNotifier, List<Meds>>(
  MedsNotifier.new,
);

class DosesNotifier extends AsyncNotifier<List<DosePreset>> {
  @override
  Future<List<DosePreset>> build() => Database.getDoses();

  Future<void> save(List<DosePreset> doses) async {
    await Database.saveDoses(doses);
    state = AsyncValue.data(List.from(doses));
  }
}

final dosesProvider = AsyncNotifierProvider<DosesNotifier, List<DosePreset>>(
  DosesNotifier.new,
);

class ActiveMedsNotifier extends AsyncNotifier<List<ActiveMeds>> {
  @override
  Future<List<ActiveMeds>> build() => Database.getActiveMeds();

  Future<void> save(List<ActiveMeds> activeMeds) async {
    await Database.saveActiveMeds(activeMeds);
    state = AsyncValue.data(List.from(activeMeds));
  }
}

final activeMedsProvider =
    AsyncNotifierProvider<ActiveMedsNotifier, List<ActiveMeds>>(
      ActiveMedsNotifier.new,
    );
