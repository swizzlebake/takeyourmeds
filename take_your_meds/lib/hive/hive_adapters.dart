import 'package:hive_ce/hive_ce.dart';
import 'package:take_your_meds/models/active_meds.dart';
import 'package:take_your_meds/models/dose_preset.dart';
import 'package:take_your_meds/models/meds.dart';

@GenerateAdapters([
  AdapterSpec<Meds>(),
  AdapterSpec<DosePreset>(),
  AdapterSpec<MedsDoseRange>(),
  AdapterSpec<ActiveMeds>(),
])
part 'hive_adapters.g.dart';
