// lib/auth/data/mapper/user_mapper.dart
import 'package:flutter/cupertino.dart';

import '../../../core/utils/focus_stats_calculator.dart';
import '../../../profile/domain/model/focus_time_stats.dart';
import '../../domain/model/member.dart';
import '../../domain/model/terms_agreement.dart';
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

    // 🚀 1. Firebase User 문서에 저장된 통계 확인
    final firebaseTotalMinutes = this['totalFocusMinutes'] as int? ?? 0;
    final firebaseWeeklyMinutes = this['weeklyFocusMinutes'] as int? ?? 0;
    final firebaseStreakDays = this['streakDays'] as int? ?? 0;

    // 🚀 2. Firebase 통계가 있으면 우선 사용
    if (firebaseTotalMinutes > 0 ||
        firebaseWeeklyMinutes > 0 ||
        firebaseStreakDays > 0) {
      debugPrint('🚀 Firebase 저장된 통계 사용:');
      debugPrint('  - totalFocusMinutes: $firebaseTotalMinutes');
      debugPrint('  - weeklyFocusMinutes: $firebaseWeeklyMinutes');
      debugPrint('  - streakDays: $firebaseStreakDays');

      final focusStats = _createFocusStatsFromFirebaseData(
        totalMinutes: firebaseTotalMinutes,
        weeklyMinutes: firebaseWeeklyMinutes,
      );

      return member.copyWith(
        focusStats: focusStats,
        totalFocusMinutes: firebaseTotalMinutes,
        weeklyFocusMinutes: firebaseWeeklyMinutes,
        streakDays: firebaseStreakDays,
        lastStatsUpdated: _parseTimestamp(this['lastStatsUpdated']),
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

      // FocusStats 계산
      final focusStats = FocusStatsCalculator.calculateFromActivities(
        activities,
      );

      // Member에 FocusStats 포함
      return member.copyWith(focusStats: focusStats);
    }

    // 🚀 4. 둘 다 없으면 기본 통계 반환
    debugPrint('🚀 기본 통계 반환 (데이터 없음)');
    return member.copyWith(
      focusStats: const FocusTimeStats(
        totalMinutes: 0,
        weeklyMinutes: {'월': 0, '화': 0, '수': 0, '목': 0, '금': 0, '토': 0, '일': 0},
      ),
    );
  }

  /// 🚀 Firebase 통계 데이터로 FocusTimeStats 생성
  FocusTimeStats _createFocusStatsFromFirebaseData({
    required int totalMinutes,
    required int weeklyMinutes,
  }) {
    // 요일별 분배 (간단한 균등 분배)
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weeklyMinutesMap = <String, int>{};

    if (weeklyMinutes > 0) {
      final avgPerDay = weeklyMinutes ~/ 7;
      final remainder = weeklyMinutes % 7;

      for (int i = 0; i < weekdays.length; i++) {
        weeklyMinutesMap[weekdays[i]] = avgPerDay + (i < remainder ? 1 : 0);
      }
    } else {
      for (final day in weekdays) {
        weeklyMinutesMap[day] = 0;
      }
    }

    return FocusTimeStats(
      totalMinutes: totalMinutes,
      weeklyMinutes: weeklyMinutesMap,
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
    // 🚀 1. Firebase 통계 먼저 확인
    final firebaseTotalMinutes = this['totalFocusMinutes'] as int? ?? 0;
    final firebaseWeeklyMinutes = this['weeklyFocusMinutes'] as int? ?? 0;

    if (firebaseTotalMinutes > 0 || firebaseWeeklyMinutes > 0) {
      return _createFocusStatsFromFirebaseData(
        totalMinutes: firebaseTotalMinutes,
        weeklyMinutes: firebaseWeeklyMinutes,
      );
    }

    // 🚀 2. Firebase 통계가 없으면 타이머 활동에서 계산
    final timerActivitiesData = this['timerActivities'] as List<dynamic>?;

    if (timerActivitiesData == null || timerActivitiesData.isEmpty) {
      return const FocusTimeStats(
        totalMinutes: 0,
        weeklyMinutes: {'월': 0, '화': 0, '수': 0, '목': 0, '금': 0, '토': 0, '일': 0},
      );
    }

    final activities =
        timerActivitiesData
            .map(
              (activity) =>
                  TimerActivityDto.fromJson(activity as Map<String, dynamic>),
            )
            .toList();

    return FocusStatsCalculator.calculateFromActivities(activities);
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
}
