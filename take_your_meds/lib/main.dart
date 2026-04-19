import 'dart:async';

import 'package:flutter/material.dart';
import 'package:take_your_meds/time.dart';

import 'db.dart';
import 'home.dart';
import 'notifications.dart';

void main() async {
  await Database.init();
  await Notifications.init();
  Time.init();
  var app = MyApp();
  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Home(
        doses: Database.cachedDoses,
        activeMeds: Database.cachedActiveMeds,
        location: Notifications.location,
      ),
    );
  }
}
