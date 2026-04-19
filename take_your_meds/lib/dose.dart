import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
      appBar: AppBar(
        title: Text(
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
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
                child: SizedBox(
                  width: 500,
                  height: isKeyboardVisible ? 50 : 300,
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
          );
        },
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Select meds'),
              ),

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
              Database.saveDoses(doses);
              widget.dosePresetChangedCallback(dosePreset);
            },
            child: Text('Save Dose'),
          ),
        ],
      ),
    );
  }
}
