import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/firebase/firebase_providers.dart';
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
import 'package:devlink_mobile_app/group/domain/usecase/record_timer_activity_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/search_groups_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/send_message_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/stream_group_member_timer_status_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/update_group_use_case.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/send_bot_use_case.dart';

part 'group_di.g.dart';

// ==================== 그룹 관련 DI ====================

// 🔧 수정: DataSource 프로바이더 - dispose 처리를 위해 keepAlive 제거하고 ref.onDispose 추가
@riverpod
GroupDataSource groupDataSource(Ref ref) {
  GroupDataSource dataSource;

  // AppConfig 설정에 따라 Firebase 또는 Mock 구현체 제공
  if (AppConfig.useMockGroup) {
    if (kDebugMode) {
      print('GroupDataSource: MockGroupDataSourceImpl 사용');
    }
    dataSource = MockGroupDataSourceImpl();
  } else {
    if (kDebugMode) {
      print('GroupDataSource: GroupFirebaseDataSource 사용');
    }

    // Firebase 인스턴스들을 주입
    dataSource = GroupFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
      storage: FirebaseStorage.instance,
      auth: ref.watch(firebaseAuthProvider),
    );
  }

  // 🔧 새로 추가: Provider가 dispose될 때 DataSource의 dispose 호출
  ref.onDispose(() {
    if (kDebugMode) {
      print('GroupDataSource Provider: onDispose 호출');
    }

    // Firebase DataSource인 경우에만 dispose 호출
    if (dataSource is GroupFirebaseDataSource) {
      dataSource.dispose();
    }
  });

  return dataSource;
}

// Group chat DataSource
@riverpod
GroupChatDataSource groupChatDataSource(Ref ref) {
  return GroupChatFirebaseDataSource();
}

// Repository 프로바이더 - Ref 제거, 순수 DataSource만 주입
@riverpod
GroupRepository groupRepository(Ref ref) => GroupRepositoryImpl(
  dataSource: ref.watch(groupDataSourceProvider),
);

// Group chat Repository
@riverpod
GroupChatRepository groupChatRepository(Ref ref) => GroupChatRepositoryImpl(
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

// 기존 UseCase 프로바이더들
@riverpod
GetGroupMembersUseCase getGroupMembersUseCase(Ref ref) =>
    GetGroupMembersUseCase(repository: ref.watch(groupRepositoryProvider));

@riverpod
GetAttendancesByMonthUseCase getAttendancesByMonthUseCase(Ref ref) =>
    GetAttendancesByMonthUseCase(
      repository: ref.watch(groupRepositoryProvider),
    );

// 🔧 새로운 실시간 스트림 UseCase Provider 추가
@riverpod
StreamGroupMemberTimerStatusUseCase streamGroupMemberTimerStatusUseCase(
  Ref ref,
) => StreamGroupMemberTimerStatusUseCase(
  repository: ref.watch(groupRepositoryProvider),
);

// Group chat UseCase

@riverpod
GetGroupMessagesUseCase getGroupMessagesUseCase(Ref ref) =>
    GetGroupMessagesUseCase(repository: ref.watch(groupChatRepositoryProvider));

@riverpod
SendMessageUseCase sendMessageUseCase(Ref ref) =>
    SendMessageUseCase(repository: ref.watch(groupChatRepositoryProvider));

@riverpod
GetGroupMessagesStreamUseCase getGroupMessagesStreamUseCase(Ref ref) =>
    GetGroupMessagesStreamUseCase(
      repository: ref.watch(groupChatRepositoryProvider),
    );

@riverpod
MarkMessagesAsReadUseCase markMessagesAsReadUseCase(Ref ref) =>
    MarkMessagesAsReadUseCase(
      repository: ref.watch(groupChatRepositoryProvider),
    );

// 기존 개별 UseCase Providers를 제거하고 통합 Provider로 교체

// ===== 통합 타이머 UseCase Provider =====
@riverpod
RecordTimerActivityUseCase recordTimerActivityUseCase(Ref ref) {
  return RecordTimerActivityUseCase(
    repository: ref.watch(groupRepositoryProvider),
  );
}

@riverpod
SendBotMessageUseCase sendBotMessageUseCase(Ref ref) =>
    SendBotMessageUseCase(repository: ref.watch(groupChatRepositoryProvider));
