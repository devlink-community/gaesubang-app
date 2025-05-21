// lib/community/presentation/community_write/community_write_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:devlink_mobile_app/storage/module/storage_di.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_write_notifier.g.dart';

@riverpod
class CommunityWriteNotifier extends _$CommunityWriteNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  CommunityWriteState build() {
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    ref.listen(appEventNotifierProvider, (previous, current) {
      if (previous != current) {
        final eventNotifier = ref.read(appEventNotifierProvider.notifier);
      }
    });

    return const CommunityWriteState();
  }

  Future<void> onAction(CommunityWriteAction action) async {
    switch (action) {
      case TitleChanged(:final title):
        state = state.copyWith(title: title);

      case ContentChanged(:final content):
        state = state.copyWith(content: content);

      case TagAdded(:final tag):
        if (tag.trim().isEmpty) return;
        // 이미 존재하는 태그라면 추가하지 않음
        if (state.hashTags.contains(tag.trim())) return;

        final newTags = [...state.hashTags, tag.trim()];
        state = state.copyWith(hashTags: newTags);

      case TagRemoved(:final tag):
        final newTags = state.hashTags.where((t) => t != tag).toList();
        state = state.copyWith(hashTags: newTags);

      case ImageAdded(:final bytes):
        // 이미지 최대 5개로 제한
        if (state.images.length >= 5) {
          state = state.copyWith(
            errorMessage: CommunityErrorMessages.tooManyImages,
          );
          return;
        }

        state = state.copyWith(
          images: [...state.images, bytes],
          errorMessage: null,
        );

      case ImageRemoved(:final index):
        if (index < 0 || index >= state.images.length) return;

        final newImages = [...state.images];
        newImages.removeAt(index);
        state = state.copyWith(images: newImages);

      case Submit():
        await _submit();

      case NavigateBack(:final postId):
        // Root에서 처리하므로 여기서는 아무 것도 하지 않음
        break;
    }
  }

  Future<void> _submit() async {
    // 유효성 검사
    if (state.title.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: CommunityErrorMessages.titleRequired,
      );
      return;
    }

    if (state.content.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: CommunityErrorMessages.contentRequired,
      );
      return;
    }

    // 제출 시작
    state = state.copyWith(submitting: true, errorMessage: null);

    try {
      debugPrint('🔄 CommunityWriteNotifier: 게시글 작성 시작 - 최신 사용자 정보 로드');

      // 최신 사용자 정보 가져오기
      final userProfileResult = await _getCurrentUserUseCase.execute();

      if (userProfileResult case AsyncError(:final error)) {
        debugPrint('❌ CommunityWriteNotifier: 사용자 정보 로드 실패 - $error');
        throw Exception('사용자 정보를 가져오는데 실패했습니다: $error');
      }

      // 사용자 정보 추출 (AsyncData의 value 필드에서)
      final Member author;
      if (userProfileResult case AsyncData(:final value)) {
        author = value;
        debugPrint(
          '✅ CommunityWriteNotifier: 최신 사용자 정보 로드 완료 - 닉네임: ${author.nickname}',
        );
      } else {
        debugPrint('⚠️ CommunityWriteNotifier: 사용자 정보가 AsyncData가 아님');
        throw Exception('사용자 정보를 가져오는데 실패했습니다: 예상치 못한 상태');
      }

      // 1. 게시글 ID 미리 생성 (Firebase에서 자동 생성되는 ID)
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      debugPrint('🔄 CommunityWriteNotifier: 게시글 ID 생성 - $postId');

      // 2. 이미지 업로드
      final List<Uri> imageUris = await _uploadImages(postId);
      debugPrint('✅ CommunityWriteNotifier: 이미지 업로드 완료 - ${imageUris.length}개');

      // 3. 게시글 데이터 생성 (수정: 사용자 프로필 전달)
      final usecase = ref.read(createPostUseCaseProvider);
      final createdPostId = await usecase.execute(
        postId: postId,
        title: state.title.trim(),
        content: state.content.trim(),
        hashTags: state.hashTags,
        imageUris: imageUris,
        author: author, // 중요: 최신 사용자 프로필 정보 전달
      );

      debugPrint(
        '✅ CommunityWriteNotifier: 게시글 생성 완료 - ID: $createdPostId, 작성자: ${author.nickname}',
      );

      // 4. 이벤트 발행: 게시글 생성됨
      ref
          .read(appEventNotifierProvider.notifier)
          .emit(AppEvent.postCreated(createdPostId));
      debugPrint(
        '✅ CommunityWriteNotifier: 게시글 생성 이벤트 발행 - ID: $createdPostId',
      );

      // 5. 성공 상태 업데이트
      state = state.copyWith(submitting: false, createdPostId: createdPostId);
    } catch (e) {
      debugPrint('❌ CommunityWriteNotifier: 게시글 작성 실패 - $e');
      // 실패 처리
      state = state.copyWith(
        submitting: false,
        errorMessage: CommunityErrorMessages.postCreateFailed,
      );
    }
  }

  // 리팩토링된 이미지 업로드 메서드
  Future<List<Uri>> _uploadImages(String postId) async {
    if (state.images.isEmpty) {
      return [];
    }

    try {
      // 현재 사용자 ID (임시로 'user1' 사용)
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception(CommunityErrorMessages.loginRequired);
      }
      final currentUserId = currentUser.uid;

      // 이미지 업로드를 위한 UseCase 가져오기
      final uploadImagesUseCase = ref.read(uploadImagesUseCaseProvider);

      // 폴더 경로: posts/{작성한 유저의 uid}/{Post의 uid}
      final folderPath = 'posts/$currentUserId/$postId';

      // UseCase를 통해 여러 이미지 업로드
      final result = await uploadImagesUseCase.execute(
        folderPath: folderPath,
        fileNamePrefix: 'image',
        bytesList: state.images,
        metadata: {'postId': postId, 'userId': currentUserId},
      );

      // AsyncValue 결과 처리
      return switch (result) {
        AsyncData(:final value) => value,
        AsyncError(:final error) => throw error,
        _ => throw Exception('이미지 업로드가 완료되지 않았습니다'), // 나머지 모든 케이스(AsyncLoading)
      };
    } catch (e) {
      // 에러 처리
      print('이미지 업로드 실패: $e');
      throw Exception('이미지 업로드에 실패했습니다: $e');
    }
  }
}
