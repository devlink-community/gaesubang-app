import 'package:devlink_mobile_app/map/data/dto/group_member_location_dto.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';

extension GroupMemberLocationDtoMapper on GroupMemberLocationDto {
  GroupMemberLocation toModel() {
    return GroupMemberLocation(
      memberId: memberId ?? '',
      nickname: nickname ?? '이름 없음',
      imageUrl: imageUrl ?? '',
      latitude: latitude?.toDouble() ?? 0.0,
      longitude: longitude?.toDouble() ?? 0.0,
      lastUpdated: lastUpdated,
      isOnline: isOnline ?? false,
    );
  }
}

extension GroupMemberLocationDtoListMapper on List<GroupMemberLocationDto>? {
  List<GroupMemberLocation> toModelList() {
    return this?.map((dto) => dto.toModel()).toList() ?? [];
  }
}
