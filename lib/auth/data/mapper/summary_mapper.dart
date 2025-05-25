// lib/auth/data/mapper/summary_mapper.dart
import 'package:devlink_mobile_app/auth/data/dto/summary_dto.dart';
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart'; // 추가: TimerActivityType import

/// SummaryDto -> Summary 변환
extension SummaryDtoMapper on SummaryDto? {
  Summary? toModel() {
    final dto = this;
    if (dto == null) return null;

    return Summary(
      allTimeTotalSeconds: dto.allTimeTotalSeconds ?? 0,
      groupTotalSecondsMap: dto.groupTotalSecondsMap ?? {},
      last7DaysActivityMap: dto.last7DaysActivityMap ?? {},
      currentStreakDays: dto.currentStreakDays ?? 0,
      lastActivityDate: dto.lastActivityDate,
      longestStreakDays: dto.longestStreakDays ?? 0,
      // 추가: 타이머 상태 문자열을 TimerActivityType으로 변환
      lastTimerState:
          dto.lastTimerState != null
              ? _stringToTimerActivityType(dto.lastTimerState!)
              : null,
      lastTimerGroupId: dto.lastTimerGroupId,
      lastTimerTimestamp: dto.lastTimerTimestamp,
    );
  }

  /// 문자열을 TimerActivityType으로 변환하는 내부 헬퍼 메서드
  TimerActivityType? _stringToTimerActivityType(String value) {
    switch (value) {
      case 'start':
        return TimerActivityType.start;
      case 'pause':
        return TimerActivityType.pause;
      case 'resume':
        return TimerActivityType.resume;
      case 'end':
        return TimerActivityType.end;
      default:
        return null;
    }
  }
}

/// Summary -> SummaryDto 변환
extension SummaryMapper on Summary {
  SummaryDto toDto() {
    return SummaryDto(
      allTimeTotalSeconds: allTimeTotalSeconds,
      groupTotalSecondsMap: groupTotalSecondsMap,
      last7DaysActivityMap: last7DaysActivityMap,
      currentStreakDays: currentStreakDays,
      lastActivityDate: lastActivityDate,
      longestStreakDays: longestStreakDays,
      // 추가: TimerActivityType을 문자열로 변환
      lastTimerState: lastTimerState?.toStringValue(),
      lastTimerGroupId: lastTimerGroupId,
      lastTimerTimestamp: lastTimerTimestamp,
    );
  }
}
