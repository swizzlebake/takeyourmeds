import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';
import 'db.dart';
import 'navigation.dart';

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
  final int duration; //hours
}

typedef MedsChangedCallback = void Function(Meds meds);
typedef SaveMedsCallback = void Function(List<Meds> meds);

class MedsCard extends StatelessWidget {
  const MedsCard({
    super.key,
    required this.meds,
    required this.medsRemovedCallback,
  });
  final Meds meds;
  final MedsChangedCallback medsRemovedCallback;
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
                'Med ${meds.name} dose range: ${meds.range.name} duration ${meds.duration} hours',
                style: TextStyle(color: Colors.black),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () => medsRemovedCallback(meds),
                child: Text("Del"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MedsOverview extends StatefulWidget {
  const MedsOverview({super.key, required this.meds});
  final List<Meds> meds;
  @override
  State<StatefulWidget> createState() => _MedsOverviewState();
}

class _MedsOverviewState extends State<MedsOverview> {
  _MedsOverviewState();

  List<Meds> meds = List.empty(growable: true);
  @override
  void initState() {
    super.initState();

    meds.addAll(widget.meds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                if (meds.isEmpty) {
                  return SizedBox(
                    height: 50,
                    child: Text('Add some new meds!'),
                  );
                }
                return MedsCard(
                  meds: meds[index],
                  medsRemovedCallback: (delMeds) {
                    setState(() {
                      meds.remove(delMeds);
                    });
                    Database.saveMeds(meds);
                  },
                );
              },
              itemCount: meds.length,
            ),
          ),
          Flexible(
            child: CreateMedsWidget(
              medsChangedCallback: (newMeds) {
                setState(() {
                  meds.add(newMeds);
                });

                Database.saveMeds(meds);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: TYMNavigation(pageIndex: 1),
    );
  }
}

class CreateMedsWidget extends StatefulWidget {
  const CreateMedsWidget({super.key, required this.medsChangedCallback});
  final MedsChangedCallback medsChangedCallback;
  @override
  State<StatefulWidget> createState() => _CreateMedsWidgetState();
}

class _CreateMedsWidgetState extends State<CreateMedsWidget> {
  _CreateMedsWidgetState();
  final TextEditingController _controller = TextEditingController();
  var meds = Meds(
    name: 'none',
    id: UniqueKey().toString(),
    range: MedsDoseRange.ug,
    duration: 360,
  );

  bool textChanged = false;
  MedsDoseRange doseRange = MedsDoseRange.mg;
  int duration = 0;
  @override
  void initState() {
    super.initState();

    _controller.text = 'Medication name';
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);
    _controller.addListener(onTextChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            children: <Widget>[
              Flexible(child: TextField(controller: _controller)),
              RadioGroup<MedsDoseRange>(
                groupValue: doseRange,
                onChanged: updateDoseRangeRadioSelection,
                child: Row(
                  children: [
                    Flexible(
                      child: ListTile(
                        title: Text('ug'),
                        leading: Radio<MedsDoseRange>(value: MedsDoseRange.ug),
                      ),
                    ),
                    Flexible(
                      child: ListTile(
                        title: Text('mg'),
                        leading: Radio<MedsDoseRange>(value: MedsDoseRange.mg),
                      ),
                    ),
                    Flexible(
                      child: ListTile(
                        title: Text('g'),
                        leading: Radio<MedsDoseRange>(value: MedsDoseRange.g),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: TextField(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Duration in hours',
                  ),
                  onChanged: (txt) {
                    var tryDuration = int.tryParse(txt);
                    if (tryDuration != null) {
                      duration = tryDuration;
                    }
                    updateState();
                  },
                ),
              ),
              ElevatedButton(onPressed: onAddPressed, child: Text('Add Meds')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(onTextChanged);
    super.dispose();
  }

  void onTextChanged() {
    String text = _controller.text;
    var offset = textChanged ? text.length : 0;
    if (!textChanged) {
      text = '';
      textChanged = true;
    }
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection(baseOffset: offset, extentOffset: offset),
    );

    updateState();
  }

  void updateDoseRangeRadioSelection(MedsDoseRange? range) {
    if (range != null) {
      doseRange = range;
    }
    updateState();
  }

  void onAddPressed() {
    widget.medsChangedCallback(meds);
  }

  void updateState() {
    setState(() {
      meds = Meds(
        name: _controller.text,
        id: UniqueKey().toString(),
        range: doseRange,
        duration: duration,
      );
    });
  }
}
