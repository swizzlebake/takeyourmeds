class Time {
  static DateTime getRemindAt(Duration duration) {
    var remindAt = DateTime.now().toUtc().add(duration);
    return remindAt.copyWith(second: 0, millisecond: 0, microsecond: 0);
  }

  static DateTime getRemindAgainAt(DateTime remindAt, Duration duration) {
    return remindAt.add(duration);
  }
}
