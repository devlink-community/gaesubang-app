// lib/group/presentation/group_setting/group_settings_notifier.dart
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/utils/image_compression.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
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

  // 추가: mounted 변수
  bool _mounted = true;

  bool get mounted => _mounted;

  @override
  GroupSettingsState build(String groupId) {
    _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider);
    _getGroupMembersUseCase = ref.watch(getGroupMembersUseCaseProvider);
    _updateGroupUseCase = ref.watch(updateGroupUseCaseProvider);
    _leaveGroupUseCase = ref.watch(leaveGroupUseCaseProvider);
    _uploadImageUseCase = ref.watch(uploadImageUseCaseProvider);

    // 추가: Provider가 dispose될 때 호출될 콜백 등록
    ref.onDispose(() {
      _mounted = false;
      debugPrint('GroupSettingsNotifier disposed');
    });

    // 초기 상태를 먼저 반환
    const initialState = GroupSettingsState(
      currentAction: GroupAction.none,
    );

    // 비동기 데이터 로드는 별도로 실행 (state 초기화 후)
    Future.microtask(() {
      _loadGroupDetail(groupId);
      _loadInitialMembers(groupId);
    });

    return initialState;
  }

  Future<void> _loadGroupDetail(String groupId) async {
    // 현재 사용자 정보 로드
    final currentUser = ref.read(currentUserProvider);

    final result = await _getGroupDetailUseCase.execute(groupId);

    switch (result) {
      case AsyncData(:final value):
        // 🔧 수정: 현재 사용자가 방장인지 확인
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
          errorMessage: _getFriendlyErrorMessage(error),
        );
      case AsyncLoading():
        state = state.copyWith(group: result);
    }
  }

  // 🔧 새로 추가: 초기 멤버 로딩 (페이지네이션 방식)
  Future<void> _loadInitialMembers(String groupId) async {
    // 멤버 목록 로딩 시작 - 페이지네이션 상태 초기화
    state = state.copyWith(
      members: const AsyncValue.loading(),
      currentMemberPage: 0,
      paginatedMembers: [],
      hasMoreMembers: true,
      isLoadingMoreMembers: false,
      memberLoadError: null,
    );

    await _loadMemberPage(groupId, isInitialLoad: true);
  }

  // 🔧 새로 추가: 멤버 페이지 로딩 로직
  Future<void> _loadMemberPage(
    String groupId, {
    bool isInitialLoad = false,
  }) async {
    try {
      if (!isInitialLoad) {
        // 추가 로딩 시작
        state = state.copyWith(
          isLoadingMoreMembers: true,
          memberLoadError: null,
        );
      }

      final result = await _getGroupMembersUseCase.execute(groupId);

      switch (result) {
        case AsyncData(:final value):
          _handleMemberPageSuccess(value, isInitialLoad);

        case AsyncError(:final error):
          _handleMemberPageError(error, isInitialLoad);

        case AsyncLoading():
          // 로딩 상태는 이미 설정됨
          break;
      }
    } catch (e, st) {
      debugPrint('멤버 페이지 로드 중 예외 발생: $e\n$st');
      _handleMemberPageError(e, isInitialLoad);
    }
  }

  // 🔧 새로 추가: 멤버 로딩 성공 처리
  void _handleMemberPageSuccess(
    List<GroupMember> allMembers,
    bool isInitialLoad,
  ) {
    final currentPage = isInitialLoad ? 0 : state.currentMemberPage;
    final pageSize = state.memberPageSize;

    // 현재까지 로드된 멤버 수 계산
    final startIndex = isInitialLoad ? 0 : state.paginatedMembers.length;
    final endIndex = startIndex + pageSize;

    // 새로 로드할 멤버들 추출
    final newMembers = allMembers.skip(startIndex).take(pageSize).toList();

    // 기존 멤버 목록과 합치기
    final updatedMembers =
        isInitialLoad ? newMembers : [...state.paginatedMembers, ...newMembers];

    // 더 로드할 멤버가 있는지 확인
    final hasMore = endIndex < allMembers.length;

    state = state.copyWith(
      members: AsyncData(allMembers),
      // 전체 멤버 목록도 업데이트
      paginatedMembers: updatedMembers,
      currentMemberPage: isInitialLoad ? 0 : currentPage + 1,
      hasMoreMembers: hasMore,
      isLoadingMoreMembers: false,
      memberLoadError: null,
    );

    debugPrint(
      '멤버 페이지 로딩 완료: ${updatedMembers.length}/${allMembers.length}, hasMore: $hasMore',
    );
  }

  // 🔧 새로 추가: 멤버 로딩 에러 처리
  void _handleMemberPageError(Object error, bool isInitialLoad) {
    final friendlyMessage = _getFriendlyErrorMessage(error);

    if (isInitialLoad) {
      // 초기 로딩 실패
      state = state.copyWith(
        members: AsyncError(error, StackTrace.current),
        memberLoadError: friendlyMessage,
        isLoadingMoreMembers: false,
      );
    } else {
      // 추가 로딩 실패
      state = state.copyWith(
        memberLoadError: friendlyMessage,
        isLoadingMoreMembers: false,
      );
    }

    debugPrint('멤버 로딩 실패: $friendlyMessage');
  }

  // 🔧 새로 추가: 사용자 친화적 에러 메시지 생성
  String _getFriendlyErrorMessage(Object? error) {
    if (error == null) return '알 수 없는 오류가 발생했습니다';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return '인터넷 연결을 확인해주세요';
    }

    if (errorString.contains('timeout')) {
      return '요청 시간이 초과되었습니다. 다시 시도해주세요';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('permission') ||
        errorString.contains('권한')) {
      return '권한이 없습니다. 다시 로그인해주세요';
    }

    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('503')) {
      return '서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해주세요';
    }

    if (errorString.contains('그룹을 찾을 수 없습니다')) {
      return '그룹을 찾을 수 없습니다';
    }

    if (errorString.contains('멤버')) {
      return '멤버 정보를 불러오는데 실패했습니다';
    }

    return '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
  }

  /// 이미지 업로드 처리 - 세밀한 상태 관리
  Future<void> uploadGroupImage(String localImagePath) async {
    try {
      state = state.copyWith(
        isSubmitting: true,
        currentAction: GroupAction.imageUpload,
        // 작업 타입 설정
        // 업로드 시작 - 초기 상태 설정
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
          isSubmitting: false, // 에러 상태이므로 로딩 해제
          currentAction: GroupAction.none, // 작업 완료
        );
        return;
      }

      debugPrint('🖼️ 이미지 업로드 시작: $localImagePath');

      // 1단계: 이미지 압축 시작
      state = state.copyWith(
        imageUploadStatus: ImageUploadStatus.compressing,
        uploadProgress: 0.1,
      );

      // file:// 프로토콜 제거 (플랫폼 호환성 개선)
      final cleanPath = localImagePath.replaceFirst(RegExp(r'^file:\/\/'), '');
      debugPrint('🖼️ 정제된 이미지 경로: $cleanPath');

      final compressedFile = await ImageCompressionUtils.compressAndSaveImage(
        originalImagePath: cleanPath,
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
      debugPrint('🖼️ 이미지 바이트 크기: ${imageBytes.length}');

      // 4단계: Firebase Storage 업로드 시작
      state = state.copyWith(
        imageUploadStatus: ImageUploadStatus.uploading,
        uploadProgress: 0.5,
      );

      final fileName =
          'group_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final folderPath = 'groups/${currentGroup.id}';

      debugPrint('🖼️ 스토리지 경로: $folderPath/$fileName');

      final uploadResult = await _uploadImageUseCase.execute(
        folderPath: folderPath,
        fileName: fileName,
        bytes: imageBytes,
        metadata: {
          'groupId': currentGroup.id,
          'uploadedBy': currentGroup.ownerId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'contentType': 'image/jpeg',
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
            originalImagePath: null,
            // 로컬 경로 초기화
            isSubmitting: false,
            // 로딩 OFF
            currentAction: GroupAction.none, // 작업 완료
          );

          // 임시 압축 파일 삭제
          try {
            if (await compressedFile.exists()) {
              await compressedFile.delete();
            }
          } catch (e) {
            debugPrint('임시 파일 삭제 실패: $e');
          }

          // 3초 후 완료 상태 초기화
          Future.delayed(const Duration(seconds: 3), () {
            if (_mounted) {
              // mounted 변수 사용
              if (state.imageUploadStatus == ImageUploadStatus.completed) {
                state = state.copyWith(
                  imageUploadStatus: ImageUploadStatus.idle,
                  uploadProgress: 0.0,
                );
              }
            }
          });
          break;

        case AsyncError(:final error):
          debugPrint('🖼️ 이미지 업로드 실패: $error');
          state = state.copyWith(
            imageUploadStatus: ImageUploadStatus.failed,
            uploadProgress: 0.0,
            errorMessage: '이미지 업로드 실패: ${_getFriendlyErrorMessage(error)}',
            isSubmitting: false,
            // 로딩 OFF
            currentAction: GroupAction.none, // 작업 완료
          );
          break;

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
        errorMessage: '이미지 업로드 실패: ${_getFriendlyErrorMessage(e)}',
        isSubmitting: false,
        // 로딩 OFF
        currentAction: GroupAction.none, // 작업 완료
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
        // null인 경우 (이미지 삭제 버튼 클릭)
        if (imageUrl == null) {
          final currentImageUrl = state.imageUrl;

          // 현재 Firebase Storage 이미지가 있으면 삭제 예약 (실제 삭제는 save 시점에서)
          if (currentImageUrl != null && currentImageUrl.startsWith('http')) {
            // 삭제할 이미지 URL을 상태에 저장해두고, save 시점에서 삭제 처리
            state = state.copyWith(
              imageUrl: null,
              originalImagePath: null, // 로컬 이미지 경로도 초기화
              imageUploadStatus: ImageUploadStatus.idle,
            );
          } else {
            state = state.copyWith(
              imageUrl: null,
              originalImagePath: null,
              imageUploadStatus: ImageUploadStatus.idle,
            );
          }
        }
        // 로컬 파일 경로인 경우 Firebase Storage에 업로드
        else if (imageUrl.startsWith('file://') ||
            imageUrl.startsWith('content://')) {
          debugPrint('🖼️ 로컬 파일 업로드 시작: $imageUrl');
          await uploadGroupImage(imageUrl);
        } else {
          // 네트워크 URL인 경우 직접 설정
          debugPrint('🖼️ 네트워크 URL 직접 설정: $imageUrl');
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
        // 이미지 업로드 중이면 저장 방지
        if (state.isImageUploading) {
          state = state.copyWith(
            errorMessage: '이미지 업로드가 진행 중입니다. 완료 후 다시 시도해 주세요.',
          );
          return;
        }
        await _updateGroup();

      case LeaveGroup():
        await _leaveGroup();

      case Refresh():
        // 그룹 ID 가져오기
        final group = state.group.valueOrNull;
        if (group != null) {
          await _loadGroupDetail(group.id);
          await _loadInitialMembers(group.id);
        }

      case SelectImage():
        // Root에서 처리 (이미지 선택 다이얼로그 표시)
        break;

      // 페이지네이션 관련 액션 처리
      case LoadMoreMembers():
        final group = state.group.valueOrNull;
        if (group != null && state.canLoadMoreMembers) {
          await _loadMemberPage(group.id, isInitialLoad: false);
        }

      case RetryLoadMembers():
        final group = state.group.valueOrNull;
        if (group != null) {
          // 현재 페이지 상태에 따라 초기 로딩 또는 추가 로딩 재시도
          if (state.paginatedMembers.isEmpty) {
            await _loadInitialMembers(group.id);
          } else {
            await _loadMemberPage(group.id, isInitialLoad: false);
          }
        }

      case ResetMemberPagination():
        final group = state.group.valueOrNull;
        if (group != null) {
          await _loadInitialMembers(group.id);
        }
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
      currentAction: GroupAction.save, // 작업 타입 설정
      errorMessage: null,
      successMessage: null,
    );

    // 🔧 수정: 업데이트된 그룹 생성
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
      pauseTimeLimit: currentGroup.pauseTimeLimit, // 기존값 유지
    );

    // 그룹 업데이트
    final result = await _updateGroupUseCase.execute(updatedGroup);

    // 결과 처리
    switch (result) {
      case AsyncData():
        // 그룹 정보 다시 로드
        await _loadGroupDetail(currentGroup.id);
        await _loadInitialMembers(currentGroup.id); // 🔧 페이지네이션 버전으로 변경
        state = state.copyWith(
          isSubmitting: false,
          isEditing: false, // 편집 모드 종료
          successMessage: '그룹 정보가 성공적으로 업데이트되었습니다.',
          currentAction: GroupAction.none, // 작업 완료
        );
        break;
      case AsyncError(:final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _getFriendlyErrorMessage(error),
          currentAction: GroupAction.none, // 작업 완료
        );
        break;
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

    state = state.copyWith(
      isSubmitting: true,
      currentAction: GroupAction.leave, // 작업 타입 설정
      errorMessage: null,
    );

    // 그룹 탈퇴
    final result = await _leaveGroupUseCase.execute(currentGroup.id);

    // 결과 처리
    switch (result) {
      case AsyncData():
        state = state.copyWith(
          isSubmitting: false,
          successMessage: '그룹에서 성공적으로 탈퇴했습니다.',
          currentAction: GroupAction.none, // 작업 완료
        );
        break;
      case AsyncError(:final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _getFriendlyErrorMessage(error),
          currentAction: GroupAction.none, // 작업 완료
        );
        break;
      case AsyncLoading():
        // 이미 처리됨
        break;
    }
  }
}
