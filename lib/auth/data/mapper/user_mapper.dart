// lib/auth/data/mapper/user_mapper.dart
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
  /// 타이머 활동이 포함된 데이터를 Member로 변환하고 FocusStats도 계산
  Member toMemberWithCalculatedStats() {
    // 기본 Member 정보 변환
    final member = toMember();

    // 타이머 활동 데이터 처리
    final timerActivitiesData = this['timerActivities'] as List<dynamic>?;

    if (timerActivitiesData != null && timerActivitiesData.isNotEmpty) {
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

    // 타이머 활동이 없는 경우 기본 통계 반환
    return member.copyWith(
      focusStats: const FocusTimeStats(
        totalMinutes: 0,
        weeklyMinutes: {'월': 0, '화': 0, '수': 0, '목': 0, '금': 0, '토': 0, '일': 0},
      ),
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
