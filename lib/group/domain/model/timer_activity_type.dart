// lib/group/domain/model/timer_activity_type.dart
enum TimerActivityType {
  start('start'),
  pause('pause'),
  resume('resume'),
  end('end');

  final String value;
  const TimerActivityType(this.value);

  static TimerActivityType fromString(String value) {
    return TimerActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid timer activity type: $value'),
    );
  }
}
