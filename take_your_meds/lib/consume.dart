import 'package:flutter/material.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';
import 'package:take_your_meds/navigation.dart';
import 'package:take_your_meds/settings.dart';

import 'notifications.dart';

class Consume extends StatefulWidget {
  const Consume({
    super.key,
    required this.doses,
    required this.selectedActiveMedsToTake,
    required this.selectedActiveMedsToResolve,
    required this.activeMeds,
  });
  final List<DosePreset> doses;
  final ActiveMeds? selectedActiveMedsToTake;
  final ActiveMeds? selectedActiveMedsToResolve;
  final List<ActiveMeds> activeMeds;

  @override
  State<StatefulWidget> createState() => _ConsumeState();
}

class _ConsumeState extends State<Consume> {
  late TakeMeds takeMeds;
  final List<DropdownMenuEntry<DosePreset>> _doseEntries = List.empty(
    growable: true,
  );
  final List<DropdownMenuEntry<ActiveMeds>> _activeMedEntries = List.empty(
    growable: true,
  );
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    for (var dose in widget.doses) {
      _doseEntries.add(
        DropdownMenuEntry<DosePreset>(value: dose, label: dose.getLabel()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    buildActiveMeds();
    buildTakeMeds();
    return Center(
      child: SizedBox(
        width: 500,
        height: 400,
        child: Card.filled(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Time For Meds!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Take Meds'),
              DropdownMenu<DosePreset>(
                initialSelection: takeMeds.medsToTake.dose,
                requestFocusOnTap: true,
                label: Text('Available Meds'),
                dropdownMenuEntries: _doseEntries,
                selectOnly: true,
                onSelected: (DosePreset? dose) {
                  if (dose == null) {
                    return;
                  }
                  setState(() {
                    takeMeds.medsToTake = ActiveMeds.fromDose(dose);
                  });
                },
              ),
              Text('Close Timer'),
              DropdownMenu<ActiveMeds>(
                width: 300,
                initialSelection: takeMeds.medsToResolve,
                requestFocusOnTap: true,
                label: Text('Active Meds'),
                dropdownMenuEntries: _activeMedEntries,
                selectOnly: true,
                onSelected: (ActiveMeds? activeMeds) {
                  if (activeMeds == null) {
                    return;
                  }
                  setState(() {
                    takeMeds.medsToResolve = activeMeds;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(takeMeds);
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        takeMeds.action = TakeMedsAction.startActiveMeds;
                      });
                      Navigator.of(context).pop(takeMeds);
                    },
                    child: Text('Take em!'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void buildTakeMeds() {
    buildActiveMeds();

    var medsToTake = widget.selectedActiveMedsToTake;
    var medsToResolve = widget.selectedActiveMedsToResolve;
    if (medsToTake == null && medsToResolve != null) {
      for (var dose in widget.doses) {
        if (dose.meds.id == medsToResolve.meds.id) {
          medsToTake = ActiveMeds.fromDose(dose);
          break;
        }
      }
    }

    if (medsToResolve == null && medsToTake != null) {
      for (var activeMeds in widget.activeMeds) {
        if (activeMeds.meds.id == medsToTake.meds.id) {
          medsToResolve = activeMeds;
          break;
        }
      }
    }

    takeMeds = TakeMeds(
      id: UniqueKey().toString(),
      medsToTake: medsToTake!,
      timerResolution: TakeMedsTimerResolution.none,
      action: TakeMedsAction.none,
      medsToResolve: medsToResolve,
    );
  }

  void buildActiveMeds() {
    _activeMedEntries.clear();
    _activeMedEntries.add(
      DropdownMenuEntry<ActiveMeds>(value: ActiveMeds.none(), label: 'None'),
    );

    var activeMedsToResolve = List<ActiveMeds>.empty(growable: true);
    for (var meds in widget.activeMeds) {
      var cancelWarningDuration = Duration(
        milliseconds:
            (meds.remindAt.difference(meds.takenAt).inMilliseconds *
                    Settings.cancelWarningWithConsumePercentage.currentValue)
                .toInt(),
      );
      var nowDuration = DateTime.now().toUtc().difference(meds.takenAt);
      _activeMedEntries.add(
        DropdownMenuEntry<ActiveMeds>(
          value: meds,
          label: meds.getLabel(),
          style: ButtonStyle(
            textStyle: WidgetStateTextStyle.resolveWith((
              Set<WidgetState> widgetState,
            ) {
              if (nowDuration < cancelWarningDuration) {
                return TextStyle(fontStyle: FontStyle.italic);
              }
              return TextStyle();
            }),
          ),
        ),
      );
      activeMedsToResolve.add(meds);
    }
  }
}
