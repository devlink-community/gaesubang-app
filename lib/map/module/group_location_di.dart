// lib/group/module/group_location_di.dart
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:devlink_mobile_app/map/data/data_source/group_location_data_source_impl.dart';
import 'package:devlink_mobile_app/map/data/data_source/group_loscation_data_source.dart';
import 'package:devlink_mobile_app/map/data/data_source/mock_group_location_data_source.dart';
import 'package:devlink_mobile_app/map/data/repository_impl/group_location_repository_impl.dart';
import 'package:devlink_mobile_app/map/domain/repository/group_location_repository.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_group_location_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/update_member_location_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_location_di.g.dart';

@riverpod
GroupLocationDataSource groupLocationDataSource(
  GroupLocationDataSourceRef ref,
) {
  // 실제 데이터 소스 대신 Mock 데이터 소스 사용
  return MockGroupLocationDataSource();
}

@riverpod
GroupLocationRepository groupLocationRepository(
  GroupLocationRepositoryRef ref,
) {
  return GroupLocationRepositoryImpl(
    dataSource: ref.watch(groupLocationDataSourceProvider),
  );
}

@riverpod
GetGroupLocationsUseCase getGroupLocationsUseCase(
  GetGroupLocationsUseCaseRef ref,
) {
  return GetGroupLocationsUseCase(
    repository: ref.watch(groupLocationRepositoryProvider),
  );
}

@riverpod
UpdateMemberLocationUseCase updateMemberLocationUseCase(
  UpdateMemberLocationUseCaseRef ref,
) {
  return UpdateMemberLocationUseCase(
    repository: ref.watch(groupLocationRepositoryProvider),
  );
}
