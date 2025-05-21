import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';

abstract interface class GroupLocationRepository {
  /// 그룹 멤버의 위치 정보 업데이트
  Future<Result<void>> updateMemberLocation(
    String groupId,
    String memberId,
    double latitude,
    double longitude,
  );

  /// 그룹 멤버들의 위치 정보 조회
  Future<Result<List<GroupMemberLocation>>> getGroupMemberLocations(
    String groupId,
  );

  /// 위치 업데이트 리스너 시작
  /// 이 메서드는 Stream을 반환하여 실시간 위치 업데이트를 받을 수 있게 합니다.
  Stream<List<GroupMemberLocation>> streamGroupMemberLocations(String groupId);
}
