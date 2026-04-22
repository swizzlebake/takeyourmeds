import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/settings.dart';
import 'package:take_your_meds/time.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/tzdata.dart';
import 'db.dart';
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
  bool operator ==(Object other) => identical(this, other) || other is ActiveMeds && other.id == id;


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
typedef SaveMedsCallback = void Function(List<Meds> meds);

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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' dosage: '),
                      TextSpan(
                        text: meds.range.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' lasts: '),
                      TextSpan(
                        text:
                            '${duration.inHours}h ${duration.inMinutes % 60}m',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => medsRemovedCallback(meds),
                  child: Text("X"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedsOverview extends StatefulWidget {
  const MedsOverview({super.key, required this.meds, required this.doses});
  final List<Meds> meds;
  final List<DosePreset> doses;
  @override
  State<StatefulWidget> createState() => _MedsOverviewState();
}

class _MedsOverviewState extends State<MedsOverview> {
  _MedsOverviewState();

  List<Meds> meds = List.empty(growable: true);
  List<DosePreset> doses = List.empty(growable: true);
  Meds? editMeds;
  final FocusNode focusNode = FocusNode();
  @override
  void initState() {
    super.initState();

    meds.addAll(widget.meds);
    doses.addAll(widget.doses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
                child: SizedBox(
                  width: 500,
                  height: isKeyboardVisible ? 50 : 300,
                  child: ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return MedsCard(
                        meds: meds[index],
                        duration: meds[index].duration,
                        medsTappedCallback: (editMeds) {
                          setState(() {
                            this.editMeds = editMeds;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              focusNode.requestFocus();
                            }
                          });
                        },
                        medsRemovedCallback: (delMeds) {
                          setState(() {
                            meds.remove(delMeds);
                            doses.removeWhere(
                              (dose) => dose.meds.id == delMeds.id,
                            );
                          });
                          Database.saveMeds(meds);
                          Database.saveDoses(doses);
                        },
                      );
                    },
                    itemCount: meds.length,
                  ),
                ),
              ),
              Flexible(
                child: CreateMedsWidget(
                  focusNode: focusNode,
                  editMeds: editMeds,
                  medsChangedCallback: (newMeds) {
                    setState(() {
                      for (var med in meds) {
                        if (med.id == newMeds.id) {
                          meds.remove(med);
                          break;
                        }
                      }
                      meds.add(newMeds);
                    });
                    Database.saveMeds(meds);

                    editMeds = null;
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: TYMNavigation(pageIndex: 1),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    // TODO: implement deactivate
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
  _CreateMedsWidgetState();
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
    var buttons = List<Widget>.empty(growable: true);

    buttons.add(
      ElevatedButton(
        onPressed: () {
          setState(() {
            meds = Meds.none();
          });
          updateFields();
        },
        child: Text(widget.editMeds != null ? 'Cancel' : 'Clear'),
      ),
    );
    buttons.add(
      ElevatedButton(
        onPressed: onAddPressed,
        child: Text(widget.editMeds != null ? 'Save Meds' : 'Add Meds'),
      ),
    );
    return Card.filled(
      child: Column(
        spacing: 10,
        children: <Widget>[
          Text(
            widget.editMeds != null ? 'Edit Meds' : 'Add New Meds',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              decoration: InputDecoration(hintText: 'name'),
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
                    final newTxt = txt;
                    final hasDot = '.'.allMatches(newTxt).length == 1;
                    final hasComma = ','.allMatches(newTxt).length == 1;
                    int? tryDuration = 0;
                    if (hasDot || hasComma) {
                      return;
                    }

                    tryDuration = int.tryParse(newTxt);
                    if (tryDuration != null) {
                      durationHours = tryDuration;
                    }
                    updateState();
                  },
                  textAlign: TextAlign.center,
                ),
              ),
              Text('h'),
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
                    final newTxt = txt;
                    final hasDot = '.'.allMatches(newTxt).length == 1;
                    final hasComma = ','.allMatches(newTxt).length == 1;
                    int? tryDuration = 0;
                    if (hasDot || hasComma) {
                      return;
                    }

                    tryDuration = int.tryParse(newTxt);
                    if (tryDuration != null) {
                      durationMins = tryDuration;
                    }
                    updateState();
                  },
                  textAlign: TextAlign.center,
                ),
              ),
              Text('m'),
            ],
          ),
          ...buttons,
        ],
      ),
    );
  }

  void updateDoseRangeRadioSelection(MedsDoseRange? range) {
    if (range != null) {
      doseRange = range;
    }
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

class ActiveMedsWidget extends StatefulWidget {
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
  State<StatefulWidget> createState() => _ActiveMedsWidgetState();
}

class _ActiveMedsWidgetState extends State<ActiveMedsWidget> {
  Color color = Colors.white;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var t = clampDouble(
      DateTime.now().difference(widget.activeMeds.remindAt).inSeconds / 30.0,
      0,
      1,
    );
    var hsv = HSVColor.lerp(
      HSVColor.fromColor(Colors.white),
      HSVColor.fromColor(Colors.yellow),
      t,
    );

    color = hsv != null ? hsv.toColor() : Colors.white;
    return GestureDetector(onTap: () => widget.onTap(), child: Card(
      shadowColor: color,
      child: Center(child: Text(widget.activeMeds.getLabel())),
    ));
  }
}
