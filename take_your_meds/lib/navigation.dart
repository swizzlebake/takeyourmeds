import 'package:flutter/material.dart';
import 'package:take_your_meds/home.dart';
import 'db.dart';
import 'meds.dart';
import 'dose.dart';

class TYMNavigation extends StatefulWidget {
  const TYMNavigation({super.key, required this.pageIndex});
  final int pageIndex;

  @override
  State<StatefulWidget> createState() => _TYMNavigationState();
}

class _TYMNavigationState extends State<TYMNavigation> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.pageIndex;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: (int index) {
        if (index == currentPageIndex) {
          return;
        }
        setState(() {
          currentPageIndex = index;
        });

        if (currentPageIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Home(
                doses: Database.cachedDoses,
                activeMeds: Database.cachedActiveMeds,
              ),
            ),
          );
        }
        if (currentPageIndex == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedsOverview(meds: Database.cachedMeds),
            ),
          );
        }
        if (currentPageIndex == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DosePresetsOverview(
                meds: Database.cachedMeds,
                doses: Database.cachedDoses,
              ),
            ),
          );
        }
      },
      indicatorColor: Colors.blueGrey,
      selectedIndex: currentPageIndex,
      destinations: <Widget>[
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.two_mp_rounded), label: 'Meds'),
        NavigationDestination(
          icon: Icon(Icons.doorbell_outlined),
          label: 'Presets',
        ),
      ],
    );
  }
}
