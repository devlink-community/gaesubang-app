// lib/group/data/mapper/group_mapper.dart
import 'package:devlink_mobile_app/auth/data/dto/joined_group_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';

/// GroupDto → Group 변환
extension GroupDtoMapper on GroupDto {
  Group toModel() {
    return Group(
      id: id ?? '',
      name: name ?? '',
      description: description ?? '',
      imageUrl: imageUrl,
      createdAt: createdAt ?? DateTime.now(),
      ownerId: ownerId ?? '', // createdBy → ownerId로 변경
      ownerNickname: ownerNickname, // 추가 필드
      ownerProfileImage: ownerProfileImage, // 추가 필드
      maxMemberCount: maxMemberCount ?? 10,
      hashTags: hashTags ?? [],
      memberCount: memberCount ?? 0,
      isJoinedByCurrentUser: isJoinedByCurrentUser ?? false,
    );
  }
}

/// Group → GroupDto 변환
extension GroupModelMapper on Group {
  GroupDto toDto() {
    return GroupDto(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      createdAt: createdAt,
      ownerId: ownerId, // createdBy → ownerId로 변경
      ownerNickname: ownerNickname, // 추가 필드
      ownerProfileImage: ownerProfileImage, // 추가 필드
      maxMemberCount: maxMemberCount,
      hashTags: hashTags,
      memberCount: memberCount,
      isJoinedByCurrentUser: isJoinedByCurrentUser,
    );
  }
}

/// List<GroupDto> → List<Group> 변환
extension GroupDtoListMapper on List<GroupDto>? {
  List<Group> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}

/// List<Group> → List<GroupDto> 변환
extension GroupModelListMapper on List<Group> {
  List<GroupDto> toDtoList() => map((e) => e.toDto()).toList();
}

/// Map<String, dynamic> → GroupDto 변환
extension MapToGroupDtoMapper on Map<String, dynamic> {
  GroupDto toGroupDto() => GroupDto.fromJson(this);
}

/// JoinedGroupDto → Group 변환 (간소화된 버전)
extension JoinedGroupDtoToGroupMapper on JoinedGroupDto {
  Group toGroupModel() {
    return Group(
      id: groupId ?? '',
      name: groupName ?? '',
      description: '', // 간소화된 버전이므로 기본값 사용
      imageUrl: groupImage,
      createdAt: DateTime.now(), // 실제 생성일은 알 수 없으므로 현재 시간 사용
      ownerId: '', // 간소화된 버전이므로 빈 값 사용
      maxMemberCount: 10, // 기본값 사용
      hashTags: const [], // 빈 리스트 사용
      memberCount: 0, // 기본값 사용
      isJoinedByCurrentUser: true, // 이미 가입된 그룹이므로 true
    );
  }
}

/// List<JoinedGroupDto> → List<Group> 변환
extension JoinedGroupDtoListToGroupListMapper on List<JoinedGroupDto>? {
  List<Group> toGroupModelList() =>
      this?.map((e) => e.toGroupModel()).toList() ?? [];
}
