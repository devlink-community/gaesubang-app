import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_chat_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_chat_firebase_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_firebase_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/mock_group_data_source_impl.dart';
import 'package:devlink_mobile_app/group/data/repository_impl/group_chat_repository_impl.dart';
import 'package:devlink_mobile_app/group/data/repository_impl/group_repository_impl.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:devlink_mobile_app/group/domain/usecase/create_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_attendance_by_month_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_list_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_members_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_messages_stream_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_messages_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/join_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/leave_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/mark_messages_as_read_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/pause_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/search_groups_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/send_message_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/start_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/stop_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/update_group_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_di.g.dart';

// ==================== 그룹 관련 DI ====================

// DataSource 프로바이더 - AppConfig에 따라 Firebase 또는 Mock 구현체 제공
@Riverpod(keepAlive: true)
GroupDataSource groupDataSource(Ref ref) {
  // AppConfig 설정에 따라 Firebase 또는 Mock 구현체 제공
  if (AppConfig.useMockGroup) {
    if (kDebugMode) {
      print('GroupDataSource: MockGroupDataSourceImpl 사용');
    }
    return MockGroupDataSourceImpl();
  } else {
    if (kDebugMode) {
      print('GroupDataSource: GroupFirebaseDataSource 사용');
    }
    return GroupFirebaseDataSource();
  }
}

// Group chat DataSource
@riverpod
GroupChatDataSource groupChatDataSource(Ref ref) {
  return GroupChatFirebaseDataSource();
}

// Repository 프로바이더
@riverpod
GroupRepository groupRepository(Ref ref) => GroupRepositoryImpl(
  dataSource: ref.watch(groupDataSourceProvider),
  ref: ref,
);

// Group chat Repository
@riverpod
GroupChatRepository groupChatRepository(Ref ref) => 
  GroupChatRepositoryImpl(
    dataSource: ref.watch(groupChatDataSourceProvider),
    ref: ref,
  );

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

@riverpod
SearchGroupsUseCase searchGroupsUseCase(Ref ref) =>
    SearchGroupsUseCase(repository: ref.watch(groupRepositoryProvider));

// 새로 추가된 UseCase 프로바이더들
@riverpod
GetGroupMembersUseCase getGroupMembersUseCase(Ref ref) =>
    GetGroupMembersUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
GetAttendancesByMonthUseCase getAttendancesByMonthUseCase(Ref ref) =>
    GetAttendancesByMonthUseCase(
      repository: ref.watch(groupRepositoryProvider),
    );

@riverpod
StartTimerUseCase startTimerUseCase(Ref ref) =>
    StartTimerUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
StopTimerUseCase stopTimerUseCase(Ref ref) =>
    StopTimerUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
PauseTimerUseCase pauseTimerUseCase(Ref ref) =>
    PauseTimerUseCase(repository: ref.watch(groupRepositoryProvider));

// Group chat UseCase

@riverpod
GetGroupMessagesUseCase getGroupMessagesUseCase(Ref ref) =>
  GetGroupMessagesUseCase(repository: ref.watch(groupChatRepositoryProvider));

@riverpod
SendMessageUseCase sendMessageUseCase(Ref ref) =>
  SendMessageUseCase(repository: ref.watch(groupChatRepositoryProvider));

@riverpod
GetGroupMessagesStreamUseCase getGroupMessagesStreamUseCase(Ref ref) =>
  GetGroupMessagesStreamUseCase(repository: ref.watch(groupChatRepositoryProvider));

@riverpod
MarkMessagesAsReadUseCase markMessagesAsReadUseCase(Ref ref) =>
  MarkMessagesAsReadUseCase(repository: ref.watch(groupChatRepositoryProvider));