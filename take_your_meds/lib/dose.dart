import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';
import 'db.dart';
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
              Spacer(),
              ElevatedButton(
                onPressed: () => doseRemovedCallback(dosePreset),
                child: Text('Del'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DosePresetsOverview extends StatefulWidget {
  const DosePresetsOverview({
    super.key,
    required this.meds,
    required this.doses,
  });
  final List<Meds> meds;
  final List<DosePreset> doses;

  @override
  State<StatefulWidget> createState() => _DosePresetsOverviewState();
}

class _DosePresetsOverviewState extends State<DosePresetsOverview> {
  _DosePresetsOverviewState();
  List<DosePreset> doses = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    doses.addAll(widget.doses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                if (doses.isEmpty) {
                  return SizedBox(
                    height: 50,
                    child: Text('Add some new meds!'),
                  );
                }
                return DoseCard(
                  dosePreset: doses[index],
                  doseRemovedCallback: (delMeds) {
                    setState(() {
                      doses.remove(delMeds);
                    });
                    Database.saveDoses(doses);
                  },
                );
              },
              itemCount: doses.length,
            ),
          ),
          Flexible(
            child: CreateDosePresetWidget(
              meds: widget.meds,
              doses: widget.doses,
              dosePresetChangedCallback: (newDose) {
                setState(() {
                  doses.add(newDose);
                });
                Database.saveDoses(doses);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: TYMNavigation(pageIndex: 2),
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
        duration: 0,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Text('Select meds'),
              DropdownButton<Meds>(
                items: dropDownItems,
                value: selectedMed,
                onChanged: (med) => setState(() {
                  if (med != null) {
                    selectedMed = med;
                  }
                }),
              ),
            ],
          ),
          Flexible(
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
              setState(() {
                doses.add(
                  DosePreset(
                    id: UniqueKey().toString(),
                    name: dose.toString(),
                    meds: selectedMed,
                    dosage: dose,
                  ),
                );
              });
              Database.saveDoses(doses);
            },
            child: Text('Save Dose'),
          ),
        ],
      ),
    );
  }
}
