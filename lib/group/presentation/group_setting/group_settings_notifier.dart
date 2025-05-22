// lib/group/presentation/group_setting/group_settings_notifier.dart
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/utils/image_compression.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_members_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/leave_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/update_group_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_state.dart';
import 'package:devlink_mobile_app/storage/domain/usecase/upload_image_use_case.dart';
import 'package:devlink_mobile_app/storage/module/storage_di.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_settings_notifier.g.dart';

@riverpod
class GroupSettingsNotifier extends _$GroupSettingsNotifier {
  late final GetGroupDetailUseCase _getGroupDetailUseCase;
  late final GetGroupMembersUseCase _getGroupMembersUseCase;
  late final UpdateGroupUseCase _updateGroupUseCase;
  late final LeaveGroupUseCase _leaveGroupUseCase;
  late final UploadImageUseCase _uploadImageUseCase;

  @override
  GroupSettingsState build(String groupId) {
    _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider);
    _getGroupMembersUseCase = ref.watch(getGroupMembersUseCaseProvider);
    _updateGroupUseCase = ref.watch(updateGroupUseCaseProvider);
    _leaveGroupUseCase = ref.watch(leaveGroupUseCaseProvider);
    _uploadImageUseCase = ref.watch(uploadImageUseCaseProvider);

    // 초기 상태를 먼저 반환
    const initialState = GroupSettingsState();

    // 비동기 데이터 로드는 별도로 실행 (state 초기화 후)
    Future.microtask(() {
      _loadGroupDetail(groupId);
      _loadGroupMembers(groupId);
    });

    return initialState;
  }

  Future<void> _loadGroupDetail(String groupId) async {
    // 현재 사용자 정보 로드
    final currentUser = ref.read(currentUserProvider);

    final result = await _getGroupDetailUseCase.execute(groupId);

    switch (result) {
      case AsyncData(:final value):
        // 현재 사용자가 방장인지 확인
        final isOwner = value.ownerId == currentUser?.id;

        state = state.copyWith(
          group: result,
          name: value.name,
          description: value.description,
          imageUrl: value.imageUrl,
          hashTags:
              value.hashTags
                  .map((tag) => HashTag(id: tag, content: tag))
                  .toList(),
          limitMemberCount: value.maxMemberCount,
          isOwner: isOwner,
        );
      case AsyncError(:final error):
        state = state.copyWith(
          group: result,
          errorMessage: '그룹 정보를 불러오는데 실패했습니다: $error',
        );
      case AsyncLoading():
        state = state.copyWith(group: result);
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    // 멤버 목록 로딩 시작
    state = state.copyWith(members: const AsyncValue.loading());

    try {
      final result = await _getGroupMembersUseCase.execute(groupId);

      switch (result) {
        case AsyncData(:final value):
          state = state.copyWith(members: AsyncData(value));

        case AsyncError(:final error):
          state = state.copyWith(
            members: AsyncError(error, StackTrace.current),
            errorMessage: '멤버 목록을 불러오는데 실패했습니다: $error',
          );

        case AsyncLoading():
          state = state.copyWith(members: result);
      }
    } catch (e, st) {
      state = state.copyWith(
        members: AsyncError(e, st),
        errorMessage: '멤버 목록 로드 중 오류: $e',
      );
    }
  }

  /// 이미지 업로드 처리 - 세밀한 상태 관리
  Future<void> uploadGroupImage(String localImagePath) async {
    try {
      state = state.copyWith(isSubmitting: true);
      // 업로드 시작 - 초기 상태 설정
      state = state.copyWith(
        imageUploadStatus: ImageUploadStatus.idle,
        uploadProgress: 0.0,
        originalImagePath: localImagePath,
        errorMessage: null,
        successMessage: null,
      );

      final currentGroup = state.group.valueOrNull;
      if (currentGroup == null) {
        state = state.copyWith(
          imageUploadStatus: ImageUploadStatus.failed,
          errorMessage: '그룹 정보가 없습니다.',
        );
        return;
      }

      debugPrint('🖼️ 이미지 업로드 시작: $localImagePath');

      // 1단계: 이미지 압축 시작
      state = state.copyWith(
        imageUploadStatus: ImageUploadStatus.compressing,
        uploadProgress: 0.1,
      );

      final compressedFile = await ImageCompressionUtils.compressAndSaveImage(
        originalImagePath: localImagePath.replaceFirst('file://', ''),
        maxWidth: 800,
        maxHeight: 800,
        quality: 85,
        maxFileSizeKB: 500,
      );

      debugPrint('🖼️ 이미지 압축 완료: ${compressedFile.path}');

      // 2단계: 압축 완료, 업로드 준비
      state = state.copyWith(
        uploadProgress: 0.3,
      );

      // 3단계: 압축된 이미지를 바이트로 읽기
      final imageBytes = await compressedFile.readAsBytes();

      // 4단계: Firebase Storage 업로드 시작
      state = state.copyWith(
        imageUploadStatus: ImageUploadStatus.uploading,
        uploadProgress: 0.5,
      );

      final fileName =
          'group_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final folderPath = 'groups/${currentGroup.id}';

      final uploadResult = await _uploadImageUseCase.execute(
        folderPath: folderPath,
        fileName: fileName,
        bytes: imageBytes,
        metadata: {
          'groupId': currentGroup.id,
          'uploadedBy': currentGroup.ownerId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      switch (uploadResult) {
        case AsyncData(:final value):
          debugPrint('🖼️ 이미지 업로드 성공: $value');

          // 5단계: 업로드 완료
          state = state.copyWith(
            imageUrl: value,
            imageUploadStatus: ImageUploadStatus.completed,
            uploadProgress: 1.0,
            successMessage: '이미지 업로드가 완료되었습니다.',
            originalImagePath: null, // 로컬 경로 초기화
            isSubmitting: false, // 로딩 OFF
          );

          // 임시 압축 파일 삭제
          try {
            if (await compressedFile.exists()) {
              await compressedFile.delete();
            }
          } catch (e) {
            debugPrint('임시 파일 삭제 실패: $e');
          }

          // 2초 후 완료 상태 초기화
          Future.delayed(const Duration(seconds: 2), () {
            if (state.imageUploadStatus == ImageUploadStatus.completed) {
              state = state.copyWith(
                imageUploadStatus: ImageUploadStatus.idle,
                uploadProgress: 0.0,
              );
            }
          });

        case AsyncError(:final error):
          debugPrint('🖼️ 이미지 업로드 실패: $error');
          state = state.copyWith(
            imageUploadStatus: ImageUploadStatus.failed,
            uploadProgress: 0.0,
            errorMessage: '이미지 업로드에 실패했습니다: $error',
            isSubmitting: false, // 로딩 OFF
          );

        case AsyncLoading():
          // 업로드 중 상태는 이미 설정되어 있음
          state = state.copyWith(uploadProgress: 0.8);
          break;
      }
    } catch (e, st) {
      debugPrint('🖼️ 이미지 업로드 과정에서 오류 발생: $e');
      debugPrint('🖼️ StackTrace: $st');

      state = state.copyWith(
        imageUploadStatus: ImageUploadStatus.failed,
        uploadProgress: 0.0,
        errorMessage: '이미지 처리 중 오류가 발생했습니다: $e',
        isSubmitting: false, // 로딩 OFF
      );
    }
  }

  Future<void> onAction(GroupSettingsAction action) async {
    switch (action) {
      case NameChanged(:final name):
        state = state.copyWith(name: name);

      case DescriptionChanged(:final description):
        state = state.copyWith(description: description);

      case LimitMemberCountChanged(:final count):
        final validCount = count < 1 ? 1 : count;
        state = state.copyWith(limitMemberCount: validCount);

      case ImageUrlChanged(:final imageUrl):
        // 로컬 파일 경로인 경우 Firebase Storage에 업로드
        if (imageUrl != null && imageUrl.startsWith('file://')) {
          await uploadGroupImage(imageUrl);
        } else {
          // 네트워크 URL이거나 null인 경우 직접 설정
          state = state.copyWith(imageUrl: imageUrl);
        }

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

      case ToggleEditMode():
        // 현재 편집 모드 상태의 반대로 변경
        state = state.copyWith(isEditing: !state.isEditing);

        // 편집 모드를 종료하면 원래 그룹 정보로 되돌림
        if (!state.isEditing) {
          final originalGroup = state.group.valueOrNull;
          if (originalGroup != null) {
            state = state.copyWith(
              name: originalGroup.name,
              description: originalGroup.description,
              imageUrl: originalGroup.imageUrl,
              hashTags:
                  originalGroup.hashTags
                      .map((tag) => HashTag(id: tag, content: tag))
                      .toList(),
              limitMemberCount: originalGroup.maxMemberCount,
            );
          }
        }

      case Save():
        await _updateGroup();

      case LeaveGroup():
        await _leaveGroup();

      case Refresh():
        // 그룹 ID 가져오기
        final group = state.group.valueOrNull;
        if (group != null) {
          await _loadGroupDetail(group.id);
          await _loadGroupMembers(group.id);
        }

      case SelectImage():
        // Root에서 처리 (이미지 선택 다이얼로그 표시)
        break;
    }
  }

  Future<void> _updateGroup() async {
    // 현재 그룹 정보 가져오기
    final currentGroup = state.group.valueOrNull;
    if (currentGroup == null) {
      state = state.copyWith(errorMessage: '그룹 정보가 없습니다. 다시 시도해주세요.');
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      successMessage: null,
    );

    // 업데이트된 그룹 생성
    final updatedGroup = Group(
      id: currentGroup.id,
      name: state.name,
      description: state.description,
      hashTags: state.hashTags.map((tag) => tag.content).toList(),
      maxMemberCount: state.limitMemberCount,
      memberCount: currentGroup.memberCount,
      ownerId: currentGroup.ownerId,
      ownerNickname: currentGroup.ownerNickname,
      ownerProfileImage: currentGroup.ownerProfileImage,
      imageUrl: state.imageUrl,
      createdAt: currentGroup.createdAt,
      isJoinedByCurrentUser: currentGroup.isJoinedByCurrentUser,
    );

    // 그룹 업데이트
    final result = await _updateGroupUseCase.execute(updatedGroup);

    // 결과 처리
    switch (result) {
      case AsyncData():
        // 그룹 정보 다시 로드
        await _loadGroupDetail(currentGroup.id);
        await _loadGroupMembers(currentGroup.id); // 멤버 정보도 다시 로드
        state = state.copyWith(
          isSubmitting: false,
          isEditing: false, // 편집 모드 종료
          successMessage: '그룹 정보가 성공적으로 업데이트되었습니다.',
        );
      case AsyncError(:final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: '그룹 정보 업데이트 실패: $error',
        );
      case AsyncLoading():
        // 이미 처리됨
        break;
    }
  }

  Future<void> _leaveGroup() async {
    final currentGroup = state.group.valueOrNull;
    if (currentGroup == null) {
      state = state.copyWith(errorMessage: '그룹 정보가 없습니다. 다시 시도해주세요.');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    // 그룹 탈퇴
    final result = await _leaveGroupUseCase.execute(currentGroup.id);

    // 결과 처리
    switch (result) {
      case AsyncData():
        state = state.copyWith(
          isSubmitting: false,
          successMessage: '그룹에서 성공적으로 탈퇴했습니다.',
        );
      case AsyncError(:final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: '그룹 탈퇴 실패: $error',
        );
      case AsyncLoading():
        // 이미 처리됨
        break;
    }
  }
}
