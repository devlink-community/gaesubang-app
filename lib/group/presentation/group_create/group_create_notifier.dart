// lib/group/presentation/group_create/group_create_notifier.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
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
        final validCount = count < 1 ? 1 : count;
        state = state.copyWith(limitMemberCount: validCount);

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

      case SelectImage():
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
      // 현재 로그인한 사용자 정보 가져오기
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: '로그인 정보를 찾을 수 없습니다',
        );
        return;
      }

      // 그룹 객체 생성 - 최신 Group 모델 구조에 맞게 수정
      final group = Group(
        id: 'temp_id', // 서버에서 생성될 ID
        name: state.name.trim(),
        description: state.description.trim(),
        ownerId: currentUser.id, // owner 객체 대신 ownerId 문자열 사용
        ownerNickname: currentUser.nickname, // 방장 닉네임 추가
        ownerProfileImage: currentUser.image, // 방장 프로필 이미지 추가
        hashTags:
            state.hashTags
                .map((tag) => tag.content)
                .toList(), // HashTag 객체 리스트 → 문자열 리스트로 변환
        maxMemberCount: state.limitMemberCount,
        imageUrl: state.imageUrl,
        createdAt: DateTime.now(),
        memberCount: 1 + state.invitedMembers.length, // 방장 + 초대된 멤버 수
        isJoinedByCurrentUser: true, // 생성자는 자동으로 그룹에 가입됨
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
