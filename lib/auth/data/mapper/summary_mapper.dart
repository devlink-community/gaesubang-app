// lib/auth/data/mapper/summary_mapper.dart
import '../../domain/model/summary.dart';
import '../dto/summary_dto.dart';

extension SummaryDtoMapper on SummaryDto {
  Summary toModel() {
    return Summary(
      allTimeTotalSeconds: allTimeTotalSeconds ?? 0,
      groupTotalSecondsMap: groupTotalSecondsMap ?? {},
      last7DaysActivityMap: last7DaysActivityMap ?? {},
      currentStreakDays: currentStreakDays ?? 0,
      lastActivityDate: lastActivityDate,
      longestStreakDays: longestStreakDays ?? 0,
    );
  }
}

extension SummaryModelMapper on Summary {
  SummaryDto toDto() {
    return SummaryDto(
      allTimeTotalSeconds: allTimeTotalSeconds,
      groupTotalSecondsMap: groupTotalSecondsMap,
      last7DaysActivityMap: last7DaysActivityMap,
      currentStreakDays: currentStreakDays,
      lastActivityDate: lastActivityDate,
      longestStreakDays: longestStreakDays,
    );
  }
}

// Map에서 직접 Summary로 변환 (Firebase 데이터용)
extension MapToSummaryMapper on Map<String, dynamic> {
  Summary toSummary() {
    return Summary(
      allTimeTotalSeconds: this['allTimeTotalSeconds'] as int? ?? 0,
      groupTotalSecondsMap:
          (this['groupTotalSecondsMap'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      last7DaysActivityMap:
          (this['last7DaysActivityMap'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      currentStreakDays: this['currentStreakDays'] as int? ?? 0,
      lastActivityDate: this['lastActivityDate'] as String?,
      longestStreakDays: this['longestStreakDays'] as int? ?? 0,
    );
  }
}

// Summary에서 Firebase Map으로 변환
extension SummaryToMapMapper on Summary {
  Map<String, dynamic> toFirebaseMap() {
    return {
      'allTimeTotalSeconds': allTimeTotalSeconds,
      'groupTotalSecondsMap': groupTotalSecondsMap,
      'last7DaysActivityMap': last7DaysActivityMap,
      'currentStreakDays': currentStreakDays,
      'lastActivityDate': lastActivityDate,
      'longestStreakDays': longestStreakDays,
    };
  }
}
