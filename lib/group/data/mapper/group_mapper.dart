import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';

// HashTag DTO → Model 변환
extension HashTagDtoMapper on HashTagDto {
  HashTag toModel() {
    return HashTag(id: id ?? '', content: content ?? '');
  }
}

// Member DTO → Model 변환
extension MemberDtoMapper on MemberDto {
  Member toModel() {
    return Member(
      id: id ?? '',
      email: email ?? '',
      nickname: nickname ?? '',
      uid: uid ?? '',
      image: image ?? '',
      onAir: onAir ?? false,
    );
  }
}

// Group DTO → Model 변환
extension GroupDtoMapper on GroupDto {
  Group toModel() {
    // 기본 소유자 생성 (DTO에서 owner가 null인 경우 사용)
    final defaultOwner = Member(
      id: '',
      email: '',
      nickname: 'Unknown Owner',
      uid: '',
    );

    return Group(
      id: id ?? '',
      name: name ?? '',
      description: description ?? '',
      members: members?.map((dto) => dto.toModel()).toList() ?? [],
      hashTags: hashTags?.map((dto) => dto.toModel()).toList() ?? [],
      limitMemberCount: limitMemberCount?.toInt() ?? 0,
      owner: owner?.toModel() ?? defaultOwner,
      imageUrl: imageUrl,
      createdAt: _parseDateTime(createdAt),
      updatedAt: _parseDateTime(updatedAt),
    );
  }
}

DateTime _parseDateTime(String? dateTimeStr) {
  if (dateTimeStr == null) return DateTime.now();
  try {
    return DateTime.parse(dateTimeStr);
  } catch (_) {
    return DateTime.now();
  }
}

// HashTag Model → DTO 변환
extension HashTagModelMapper on HashTag {
  HashTagDto toDto() {
    return HashTagDto(id: id, content: content);
  }
}

// Member Model → DTO 변환
extension MemberModelMapper on Member {
  MemberDto toDto() {
    return MemberDto(
      id: id,
      email: email,
      nickname: nickname,
      uid: uid,
      image: image,
      onAir: onAir,
    );
  }
}

// Group Model → DTO 변환
extension GroupModelMapper on Group {
  GroupDto toDto() {
    return GroupDto(
      id: id,
      name: name,
      description: description,
      members: members.map((model) => model.toDto()).toList(),
      hashTags: hashTags.map((model) => model.toDto()).toList(),
      limitMemberCount: limitMemberCount,
      owner: owner.toDto(),
      imageUrl: imageUrl,
    );
  }
}

// List<GroupDto> → List<Group> 변환
extension GroupDtoListMapper on List<GroupDto> {
  List<Group> toModelList() => map((e) => e.toModel()).toList();
}

// List<HashTagDto> → List<HashTag> 변환
extension HashTagDtoListMapper on List<HashTagDto> {
  List<HashTag> toModelList() => map((e) => e.toModel()).toList();
}
