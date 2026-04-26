import 'package:take_your_meds/models/meds.dart';

class DosePreset {
  DosePreset({
    required this.id,
    required this.name,
    required this.meds,
    required this.dosage,
  }) : range = meds.range;
  final String id;
  final String name;
  final Meds meds;
  final MedsDoseRange range;
  final int dosage;

  DosePreset.none()
    : id = 'none',
      name = 'None',
      meds = Meds.none(),
      range = MedsDoseRange.ug,
      dosage = 0;

  String getLabel() {
    return '${meds.name} $dosage${range.name}';
  }

  @override
  bool operator ==(Object other) =>
      other is DosePreset && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
