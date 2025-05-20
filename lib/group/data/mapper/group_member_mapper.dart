// lib/group/data/mapper/group_member_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';

/// GroupMemberDto → GroupMember 변환
extension GroupMemberDtoMapper on GroupMemberDto {
  GroupMember toModel() {
    return GroupMember(
      id: id ?? '',
      userId: userId ?? '',
      userName: userName ?? '',
      profileUrl: profileUrl,
      role: role ?? 'member',
      joinedAt: joinedAt ?? DateTime.now(),
    );
  }
}

/// GroupMember → GroupMemberDto 변환
extension GroupMemberModelMapper on GroupMember {
  GroupMemberDto toDto() {
    return GroupMemberDto(
      id: id,
      userId: userId,
      userName: userName,
      profileUrl: profileUrl,
      role: role,
      joinedAt: joinedAt,
    );
  }
}

/// List<GroupMemberDto> → List<GroupMember> 변환
extension GroupMemberDtoListMapper on List<GroupMemberDto>? {
  List<GroupMember> toModelList() =>
      this?.map((e) => e.toModel()).toList() ?? [];
}

/// List<GroupMember> → List<GroupMemberDto> 변환
extension GroupMemberModelListMapper on List<GroupMember> {
  List<GroupMemberDto> toDtoList() => map((e) => e.toDto()).toList();
}

/// Map<String, dynamic> → GroupMemberDto 변환
extension MapToGroupMemberDtoMapper on Map<String, dynamic> {
  GroupMemberDto toGroupMemberDto() => GroupMemberDto.fromJson(this);
}
