class Setting<T> {
  Setting({required this.defaultValue, required this.currentValue});
  Setting.fromDefault({required this.defaultValue}) {
    currentValue = defaultValue;
  }
  final T defaultValue;
  late T currentValue;
}

class Settings {
  // After this percentage an active med will appear in the list of meds to re-take
  static Setting cancelWarningWithConsumePercentage = Setting.fromDefault(
    defaultValue: 0.5,
  );

  // How long we wait between a remindAt and a remindAtAgain
  static Setting remindAgainAtFrequencyInMins = Setting.fromDefault(
    defaultValue: 5.0,
  );
}
