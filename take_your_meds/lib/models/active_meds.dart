import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:take_your_meds/models/dose_preset.dart';
import 'package:take_your_meds/models/meds.dart';
import 'package:take_your_meds/notifications.dart';
import 'package:take_your_meds/settings.dart';
import 'package:take_your_meds/time.dart';
import 'package:timezone/timezone.dart';

enum TakeMedsTimerResolution { none, keepReminder, clearReminder }

enum TakeMedsAction { none, startActiveMeds }

class ActiveMeds {
  ActiveMeds({
    required this.id,
    required this.meds,
    required this.dose,
    required this.takenAt,
    required this.remindAt,
    required this.remindAgainAt,
  });

  ActiveMeds.none()
    : id = 'None',
      meds = Meds.none(),
      dose = DosePreset(id: 'none', name: 'None', meds: Meds.none(), dosage: 0),
      takenAt = DateTime.fromMillisecondsSinceEpoch(0),
      remindAt = DateTime.fromMillisecondsSinceEpoch(1000),
      remindAgainAt = DateTime.fromMillisecondsSinceEpoch(2000);

  ActiveMeds.fromDose(this.dose, DateTime takenAt)
    : id = UniqueKey().toString(),
      meds = dose.meds,
      takenAt = takenAt.toUtc(),
      remindAt = Time.getRemindAt(dose.meds.duration),
      remindAgainAt = Time.getRemindAgainAt(
        Time.getRemindAt(dose.meds.duration),
        Duration(minutes: Settings.remindAgainAtFrequencyInMins.currentValue),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ActiveMeds && other.id == id;

  final String id;
  final Meds meds;
  final DosePreset dose;
  final DateTime takenAt;
  final DateTime remindAt;
  final DateTime remindAgainAt;

  String getLabel() {
    return '${meds.name} ${dose.dosage}${dose.range.name} ${DateFormat.Hm().format(TZDateTime.from(remindAt, Notifications.location))}';
  }

  @override
  int get hashCode => id.hashCode;
}

class TakeMeds {
  TakeMeds({
    required this.id,
    required this.medsToTake,
    required this.medsToResolve,
    required this.timerResolution,
    required this.action,
  });

  final String id;
  ActiveMeds medsToTake;
  ActiveMeds? medsToResolve;
  late TakeMedsTimerResolution timerResolution;
  late TakeMedsAction action;
}
