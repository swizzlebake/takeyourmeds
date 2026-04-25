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
    return SizedBox(
      height: 50,
      child: Card(
        elevation: 0.5,
        child: Padding(
          padding: EdgeInsetsGeometry.all(5),
          child: Row(
            children: [
              Text(
                '${dosePreset.meds.name} ${dosePreset.dosage}${dosePreset.range.name}',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => doseRemovedCallback(dosePreset),
                child: const Text('Del'),
              ),
            ],
          ),
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

  late Meds selectedMed;
  List<DosePreset> doses = List.empty(growable: true);
  int dose = 0;

  @override
  void initState() {
    super.initState();

    doses.addAll(widget.doses);

    if (widget.meds.isNotEmpty) {
      selectedMed = widget.meds[0];
    } else {
      selectedMed = Meds(
        name: 'none',
        id: '',
        range: MedsDoseRange.mg,
        duration: Duration(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    dropDownItems.clear();
    for (var med in widget.meds) {
      dropDownItems.add(DropdownMenuItem(value: med, child: Text(med.name)));
    }

    return Card(
      child: Column(
        spacing: 20,
        children: [
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
                Text(selectedMed.range.name),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              var dosePreset = DosePreset(
                id: UniqueKey().toString(),
                name: dose.toString(),
                meds: selectedMed,
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
