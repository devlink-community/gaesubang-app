// lib/group/data/mapper/user_streak_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/user_streak_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/user_streak.dart';

/// UserStreakDto → UserStreak 변환
extension UserStreakDtoMapper on UserStreakDto {
  UserStreak toModel() {
    return UserStreak(
      maxStreakDays: maxStreakDays ?? 0,
      bestGroupId: bestGroupId,
      bestGroupName: bestGroupName,
      lastActiveDate: lastActiveDate ?? DateTime.now(),
    );
  }
}

/// UserStreak → UserStreakDto 변환
extension UserStreakModelMapper on UserStreak {
  UserStreakDto toDto() {
    return UserStreakDto(
      maxStreakDays: maxStreakDays,
      bestGroupId: bestGroupId,
      bestGroupName: bestGroupName,
      lastActiveDate: lastActiveDate,
    );
  }
}

/// Map<String, dynamic> → UserStreakDto 변환
extension MapToUserStreakDtoMapper on Map<String, dynamic> {
  UserStreakDto toUserStreakDto() => UserStreakDto.fromJson(this);
}
