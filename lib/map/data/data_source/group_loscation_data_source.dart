// lib/group/data/data_source/group_location_data_source.dart

import 'package:devlink_mobile_app/map/data/dto/group_member_location_dto.dart';

abstract interface class GroupLocationDataSource {
  /// 멤버 위치 업데이트
  Future<void> updateMemberLocation(
    String groupId,
    String memberId,
    double latitude,
    double longitude,
  );

  /// 그룹 멤버 위치 정보 조회
  Future<List<GroupMemberLocationDto>> getGroupMemberLocations(String groupId);

  /// 실시간 그룹 멤버 위치 스트림
  Stream<List<GroupMemberLocationDto>> streamGroupMemberLocations(
    String groupId,
  );
}
