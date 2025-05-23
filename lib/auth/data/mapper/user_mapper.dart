// lib/auth/data/mapper/user_mapper.dart
import 'package:flutter/cupertino.dart';

import '../../../core/utils/focus_stats_calculator.dart';
import '../../../profile/domain/model/focus_time_stats.dart';
import '../../domain/model/member.dart';
import '../../domain/model/terms_agreement.dart';
import '../../domain/model/user_focus_stats.dart'; // 🆕 UserFocusStats 임포트 추가
import '../dto/joined_group_dto.dart';
import '../dto/timer_activity_dto.dart';

// Map → Member 직접 변환 (Firebase/Mock 데이터 → Member)
extension MapToMemberMapper on Map<String, dynamic> {
  Member toMember() {
    // joingroup 데이터 안전하게 처리 (있으면 사용, 없으면 빈 배열)
    final joinedGroupsData = this['joingroup'] as List<dynamic>?;
    final joinedGroups =
        joinedGroupsData?.map((item) {
          final groupData = item as Map<String, dynamic>;
          return JoinedGroupDto(
            groupId: groupData['group_id'] as String?,
            groupName: groupData['group_name'] as String?,
            groupImage: groupData['group_image'] as String?,
          );
        }).toList() ??
        <JoinedGroupDto>[];

    return Member(
      id: this['uid'] as String? ?? '',
      email: this['email'] as String? ?? '',
      nickname: this['nickname'] as String? ?? '',
      uid: this['uid'] as String? ?? '',
      image: this['image'] as String? ?? '',
      onAir: this['onAir'] as bool? ?? false,
      description: this['description'] as String? ?? '',
      position: this['position'] as String? ?? '',
      skills: this['skills'] as String? ?? '',
      streakDays: this['streakDays'] as int? ?? 0,
      agreedTermsId: this['agreedTermId'] as String?,
      joinedGroups: joinedGroups,
    );
  }
}

// Map → Member + FocusStats 변환 (타이머 활동 포함된 데이터 → Member + Stats)
extension MapToMemberWithStatsMapper on Map<String, dynamic> {
  /// 🚀 Firebase User 문서에 저장된 통계를 우선 사용하는 변환
  Member toMemberWithCalculatedStats() {
    // 기본 Member 정보 변환
    final member = toMember();

    // 🚀 1. Firebase User 문서에 저장된 통계 데이터 확인
    final userFocusStats = _extractUserFocusStats();

    // 🚀 2. UserFocusStats가 유효하면 FocusTimeStats로 변환
    if (userFocusStats.hasValidData) {
      debugPrint('🚀 Firebase 저장된 통계 사용:');
      debugPrint('  - totalFocusMinutes: ${userFocusStats.totalFocusMinutes}');
      debugPrint(
        '  - weeklyFocusMinutes: ${userFocusStats.weeklyFocusMinutes}',
      );
      debugPrint('  - streakDays: ${userFocusStats.streakDays}');
      debugPrint(
        '  - dailyFocusMinutes: ${userFocusStats.dailyFocusMinutes.length}개 항목',
      );

      // UserFocusStats를 FocusTimeStats로 변환
      final focusStats = userFocusStats.toFocusTimeStats();

      // 디버그 출력 추가
      debugPrint('🚀 변환된 FocusTimeStats:');
      debugPrint('  - totalMinutes: ${focusStats.totalMinutes}');
      debugPrint('  - weeklyMinutes: ${focusStats.weeklyMinutes}');
      debugPrint('  - dailyMinutes: ${focusStats.dailyMinutes.length}개 항목');

      // 상세 로그 추가
      focusStats.weeklyMinutes.forEach((day, minutes) {
        debugPrint('    > $day: ${minutes}분');
      });

      return member.copyWith(
        focusStats: focusStats,
        totalFocusMinutes: userFocusStats.totalFocusMinutes,
        weeklyFocusMinutes: userFocusStats.weeklyFocusMinutes,
        streakDays: userFocusStats.streakDays,
        lastStatsUpdated: userFocusStats.lastUpdated,
      );
    }

    // 🚀 3. Firebase 통계가 없으면 타이머 활동에서 계산 (기존 방식)
    final timerActivitiesData = this['timerActivities'] as List<dynamic>?;

    if (timerActivitiesData != null && timerActivitiesData.isNotEmpty) {
      debugPrint('🚀 타이머 활동 데이터에서 통계 계산');

      // List<Map> → List<TimerActivityDto> 변환
      final activities =
          timerActivitiesData
              .map(
                (activity) =>
                    TimerActivityDto.fromJson(activity as Map<String, dynamic>),
              )
              .toList();

      // FocusStats 계산 - 일별 데이터도 포함하도록 수정
      final focusStats = FocusStatsCalculator.calculateFromActivitiesWithDaily(
        activities,
      );

      // Member에 FocusStats 포함
      return member.copyWith(focusStats: focusStats);
    }

    // 🚀 4. 둘 다 없으면 기본 통계 반환
    debugPrint('🚀 기본 통계 반환 (데이터 없음)');
    return member.copyWith(
      focusStats: FocusTimeStats.empty(),
    );
  }

  /// 🚀 Firebase 통계 데이터에서 UserFocusStats 객체 추출
  UserFocusStats _extractUserFocusStats() {
    // 1. Firebase 저장된 통계 기본 필드
    final totalFocusMinutes = this['totalFocusMinutes'] as int? ?? 0;
    final weeklyFocusMinutes = this['weeklyFocusMinutes'] as int? ?? 0;
    final streakDays = this['streakDays'] as int? ?? 0;

    // 2. 일별 데이터 추출
    final rawDailyData = this['dailyFocusMinutes'];
    final dailyFocusMinutes = <String, int>{};

    if (rawDailyData != null && rawDailyData is Map) {
      debugPrint('🔍 일별 데이터 발견! ${rawDailyData.length}개 항목');
      rawDailyData.forEach((key, value) {
        if (value is num) {
          dailyFocusMinutes[key.toString()] = value.toInt();
          debugPrint('  → $key: ${value.toInt()}분');
        }
      });
    } else {
      debugPrint('⚠️ 일별 데이터가 없거나 유효하지 않음: $rawDailyData');
    }

    // 3. lastStatsUpdated 처리
    final lastStatsUpdated = _parseTimestamp(this['lastStatsUpdated']);

    // 4. UserFocusStats 객체 생성
    return UserFocusStats(
      totalFocusMinutes: totalFocusMinutes,
      weeklyFocusMinutes: weeklyFocusMinutes,
      streakDays: streakDays,
      lastUpdated: lastStatsUpdated,
      dailyFocusMinutes: dailyFocusMinutes,
    );
  }

  /// 타이머 활동 데이터만 추출하여 TimerActivityDto 리스트로 변환
  List<TimerActivityDto> toTimerActivityList() {
    final timerActivitiesData = this['timerActivities'] as List<dynamic>?;

    if (timerActivitiesData == null) return [];

    return timerActivitiesData
        .map(
          (activity) =>
              TimerActivityDto.fromJson(activity as Map<String, dynamic>),
        )
        .toList();
  }

  /// 별도의 FocusStats만 계산 (캐싱된 Member가 있을 때 통계만 업데이트하는 경우)
  FocusTimeStats? toFocusStats() {
    // 🚀 1. UserFocusStats 추출
    final userFocusStats = _extractUserFocusStats();

    // 🚀 2. 유효한 데이터가 있으면 FocusTimeStats로 변환
    if (userFocusStats.hasValidData) {
      return userFocusStats.toFocusTimeStats();
    }

    // 🚀 3. Firebase 통계가 없으면 타이머 활동에서 계산
    final timerActivitiesData = this['timerActivities'] as List<dynamic>?;

    if (timerActivitiesData == null || timerActivitiesData.isEmpty) {
      return FocusTimeStats.empty();
    }

    final activities =
        timerActivitiesData
            .map(
              (activity) =>
                  TimerActivityDto.fromJson(activity as Map<String, dynamic>),
            )
            .toList();

    return FocusStatsCalculator.calculateFromActivitiesWithDaily(activities);
  }
}

// Member → Map 변환 (Member → Firebase 데이터)
extension MemberToFirebaseMapMapper on Member {
  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'image': image,
      'onAir': onAir,
      'description': description,
      'position': position ?? '',
      'skills': skills ?? '',
      'streakDays': streakDays,
      'agreedTermId': agreedTermsId,
      'joingroup':
          joinedGroups
              .map(
                (group) => {
                  'group_name': group.groupName,
                  'group_image': group.groupImage,
                },
              )
              .toList(),
    };
  }
}

// TermsAgreement → Map 변환 (TermsAgreement → UserDto 필드들)
extension TermsAgreementToMapMapper on TermsAgreement {
  Map<String, dynamic> toUserDtoMap() {
    return {
      'agreedTermId': id,
      'isServiceTermsAgreed': isServiceTermsAgreed,
      'isPrivacyPolicyAgreed': isPrivacyPolicyAgreed,
      'isMarketingAgreed': isMarketingAgreed,
      'agreedAt': agreedAt,
    };
  }
}

// Map → TermsAgreement 변환 (UserDto 필드들 → TermsAgreement)
extension MapToTermsAgreementMapper on Map<String, dynamic> {
  TermsAgreement toTermsAgreement() {
    return TermsAgreement(
      id:
          this['agreedTermId'] as String? ??
          'terms_${DateTime.now().millisecondsSinceEpoch}',
      isAllAgreed:
          (this['isServiceTermsAgreed'] as bool? ?? false) &&
          (this['isPrivacyPolicyAgreed'] as bool? ?? false),
      isServiceTermsAgreed: this['isServiceTermsAgreed'] as bool? ?? false,
      isPrivacyPolicyAgreed: this['isPrivacyPolicyAgreed'] as bool? ?? false,
      isMarketingAgreed: this['isMarketingAgreed'] as bool? ?? false,
      agreedAt: _parseTimestamp(this['agreedAt']),
    );
  }
}

// 안전한 Timestamp 파싱 헬퍼
DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return null;

  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  // Firebase Timestamp 처리 (import 필요시)
  if (timestamp.toString().contains('Timestamp')) {
    try {
      // Firebase Timestamp의 toDate() 메서드 호출
      return (timestamp as dynamic).toDate() as DateTime?;
    } catch (e) {
      return null;
    }
  }

  return null;
}
