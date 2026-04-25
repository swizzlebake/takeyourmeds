import 'package:flutter/material.dart';
import 'package:take_your_meds/home.dart';
import 'dose.dart';
import 'meds.dart';

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
        if (index == currentPageIndex) return;
        setState(() {
          currentPageIndex = index;
        });

        if (currentPageIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
        if (currentPageIndex == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MedsOverview()),
          );
        }
        if (currentPageIndex == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DosePresetsOverview(),
            ),
          );
        }
      },
      indicatorColor: Colors.blueGrey,
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
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
