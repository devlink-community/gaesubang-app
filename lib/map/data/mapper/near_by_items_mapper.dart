import 'package:devlink_mobile_app/map/data/dto/near_by_items_dto.dart';
import 'package:devlink_mobile_app/map/data/mapper/map_marker_mapper.dart';
import 'package:devlink_mobile_app/map/domain/model/near_by_items.dart';

extension NearByItemsDtoMapper on NearByItemsDto {
  NearByItems toModel() {
    return NearByItems(
      groups: groups?.toModelList() ?? [],
      users: users?.toModelList() ?? [],
    );
  }
}

extension NearByItemsModelMapper on NearByItems {
  NearByItemsDto toDto() {
    return NearByItemsDto(
      groups: groups.map((group) => group.toDto()).toList(),
      users: users.map((user) => user.toDto()).toList(),
    );
  }
}
