import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:take_your_meds/meds.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  static final AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('app_icon');
  static final LinuxInitializationSettings linuxInitializationSettings =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  static late FlutterLocalNotificationsPlugin plugin;
  static InitializationSettings initializationSettings() =>
      InitializationSettings(
        android: androidInitializationSettings,
        linux: linuxInitializationSettings,
      );

  static Future<void> init() async {
    plugin = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    final android = AndroidFlutterLocalNotificationsPlugin();
    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();

    await plugin.initialize(
      initializationSettings(),
      onDidReceiveNotificationResponse: (NotificationResponse notification) =>
          print('woo'),
    );
  }

  static Future<String?> getLinuxTimeZoneName() async {
    final timezoneFile = File('/etc/timezone');
    if (await timezoneFile.exists()) {
      final content = await timezoneFile.readAsString();
      final tzName = content.trim();
      if (tzName.isNotEmpty) {
        return tzName;
      }

      final timeZoneLink = File('/etc/localtime');
      try {
        final resolved = await timeZoneLink.resolveSymbolicLinks();
        const zoneInfoPrefix = 'usr/share/zoneinfo/';
        final index = resolved.indexOf(zoneInfoPrefix);
        if (index != -1) {
          return resolved.substring(index + zoneInfoPrefix.length);
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> scheduleNotification(ActiveMeds meds) async {
    String timeZoneName = '';
    if (Platform.isAndroid) {
      var timezone = await FlutterTimezone.getLocalTimezone();
      timeZoneName = timezone.identifier;
    } else if (Platform.isLinux) {
      var name = await getLinuxTimeZoneName();
      if (name != null) {
        timeZoneName = name;
      }
    }
    var scheduledDate = tz.TZDateTime.from(
      meds.remindAt,
      tz.getLocation(timeZoneName),
    );
    var notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'tym',
        'tym',
        channelDescription: 'take your meds',
        icon: 'app_icon'
      ),
      linux: LinuxNotificationDetails(category: LinuxNotificationCategory.im),
    );
    plugin.zonedSchedule(
      0,
      'Take Your Meds!',
      'It\'s time to take your meds!',
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }
}
