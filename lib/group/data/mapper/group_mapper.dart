// lib/group/data/mapper/group_mapper.dart
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
      createdBy: createdBy ?? '',
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
      createdBy: createdBy,
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
