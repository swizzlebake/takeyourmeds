import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_your_meds/providers.dart';
import 'meds.dart';
import 'navigation.dart';

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
  bool operator ==(Object other) {
    // TODO: implement ==
    return (other is DosePreset) ? (id == other.id) : false;
  }

  @override
  // TODO: implement hashCode
  int get hashCode => id.hashCode;
}

typedef DosePresetChangedCallback = void Function(DosePreset meds);

class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.dosePreset,
    required this.doseRemovedCallback,
  });
  final DosePreset dosePreset;
  final DosePresetChangedCallback doseRemovedCallback;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              '${dosePreset.meds.name} ${dosePreset.dosage}${dosePreset.range.name}',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => doseRemovedCallback(dosePreset),
              child: const Text('X'),
            ),
          ],
        ),
      ),
    );
  }
}

class DosePresetsOverview extends ConsumerWidget {
  const DosePresetsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(medsProvider).valueOrNull ?? [];
    final doses = ref.watch(dosesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dose List',
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
                    itemCount: doses.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (doses.isEmpty) {
                        return const SizedBox(
                          height: 50,
                          child: Text('Add some new meds!'),
                        );
                      }
                      return DoseCard(
                        dosePreset: doses[index],
                        doseRemovedCallback: (delDose) {
                          final updated = List<DosePreset>.from(doses)
                            ..remove(delDose);
                          ref.read(dosesProvider.notifier).save(updated);
                        },
                      );
                    },
                  ),
                ),
              ),
              Flexible(
                child: CreateDosePresetWidget(
                  meds: meds,
                  doses: doses,
                  dosePresetChangedCallback: (newDose) {
                    final updated = List<DosePreset>.from(doses)..add(newDose);
                    ref.read(dosesProvider.notifier).save(updated);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const TYMNavigation(pageIndex: 2),
    );
  }
}

class CreateDosePresetWidget extends StatefulWidget {
  const CreateDosePresetWidget({
    super.key,
    required this.meds,
    required this.doses,
    required this.dosePresetChangedCallback,
  });
  final List<Meds> meds;
  final List<DosePreset> doses;
  final DosePresetChangedCallback dosePresetChangedCallback;

  @override
  State<StatefulWidget> createState() => _CreateDosePresetWidgetState();
}

class _CreateDosePresetWidgetState extends State<CreateDosePresetWidget> {
  List<DropdownMenuItem<Meds>> dropDownItems = List.empty(growable: true);

  Meds? selectedMed;
  List<DosePreset> doses = List.empty(growable: true);
  int dose = 0;

  @override
  void initState() {
    super.initState();
    doses.addAll(widget.doses);
    selectedMed = widget.meds.isNotEmpty ? widget.meds[0] : null;
  }

  @override
  void didUpdateWidget(CreateDosePresetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedMed == null && widget.meds.isNotEmpty) {
      selectedMed = widget.meds[0];
    } else if (selectedMed != null && !widget.meds.contains(selectedMed)) {
      selectedMed = widget.meds.isNotEmpty ? widget.meds[0] : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    dropDownItems.clear();
    for (var med in widget.meds) {
      dropDownItems.add(DropdownMenuItem(value: med, child: Text(med.name)));
    }

    return Card.filled(
      child: Column(
        spacing: 20,
        children: [
          Text(
            'Add New Dose',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Row(
            spacing: 50,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select meds'),
              ),
              DropdownButton<Meds>(
                items: dropDownItems,
                value: selectedMed,
                onChanged: (med) => setState(() {
                  if (med != null) selectedMed = med;
                }),
              ),
            ],
          ),
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'dose'),
                    onChanged: (txt) {
                      var tryDose = int.tryParse(txt);
                      if (tryDose != null) {
                        setState(() {
                          dose = tryDose;
                        });
                      }
                    },
                  ),
                ),
                Text(selectedMed?.range.name ?? ''),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: selectedMed == null
                ? null
                : () {
                    final dosePreset = DosePreset(
                      id: UniqueKey().toString(),
                      name: dose.toString(),
                      meds: selectedMed!,
                      dosage: dose,
                    );
                    setState(() {
                      doses.add(dosePreset);
                    });
                    widget.dosePresetChangedCallback(dosePreset);
                  },
            child: const Text('Save Dose'),
          ),
        ],
      ),
    );
  }
}
