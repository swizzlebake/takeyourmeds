import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:take_your_meds/consume.dart';
import 'package:take_your_meds/dose.dart';
import 'package:take_your_meds/meds.dart';
import 'package:take_your_meds/navigation.dart';
import 'package:take_your_meds/providers.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notifications.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(tickProvider).valueOrNull ?? DateTime.now();
    final doses = ref.watch(dosesProvider).valueOrNull ?? [];
    final activeMeds = List<ActiveMeds>.from(
      ref.watch(activeMedsProvider).valueOrNull ?? [],
    )..sort((a, b) => a.takenAt.compareTo(b.takenAt));

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Available Meds ${DateFormat.Hms().format(tz.TZDateTime.from(tick, Notifications.location))}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: doses.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _onPressedDosePreset(context, ref, doses[index]);
                    },
                    child: Text(doses[index].getLabel()),
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onLongPress: () async {
              await _onLongPressActiveMeds(context, ref);
            },
            child: const Text(
              'Active Meds',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              itemCount: activeMeds.length,
              itemBuilder: (BuildContext context, int index) {
                return ActiveMedsWidget(
                  activeMeds: activeMeds[index],
                  location: Notifications.location,
                  onTap: () async => await _onPressedActiveMeds(
                    context,
                    ref,
                    activeMeds[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TYMNavigation(pageIndex: 0),
    );
  }

  Future<void> _onLongPressActiveMeds(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
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
                  const Text(
                    'Clear all?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
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
    if (confirmed == true && context.mounted) {
      await ref.read(activeMedsProvider.notifier).save([]);
    }
  }

  Future<void> _onPressedDosePreset(
    BuildContext context,
    WidgetRef ref,
    DosePreset dose,
  ) async {
    final result = await showDialog<TakeMeds>(
      context: context,
      builder: (BuildContext context) {
        return Consume(
          selectedActiveMedsToTake: ActiveMeds.fromDose(dose, DateTime.now().toUtc()),
          selectedActiveMedsToResolve: null,
        );
      },
    );
    if (result == null || !context.mounted) return;
    await _handleConsumeResult(ref, result);
  }

  Future<void> _onPressedActiveMeds(
    BuildContext context,
    WidgetRef ref,
    ActiveMeds meds,
  ) async {
    final result = await showDialog<TakeMeds>(
      context: context,
      builder: (BuildContext context) {
        return Consume(
          selectedActiveMedsToTake: null,
          selectedActiveMedsToResolve: meds,
        );
      },
    );
    if (result == null || !context.mounted) return;
    await _handleConsumeResult(ref, result);
  }

  Future<void> _handleConsumeResult(WidgetRef ref, TakeMeds takeMeds) async {
    if (takeMeds.action == TakeMedsAction.startActiveMeds) {
      final current = List<ActiveMeds>.from(
        ref.read(activeMedsProvider).valueOrNull ?? [],
      );
      current.add(takeMeds.medsToTake);
      current.remove(takeMeds.medsToResolve);
      await ref.read(activeMedsProvider.notifier).save(current);
    }
    await Notifications.scheduleAlarm(takeMeds.medsToTake);
  }
}
