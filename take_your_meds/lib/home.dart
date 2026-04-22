import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:take_your_meds/consume.dart';
import 'package:take_your_meds/db.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';
import 'package:take_your_meds/navigation.dart';
import 'package:take_your_meds/settings.dart';
import 'package:take_your_meds/time.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notifications.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.doses,
    required this.activeMeds,
    required this.location,
  });

  final List<DosePreset> doses;
  final List<ActiveMeds> activeMeds;
  final tz.Location location;
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<DosePreset> doses = List.empty(growable: true);
  List<ActiveMeds> activeMeds = List.empty(growable: true);
  DateTime _tick = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    doses.addAll(widget.doses);
    activeMeds.addAll(widget.activeMeds);
    activeMeds.sort(
      (ActiveMeds a, ActiveMeds b) => a.takenAt.compareTo(b.takenAt),
    );
  }

  @override
  void didUpdateWidget(covariant Home oldHome) {
    super.didUpdateWidget(oldHome);

    if (widget != oldHome) {
      doses.clear();
      doses.addAll(widget.doses);
      activeMeds.clear();
      activeMeds.addAll(widget.activeMeds);

      Time.registerCallback(tick);
    }
  }

  void tick() => {
    setState(() {
      _tick = DateTime.now();
    }),
  };

  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();

    Time.removeCallback(tick);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Available Meds ${DateFormat.Hms().format(tz.TZDateTime.from(_tick, Notifications.location)).toString()}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ElevatedButton(
                    onPressed: () async {
                      await onPressedDosePreset(doses[index]);
                    },
                    child: Text(doses[index].getLabel()),
                  ),
                );
              },
              itemCount: doses.length,
            ),
          ),
          GestureDetector(
            onLongPress: () async {
              var clearedActiveMeds = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Center(
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: Card.filled(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'Clear all?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      activeMeds = List.empty(growable: true);
                                    });
                                    Database.saveActiveMeds(activeMeds);
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Text('Yes'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Text(
              'Active Meds',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return ActiveMedsWidget(
                  activeMeds: activeMeds[index],
                  location: Notifications.location,
                  onTap: () async => await onPressedActiveMeds(activeMeds[index]),
                );
              },
              itemCount: activeMeds.length,
            ),
          ),
        ],
      ),
      bottomNavigationBar: TYMNavigation(pageIndex: 0),
    );
  }

  Future<void> onPressedDosePreset(DosePreset dose) async {
    var medsToTake = ActiveMeds.fromDose(dose);
    var result = await showDialog(
      context: context,
      builder: (BuildContext builder) {
        return Consume(
          doses: Database.cachedDoses,
          activeMeds: Database.cachedActiveMeds,
          selectedActiveMedsToTake: medsToTake,
          selectedActiveMedsToResolve: null,
        );
      },
    );
    if (result == null) {
      return;
    }
    var takeMeds = result as TakeMeds;
    _handleConsumeResult(takeMeds);
  }

  Future<void> onPressedActiveMeds(ActiveMeds meds) async {
    var result = await showDialog(
      context: context,
      builder: (BuildContext builder) {
        var consume = Consume(
          doses: Database.cachedDoses,
          activeMeds: Database.cachedActiveMeds,
          selectedActiveMedsToTake: null,
          selectedActiveMedsToResolve: meds,
        );
        return consume;
      },
    );
    if (result == null) {
      return;
    }
    var takeMeds = result as TakeMeds;
    await _handleConsumeResult(takeMeds);
  }

  Future<void> _handleConsumeResult(TakeMeds takeMeds) async {
    if (takeMeds.action == TakeMedsAction.startActiveMeds) {
      setState(() {
        activeMeds.add(takeMeds.medsToTake);
        activeMeds.remove(takeMeds.medsToResolve);
      });
    }

    Database.saveActiveMeds(activeMeds);
    await Notifications.scheduleAlarm(takeMeds.medsToTake);
  }
}
