// lib/group/data/repository_impl/group_location_repository_impl.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/data/data_source/group_location_data_source.dart';
import 'package:devlink_mobile_app/map/data/mapper/group_member_location_dto_mapper.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:devlink_mobile_app/map/domain/repository/group_location_repository.dart';

class GroupLocationRepositoryImpl implements GroupLocationRepository {
  final GroupLocationDataSource _dataSource;

  GroupLocationRepositoryImpl({required GroupLocationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<void>> updateMemberLocation(
    String groupId,
    String memberId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _dataSource.updateMemberLocation(
        groupId,
        memberId,
        latitude,
        longitude,
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<List<GroupMemberLocation>>> getGroupMemberLocations(
    String groupId,
  ) async {
    try {
      final locationsDto = await _dataSource.getGroupMemberLocations(groupId);
      final locations = locationsDto.toModelList(); // 이제 이 확장 메서드를 인식함
      return Result.success(locations);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Stream<List<GroupMemberLocation>> streamGroupMemberLocations(String groupId) {
    return _dataSource
        .streamGroupMemberLocations(groupId)
        .map((locationsDto) => locationsDto.toModelList()); // 이제 이 확장 메서드를 인식함
  }
}
