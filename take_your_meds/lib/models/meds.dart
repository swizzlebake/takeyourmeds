import 'package:flutter/material.dart';
import 'package:take_your_meds/models/dose_preset.dart';

enum MedsDoseRange { ug, mg, g }

class Meds {
  Meds({
    required this.name,
    required this.id,
    required this.range,
    required this.duration,
    this.doses = const [],
  });
  final String name;
  final String id;
  final MedsDoseRange range;
  final Duration duration;
  final List<DosePreset> doses;

  Meds.none()
    : name = 'None',
      id = UniqueKey().toString(),
      range = MedsDoseRange.ug,
      duration = Duration(),
      doses = const [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Meds && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
