// lib/auth/data/mapper/activity_mapper.dart
import '../../domain/model/activity.dart';
import '../dto/activity_dto.dart';

extension ActivityDtoMapper on ActivityDto {
  Activity toModel() {
    return Activity(
      timerStatus:
          timerStatus != null
              ? TimerStatus.fromString(timerStatus!)
              : TimerStatus.end,
      sessionStartedAt: sessionStartedAt,
      lastUpdatedAt: lastUpdatedAt,
      currentSessionElapsedSeconds: currentSessionElapsedSeconds ?? 0,
      todayTotalSeconds: todayTotalSeconds ?? 0,
      dailyDurationsMap: dailyDurationsMap ?? {},
      allTimeTotalSeconds: allTimeTotalSeconds ?? 0,
    );
  }
}

extension ActivityModelMapper on Activity {
  ActivityDto toDto() {
    return ActivityDto(
      timerStatus: timerStatus.value,
      sessionStartedAt: sessionStartedAt,
      lastUpdatedAt: lastUpdatedAt,
      currentSessionElapsedSeconds: currentSessionElapsedSeconds,
      todayTotalSeconds: todayTotalSeconds,
      dailyDurationsMap: dailyDurationsMap,
      allTimeTotalSeconds: allTimeTotalSeconds,
    );
  }
}

// Map에서 직접 Activity로 변환 (Firebase 데이터용)
extension MapToActivityMapper on Map<String, dynamic> {
  Activity toActivity() {
    return Activity(
      timerStatus:
          this['timerStatus'] != null
              ? TimerStatus.fromString(this['timerStatus'] as String)
              : TimerStatus.end,
      sessionStartedAt:
          this['sessionStartedAt'] != null
              ? DateTime.parse(this['sessionStartedAt'] as String)
              : null,
      lastUpdatedAt:
          this['lastUpdatedAt'] != null
              ? DateTime.parse(this['lastUpdatedAt'] as String)
              : null,
      currentSessionElapsedSeconds:
          this['currentSessionElapsedSeconds'] as int? ?? 0,
      todayTotalSeconds: this['todayTotalSeconds'] as int? ?? 0,
      dailyDurationsMap:
          (this['dailyDurationsMap'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      allTimeTotalSeconds: this['allTimeTotalSeconds'] as int? ?? 0,
    );
  }
}

// Activity에서 Firebase Map으로 변환
extension ActivityToMapMapper on Activity {
  Map<String, dynamic> toFirebaseMap() {
    return {
      'timerStatus': timerStatus.value,
      'sessionStartedAt': sessionStartedAt?.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      'currentSessionElapsedSeconds': currentSessionElapsedSeconds,
      'todayTotalSeconds': todayTotalSeconds,
      'dailyDurationsMap': dailyDurationsMap,
      'allTimeTotalSeconds': allTimeTotalSeconds,
    };
  }
}

// List 변환 확장
extension ActivityDtoListMapper on List<ActivityDto>? {
  List<Activity> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}

extension ActivityModelListMapper on List<Activity> {
  List<ActivityDto> toDtoList() => map((e) => e.toDto()).toList();
}
