import 'package:take_your_meds/models/meds.dart';

class DosePreset {
  DosePreset({required this.id, required this.dosage});
  final String id;
  final int dosage;

  DosePreset.none() : id = 'none', dosage = 0;

  String getLabel(Meds meds) => '${meds.name} $dosage${meds.range.name}';

  @override
  bool operator ==(Object other) => other is DosePreset && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
