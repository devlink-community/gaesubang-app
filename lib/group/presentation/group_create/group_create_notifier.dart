// lib/group/presentation/group_create/group_create_notifier.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/usecase/create_group_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_create_notifier.g.dart';

@riverpod
class GroupCreateNotifier extends _$GroupCreateNotifier {
  late final CreateGroupUseCase _createGroupUseCase;

  @override
  GroupCreateState build() {
    _createGroupUseCase = ref.watch(createGroupUseCaseProvider);
    return const GroupCreateState();
  }

  Future<void> onAction(GroupCreateAction action) async {
    switch (action) {
      case NameChanged(:final name):
        state = state.copyWith(name: name);

      case DescriptionChanged(:final description):
        state = state.copyWith(description: description);

      case LimitMemberCountChanged(:final count):
        state = state.copyWith(limitMemberCount: count);

      case HashTagAdded(:final tag):
        final trimmed = tag.trim();
        if (trimmed.isEmpty ||
            state.hashTags.any((t) => t.content == trimmed) ||
            trimmed.length > 20) {
          return;
        }
        final newTag = HashTag(
          id: DateTime.now().toString(),
          content: tag.trim(),
        );
        state = state.copyWith(hashTags: [...state.hashTags, newTag]);

      case HashTagRemoved(:final tag):
        state = state.copyWith(
          hashTags: state.hashTags.where((t) => t.content != tag).toList(),
        );

      case ImageUrlChanged(:final imageUrl):
        state = state.copyWith(imageUrl: imageUrl);

      case MemberInvited(:final memberId):
        // 실제 구현에서는 멤버 조회 API 호출 등이 필요
        final mockMember = Member(
          id: memberId,
          email: 'user$memberId@example.com',
          nickname: 'User $memberId',
          uid: 'uid_$memberId',
        );
        if (!state.invitedMembers.any((m) => m.id == memberId)) {
          state = state.copyWith(
            invitedMembers: [...state.invitedMembers, mockMember],
          );
        }

      case MemberRemoved(:final memberId):
        state = state.copyWith(
          invitedMembers:
              state.invitedMembers.where((m) => m.id != memberId).toList(),
        );

      case Submit():
        await _submit();

      case Cancel():
        // Root에서 처리
        break;
    }
  }

  Future<void> _submit() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(errorMessage: '그룹 이름을 입력하세요');
      return;
    }

    if (state.description.trim().isEmpty) {
      state = state.copyWith(errorMessage: '그룹 설명을 입력하세요');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // 현재 로그인한 사용자를 오너로 설정 (실제 구현 필요)
      // -> 이 부분은 실제 로그인된 사용자 정보를 가져오는 로직으로 대체해야 함
      // 예시로 현재 사용자의 정보를 하드코딩
      // -> 실제로는 AuthProvider 등을 통해 현재 사용자 정보를 가져와야 함
      final owner = Member(
        id: 'current_user_id',
        email: 'current_user@example.com',
        nickname: '현재 사용자',
        uid: 'current_user_uid',
      );

      // 그룹 객체 생성
      final group = Group(
        id: 'temp_id', // 서버에서 생성될 ID
        name: state.name.trim(),
        description: state.description.trim(),
        members: [owner, ...state.invitedMembers],
        hashTags: state.hashTags,
        limitMemberCount: state.limitMemberCount,
        owner: owner,
        imageUrl: state.imageUrl,
      );

      // UseCase 호출하여 그룹 생성
      final result = await _createGroupUseCase.execute(group);

      // 결과 처리
      switch (result) {
        case AsyncData(:final value):
          state = state.copyWith(isSubmitting: false, createdGroupId: value.id);
        case AsyncError(:final error):
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.toString(),
          );
        case AsyncLoading():
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '그룹 생성에 실패했습니다: $e',
      );
    }
  }
}
