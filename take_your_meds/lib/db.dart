import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/hive/hive_registrar.g.dart';
import 'meds.dart';

class Database {
  Database();
  static late BoxCollection boxCollection;
  static late CollectionBox<Meds> medsBox;
  static late CollectionBox<DosePreset> doseBox;
  static late List<Meds> cachedMeds;
  static late List<DosePreset> cachedDoses;

  static Future<void> init() async {
    await Hive.initFlutter('./tym');
    boxCollection = await BoxCollection.open('tym', {
      'meds',
      'dose',
      'timers',
    }, path: './tym');

    Hive.registerAdapters();
    medsBox = await boxCollection.openBox('meds');
    doseBox = await boxCollection.openBox('dose');
    cachedMeds = await getMeds();
    cachedDoses = await getDoses();
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

  static Future<void> saveDoses(List<DosePreset> doses) async {
    await doseBox.clear();
    await boxCollection.transaction(() async {
      for (var dose in doses) {
        await doseBox.put(dose.id, dose);
      }
    });

    cachedDoses = await getDoses();
  }

  static Future<List<DosePreset>> getDoses() async {
    var dosages = await doseBox.getAll(await doseBox.getAllKeys());
    var finalDoses = List<DosePreset>.empty(growable: true);
    for (var dose in dosages) {
      if (dose != null) {
        finalDoses.add(dose);
      }
    }
    return finalDoses;
  }
}
