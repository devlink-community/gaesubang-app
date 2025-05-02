import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/mock_group_data_source_impl.dart';
import 'package:devlink_mobile_app/group/data/repository_impl/group_repository_impl.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:devlink_mobile_app/group/domain/usecase/create_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_list_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/join_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/leave_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/update_group_use_case.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_di.g.dart';

// DataSource 프로바이더
@riverpod
GroupDataSource groupDataSource(Ref ref) => MockGroupDataSourceImpl();

// Repository 프로바이더
@riverpod
GroupRepository groupRepository(Ref ref) =>
    GroupRepositoryImpl(dataSource: ref.watch(groupDataSourceProvider));

// UseCase 프로바이더들
@riverpod
GetGroupListUseCase getGroupListUseCase(Ref ref) =>
    GetGroupListUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
GetGroupDetailUseCase getGroupDetailUseCase(Ref ref) =>
    GetGroupDetailUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
JoinGroupUseCase joinGroupUseCase(Ref ref) =>
    JoinGroupUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
CreateGroupUseCase createGroupUseCase(Ref ref) =>
    CreateGroupUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
UpdateGroupUseCase updateGroupUseCase(Ref ref) =>
    UpdateGroupUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
LeaveGroupUseCase leaveGroupUseCase(Ref ref) =>
    LeaveGroupUseCase(repository: ref.watch(groupRepositoryProvider));
