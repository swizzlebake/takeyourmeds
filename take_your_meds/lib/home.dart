import 'package:flutter/material.dart';
import 'package:take_your_meds/db.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';
import 'package:take_your_meds/navigation.dart';

import 'notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.doses, required this.activeMeds});

  final List<DosePreset> doses;
  final List<ActiveMeds> activeMeds;
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<DosePreset> doses = List.empty(growable: true);
  List<ActiveMeds> activeMeds = List.empty(growable: true);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    doses.addAll(widget.doses);
    activeMeds.addAll(widget.activeMeds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Meds', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ElevatedButton(
                    onPressed: () async {
                      var remindAt = DateTime.now().toUtc().add(
                        Duration(seconds: doses[index].meds.duration),
                      );
                      var remindAtAgain = remindAt.add(Duration(minutes: 10));
                      var meds = ActiveMeds(
                        id: UniqueKey().toString(),
                        dose: doses[index],
                        takenAt: DateTime.now().toUtc(),
                        remindAt: remindAt,
                        remindAgainAt: remindAtAgain,
                      );
                      setState(() {
                        activeMeds.add(meds);
                      });

                      Database.saveActiveMeds(activeMeds);
                      await Notifications.scheduleNotification(meds);
                    },
                    child: Text(
                      '${doses[index].meds.name} ${doses[index].dosage} ${doses[index].range.name}',
                    ),
                  ),
                );
              },
              itemCount: doses.length,
            ),
          ),
          Text('Active Meds', style: TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: Text(
                    '${activeMeds[index].dose.meds.name} ${activeMeds[index].dose.dosage} ${activeMeds[index].remindAt}',
                  ),
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
}
