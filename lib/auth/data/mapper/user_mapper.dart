// lib/auth/data/mapper/user_mapper.dart
import '../../domain/model/member.dart';
import '../../domain/model/terms_agreement.dart';
import '../dto/joined_group_dto.dart';

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
