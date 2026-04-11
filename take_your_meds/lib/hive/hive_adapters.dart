import 'package:hive_ce/hive_ce.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';

@GenerateAdapters([
  AdapterSpec<Meds>(),
  AdapterSpec<DosePreset>(),
  AdapterSpec<MedsDoseRange>(),
  AdapterSpec<ActiveMeds>(),
])
part 'hive_adapters.g.dart';
