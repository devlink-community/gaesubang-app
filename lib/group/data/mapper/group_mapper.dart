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

/// 🔧 Map<String, dynamic> → GroupDto 변환 (isJoinedByCurrentUser 보존)
extension MapToGroupDtoMapper on Map<String, dynamic> {
  GroupDto toGroupDto() {
    // 기본 DTO 생성
    final dto = GroupDto.fromJson(this);

    // isJoinedByCurrentUser 직접 추출하여 설정
    final isJoined = this['isJoinedByCurrentUser'] as bool? ?? false;

    return dto.copyWith(isJoinedByCurrentUser: isJoined);
  }
}

/// 🔧 Map 리스트를 Group 리스트로 직접 변환 (Repository에서 사용)
extension MapListToGroupListMapper on List<Map<String, dynamic>>? {
  List<Group> toGroupModelList() {
    if (this == null || this!.isEmpty) return [];

    return this!.map((data) {
      // isJoinedByCurrentUser 직접 추출
      final isJoined = data['isJoinedByCurrentUser'] as bool? ?? false;

      // GroupDto 생성
      final dto = GroupDto.fromJson(data);

      // Group 모델 생성 시 isJoinedByCurrentUser 직접 설정
      return Group(
        id: dto.id ?? '',
        name: dto.name ?? '',
        description: dto.description ?? '',
        imageUrl: dto.imageUrl,
        createdAt: dto.createdAt ?? DateTime.now(),
        ownerId: dto.ownerId ?? '',
        ownerNickname: dto.ownerNickname,
        ownerProfileImage: dto.ownerProfileImage,
        maxMemberCount: dto.maxMemberCount ?? 10,
        hashTags: dto.hashTags ?? [],
        memberCount: dto.memberCount ?? 0,
        isJoinedByCurrentUser: isJoined, // 🔧 원본 데이터에서 직접 가져온 값 사용
      );
    }).toList();
  }
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
