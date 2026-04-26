import 'package:flutter/material.dart';

enum MedsDoseRange { ug, mg, g }

class Meds {
  Meds({
    required this.name,
    required this.id,
    required this.range,
    required this.duration,
  });
  final String name;
  final String id;
  final MedsDoseRange range;
  final Duration duration;

  Meds.none()
    : name = 'None',
      id = UniqueKey().toString(),
      range = MedsDoseRange.ug,
      duration = Duration();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Meds && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
