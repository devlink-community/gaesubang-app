// lib/auth/data/mapper/user_mapper.dart
import '../../domain/model/member.dart';
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
