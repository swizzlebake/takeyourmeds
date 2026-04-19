import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:take_your_meds/meds.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/tzdata.dart';

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

  static late tz.Location location;

  static Future<void> init() async {
    plugin = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    if (Platform.isAndroid) {
      final android = AndroidFlutterLocalNotificationsPlugin();
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    await plugin.initialize(
      settings: initializationSettings(),
      onDidReceiveNotificationResponse: (NotificationResponse notification) =>
          print('woo'),
    );

    location = await getLocation();

    await Alarm.init();
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

  static Future<void> scheduleAlarm(ActiveMeds meds) async {
    var scheduledDate = await getScheduledDate(meds);
    final alarmSettings = AlarmSettings(
      id: 1985,
      dateTime: scheduledDate,
      volumeSettings: VolumeSettings.fixed(volume: 0.5, volumeEnforced: false),
      loopAudio: true,
      vibrate: true,
      androidStopAlarmOnTermination: false,
      notificationSettings: NotificationSettings(
        title: 'Take Your Meds',
        body: 'It\'s time to take your meds!',
        stopButton: 'Take Meds',
        icon: 'app_icon',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> scheduleNotification(ActiveMeds meds) async {
    var scheduledDate = await getScheduledDate(meds);
    var notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'tym',
        'tym',
        channelDescription: 'take your meds',
        icon: 'app_icon',
      ),
      linux: LinuxNotificationDetails(category: LinuxNotificationCategory.im),
    );
    if (Platform.isAndroid) {
      plugin.zonedSchedule(
        id: 0,
        title: 'Take Your Meds!',
        payload: 'It\'s time to take your meds!',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exact,
      );
    }
  }

  static Future<tz.TZDateTime> getScheduledDate(ActiveMeds meds) async {
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
    return scheduledDate;
  }

  static Future<String> getTimeZoneName() async {
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

    return timeZoneName;
  }

  static Future<tz.Location> getLocation() async {
    var name = await getTimeZoneName();
    return tz.getLocation(name);
  }
}
