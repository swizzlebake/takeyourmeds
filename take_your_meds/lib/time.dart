import 'dart:async';

class Time {
  static late final Timer _timer;
  static DateTime lastTickTime = DateTime.now();
  static Duration elapsedTime() => DateTime.now().difference(lastTickTime);
  static List<Function> _callbacks = List.empty(growable: true);

  static void init() {
    _timer = Timer.periodic(Duration(seconds: 1), _tick);
  }

  static void registerCallback(Function callback) {
    _callbacks.add(callback);
  }

  static void removeCallback(Function callback) {
    _callbacks.remove(callback);
  }

  static void _tick(Timer timer) {
    for (var callback in _callbacks) {
      callback();
    }
    lastTickTime = DateTime.now();
  }

  static DateTime getRemindAt(Duration duration) {
    return DateTime.now().toUtc().add(duration);
  }

  static DateTime getRemindAgainAt(DateTime remindAt, Duration duration) {
    return remindAt.add(duration);
  }
}
