import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';
import 'package:take_your_meds/providers.dart';
import 'package:take_your_meds/settings.dart';

class Consume extends ConsumerStatefulWidget {
  const Consume({
    super.key,
    required this.selectedActiveMedsToTake,
    required this.selectedActiveMedsToResolve,
  });
  final ActiveMeds? selectedActiveMedsToTake;
  final ActiveMeds? selectedActiveMedsToResolve;

  @override
  ConsumerState<Consume> createState() => _ConsumeState();
}

class _ConsumeState extends ConsumerState<Consume> {
  late TakeMeds takeMeds;
  final List<DropdownMenuEntry<DosePreset>> _doseEntries = [];
  final List<DropdownMenuEntry<ActiveMeds>> _activeMedEntries = [];

  @override
  void initState() {
    super.initState();
    final doses = ref.read(dosesProvider).valueOrNull ?? [];
    final activeMeds = ref.read(activeMedsProvider).valueOrNull ?? [];

    for (var dose in doses) {
      _doseEntries.add(
        DropdownMenuEntry<DosePreset>(value: dose, label: dose.getLabel()),
      );
    }
    _buildActiveMeds(activeMeds);
    _buildTakeMeds(doses, activeMeds);
  }

  void _buildTakeMeds(List<DosePreset> doses, List<ActiveMeds> activeMeds) {
    var medsToTake = widget.selectedActiveMedsToTake;
    var medsToResolve = widget.selectedActiveMedsToResolve;

    if (medsToTake == null && medsToResolve != null) {
      for (var dose in doses) {
        if (dose.meds.id == medsToResolve.meds.id) {
          medsToTake = ActiveMeds.fromDose(dose);
          break;
        }
      }
    }

    if (medsToResolve == null && medsToTake != null) {
      for (var active in activeMeds) {
        if (active.meds.id == medsToTake.meds.id) {
          medsToResolve = active;
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

  void _buildActiveMeds(List<ActiveMeds> activeMeds) {
    _activeMedEntries.clear();
    _activeMedEntries.add(
      DropdownMenuEntry<ActiveMeds>(value: ActiveMeds.none(), label: 'None'),
    );
    for (var meds in activeMeds) {
      final cancelWarningDuration = Duration(
        milliseconds: (meds.remindAt.difference(meds.takenAt).inMilliseconds *
                Settings.cancelWarningWithConsumePercentage.currentValue)
            .toInt(),
      );
      final nowDuration = DateTime.now().toUtc().difference(meds.takenAt);
      _activeMedEntries.add(
        DropdownMenuEntry<ActiveMeds>(
          value: meds,
          label: meds.getLabel(),
          style: ButtonStyle(
            textStyle: WidgetStateTextStyle.resolveWith((states) {
              if (nowDuration < cancelWarningDuration) {
                return const TextStyle(fontStyle: FontStyle.italic);
              }
              return const TextStyle();
            }),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 500,
        height: 400,
        child: Card.filled(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'Time For Meds!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Take Meds'),
              DropdownMenu<DosePreset>(
                initialSelection: takeMeds.medsToTake.dose,
                requestFocusOnTap: true,
                label: const Text('Available Meds'),
                dropdownMenuEntries: _doseEntries,
                selectOnly: true,
                onSelected: (DosePreset? dose) {
                  if (dose == null) return;
                  setState(() {
                    takeMeds.medsToTake = ActiveMeds.fromDose(dose);
                  });
                },
              ),
              const Text('Close Timer'),
              DropdownMenu<ActiveMeds>(
                width: 300,
                initialSelection: takeMeds.medsToResolve,
                requestFocusOnTap: true,
                label: const Text('Active Meds'),
                dropdownMenuEntries: _activeMedEntries,
                selectOnly: true,
                onSelected: (ActiveMeds? activeMeds) {
                  if (activeMeds == null) return;
                  setState(() {
                    takeMeds.medsToResolve = activeMeds;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(takeMeds),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        takeMeds.action = TakeMedsAction.startActiveMeds;
                      });
                      Navigator.of(context).pop(takeMeds);
                    },
                    child: const Text('Take em!'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
