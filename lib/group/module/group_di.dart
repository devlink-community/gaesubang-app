import 'package:devlink_mobile_app/core/firebase/firebase_providers.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_chat_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_chat_firebase_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_firebase_data_source.dart';
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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/send_bot_use_case.dart';

part 'group_di.g.dart';

// ==================== 그룹 관련 DI ====================

// 🔧 수정: Firebase만 사용하도록 DataSource 프로바이더 변경
@riverpod
GroupDataSource groupDataSource(Ref ref) {
  AppLogger.debug(
    'GroupDataSource: GroupFirebaseDataSource 사용 (Mock 제거)',
    tag: 'GroupDI',
  );

  // Firebase 인스턴스들을 주입하여 실제 Firebase DataSource 생성
  final dataSource = GroupFirebaseDataSource(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: FirebaseStorage.instance,
    auth: ref.watch(firebaseAuthProvider),
  );

  // Provider가 dispose될 때 DataSource의 dispose 호출
  ref.onDispose(() {
    AppLogger.debug('GroupDataSource Provider: onDispose 호출', tag: 'GroupDI');
    dataSource.dispose();
  });

  return dataSource;
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

// 통합 타이머 UseCase Provider
@riverpod
RecordTimerActivityUseCase recordTimerActivityUseCase(Ref ref) {
  return RecordTimerActivityUseCase(
    repository: ref.watch(groupRepositoryProvider),
  );
}

@riverpod
SendBotMessageUseCase sendBotMessageUseCase(Ref ref) =>
    SendBotMessageUseCase(repository: ref.watch(groupChatRepositoryProvider));
