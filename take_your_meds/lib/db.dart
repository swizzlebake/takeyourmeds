import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:take_your_meds/hive/hive_registrar.g.dart';
import 'package:take_your_meds/models/active_meds.dart';
import 'package:take_your_meds/models/meds.dart';

class Database {
  Database();
  static late BoxCollection boxCollection;
  static late CollectionBox<Meds> medsBox;
  static late CollectionBox<ActiveMeds> activeMedsBox;
  static late CollectionBox<int> settingsBox;
  static late List<Meds> cachedMeds;
  static late List<ActiveMeds> cachedActiveMeds;
  static late ThemeMode cachedThemeMode;

  static Future<void> init() async {
    await Hive.initFlutter('./tym');
    boxCollection = await BoxCollection.open('tym', {
      'meds',
      'timers',
      'settings',
    }, path: './tym');
    Hive.registerAdapters();
    medsBox = await boxCollection.openBox('meds');
    activeMedsBox = await boxCollection.openBox('timers');
    settingsBox = await boxCollection.openBox('settings');
    final themeModeIndex = await settingsBox.get('themeMode');
    cachedThemeMode = themeModeIndex != null
        ? ThemeMode.values[themeModeIndex]
        : ThemeMode.system;

    cachedMeds = await getMeds();
    cachedActiveMeds = await getActiveMeds();
  }

  static Future<List<Meds>> getMeds() async {
    var meds = await medsBox.getAll(await medsBox.getAllKeys());
    var finalMeds = List<Meds>.empty(growable: true);
    for (var med in meds) {
      if (med != null) {
        finalMeds.add(med);
      }
    }
    return finalMeds;
  }

  static Future<void> saveMeds(List<Meds> meds) async {
    await medsBox.clear();
    await boxCollection.transaction(() async {
      for (var med in meds) {
        await medsBox.put(med.id, med);
      }
    });

    cachedMeds = await getMeds();
  }

  static Future<void> saveActiveMeds(List<ActiveMeds> activeMeds) async {
    await activeMedsBox.clear();
    await boxCollection.transaction(() async {
      for (var med in activeMeds) {
        await activeMedsBox.put(med.id, med);
      }
    });

    cachedActiveMeds = await getActiveMeds();
  }

  static Future<List<ActiveMeds>> getActiveMeds() async {
    var meds = await activeMedsBox.getAll(await activeMedsBox.getAllKeys());
    var finalMeds = List<ActiveMeds>.empty(growable: true);
    for (var med in meds) {
      if (med != null) {
        finalMeds.add(med);
      }
    }
    return finalMeds;
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    await settingsBox.put('themeMode', mode.index);
    cachedThemeMode = mode;
  }
}
