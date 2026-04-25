import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/providers.dart';
import 'package:take_your_meds/settings.dart';
import 'package:take_your_meds/time.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'navigation.dart';
import 'notifications.dart';

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
}

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

  ActiveMeds.fromDose(this.dose)
    : id = UniqueKey().toString(),
      meds = dose.meds,
      takenAt = DateTime.now().toUtc(),
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

enum TakeMedsTimerResolution { none, keepReminder, clearReminder }

enum TakeMedsAction { none, startActiveMeds }

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

typedef MedsChangedCallback = void Function(Meds meds);

class MedsCard extends StatelessWidget {
  const MedsCard({
    super.key,
    required this.meds,
    required this.duration,
    required this.medsTappedCallback,
    required this.medsRemovedCallback,
  });
  final Meds meds;
  final Duration duration;
  final MedsChangedCallback medsTappedCallback;
  final MedsChangedCallback medsRemovedCallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: GestureDetector(
        onTap: () => medsTappedCallback(meds),
        child: Card(
          elevation: 0.5,
          child: Padding(
            padding: EdgeInsetsGeometry.all(2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RichText(
                  text: TextSpan(
                    text: '',
                    children: <TextSpan>[
                      TextSpan(
                        text: meds.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' dosage: '),
                      TextSpan(
                        text: meds.range.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' lasts: '),
                      TextSpan(
                        text:
                            '${duration.inHours}h ${duration.inMinutes % 60}m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => medsRemovedCallback(meds),
                  child: const Text("X"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedsOverview extends ConsumerStatefulWidget {
  const MedsOverview({super.key});

  @override
  ConsumerState<MedsOverview> createState() => _MedsOverviewState();
}

class _MedsOverviewState extends ConsumerState<MedsOverview> {
  Meds? editMeds;
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final meds = ref.watch(medsProvider).valueOrNull ?? [];
    final doses = ref.watch(dosesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meds List',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
                child: SizedBox(
                  width: 500,
                  height: isKeyboardVisible ? 50 : 300,
                  child: ListView.builder(
                    itemCount: meds.length,
                    itemBuilder: (BuildContext context, int index) {
                      return MedsCard(
                        meds: meds[index],
                        duration: meds[index].duration,
                        medsTappedCallback: (tapped) {
                          setState(() {
                            editMeds = tapped;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) focusNode.requestFocus();
                          });
                        },
                        medsRemovedCallback: (delMeds) {
                          final updatedMeds = List<Meds>.from(meds)
                            ..remove(delMeds);
                          final updatedDoses = List<DosePreset>.from(doses)
                            ..removeWhere((d) => d.meds.id == delMeds.id);
                          ref.read(medsProvider.notifier).save(updatedMeds);
                          ref.read(dosesProvider.notifier).save(updatedDoses);
                        },
                      );
                    },
                  ),
                ),
              ),
              Flexible(
                child: CreateMedsWidget(
                  focusNode: focusNode,
                  editMeds: editMeds,
                  medsChangedCallback: (newMeds) {
                    final updated = List<Meds>.from(meds)
                      ..removeWhere((m) => m.id == newMeds.id)
                      ..add(newMeds);
                    ref.read(medsProvider.notifier).save(updated);
                    setState(() {
                      editMeds = null;
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const TYMNavigation(pageIndex: 1),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
}

class CreateMedsWidget extends StatefulWidget {
  const CreateMedsWidget({
    super.key,
    required this.medsChangedCallback,
    required this.editMeds,
    required this.focusNode,
  });
  final MedsChangedCallback medsChangedCallback;
  final Meds? editMeds;
  final FocusNode focusNode;

  @override
  State<StatefulWidget> createState() => _CreateMedsWidgetState();
}

class _CreateMedsWidgetState extends State<CreateMedsWidget> {
  var meds = Meds.none();
  var editMeds = Meds.none();
  String nameText = '';
  MedsDoseRange doseRange = MedsDoseRange.mg;
  int durationHours = 0;
  int durationMins = 0;
  String hoursHintText = 'hours';
  String minsHintText = 'minutes';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController minsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editMeds = widget.editMeds ?? Meds.none();
  }

  @override
  void dispose() {
    nameController.dispose();
    hoursController.dispose();
    minsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CreateMedsWidget oldHome) {
    super.didUpdateWidget(oldHome);

    if (widget.editMeds != null && widget.editMeds != oldHome.editMeds) {
      editMeds = widget.editMeds!;
      meds = editMeds;
      updateFields();
    }
  }

  void updateFields() {
    nameText = meds.name;
    doseRange = meds.range;
    durationMins = meds.duration.inMinutes % 60;
    durationHours = meds.duration.inHours;
    nameController.text = nameText;
    hoursController.text = durationHours.toString();
    minsController.text = durationMins.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Column(
        spacing: 10,
        children: <Widget>[
          Text(
            widget.editMeds != null ? 'Edit Meds' : 'Add New Meds',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              focusNode: widget.focusNode,
              keyboardType: TextInputType.text,
              controller: nameController,
              decoration: const InputDecoration(hintText: 'name'),
              onChanged: (txt) {
                nameText = txt;
                updateState();
              },
            ),
          ),
          RadioGroup<MedsDoseRange>(
            groupValue: doseRange,
            onChanged: updateDoseRangeRadioSelection,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _doseOption('ug', MedsDoseRange.ug),
                _doseOption('mg', MedsDoseRange.mg),
                _doseOption('g', MedsDoseRange.g),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: hoursHintText),
                  onChanged: (txt) {
                    final hasDot = '.'.allMatches(txt).length == 1;
                    final hasComma = ','.allMatches(txt).length == 1;
                    if (hasDot || hasComma) return;
                    final tryDuration = int.tryParse(txt);
                    if (tryDuration != null) durationHours = tryDuration;
                    updateState();
                  },
                  textAlign: TextAlign.center,
                ),
              ),
              const Text('h'),
              SizedBox(
                width: 100,
                child: TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  controller: minsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: minsHintText),
                  onChanged: (txt) {
                    final hasDot = '.'.allMatches(txt).length == 1;
                    final hasComma = ','.allMatches(txt).length == 1;
                    if (hasDot || hasComma) return;
                    final tryDuration = int.tryParse(txt);
                    if (tryDuration != null) durationMins = tryDuration;
                    updateState();
                  },
                  textAlign: TextAlign.center,
                ),
              ),
              const Text('m'),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                meds = Meds.none();
                editMeds = Meds.none();
              });
              updateFields();
            },
            child: Text(widget.editMeds != null ? 'Cancel' : 'Clear'),
          ),
          ElevatedButton(
            onPressed: onAddPressed,
            child: Text(widget.editMeds != null ? 'Save Meds' : 'Add Meds'),
          ),
        ],
      ),
    );
  }

  void updateDoseRangeRadioSelection(MedsDoseRange? range) {
    if (range != null) doseRange = range;
    updateState();
  }

  void onAddPressed() {
    widget.medsChangedCallback(meds);
    setState(() {
      meds = Meds.none();
      editMeds = Meds.none();
    });
    updateFields();
  }

  void updateState() {
    setState(() {
      meds = Meds(
        name: nameText,
        id: meds.id,
        range: doseRange,
        duration: Duration(hours: durationHours, minutes: durationMins),
      );
    });
  }

  Widget _doseOption(String label, MedsDoseRange value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<MedsDoseRange>(
          value: value,
          visualDensity: VisualDensity.compact,
        ),
        Text(label),
      ],
    );
  }
}

class ActiveMedsWidget extends StatelessWidget {
  const ActiveMedsWidget({
    super.key,
    required this.activeMeds,
    required this.location,
    required this.onTap,
  });
  final ActiveMeds activeMeds;
  final tz.Location location;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    var t = clampDouble(
      DateTime.now().difference(activeMeds.remindAt).inSeconds / 30.0,
      0,
      1,
    );
    var hsv = HSVColor.lerp(
      HSVColor.fromColor(Colors.white),
      HSVColor.fromColor(Colors.yellow),
      t,
    );
    final color = hsv != null ? hsv.toColor() : Colors.white;

    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        shadowColor: color,
        child: Center(child: Text(activeMeds.getLabel())),
      ),
    );
  }
}
