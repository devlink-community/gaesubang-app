// lib/community/presentation/community_write/community_write_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:devlink_mobile_app/storage/module/storage_di.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_write_notifier.g.dart';

@riverpod
class CommunityWriteNotifier extends _$CommunityWriteNotifier {
  @override
  CommunityWriteState build() {
    ref.listen(appEventNotifierProvider, (previous, current) {
      if (previous != current) {
        final eventNotifier = ref.read(appEventNotifierProvider.notifier);
        //TODO: 이곳 실제로 사용하는지 검증 필요합니다. 체크해주세요
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
        // 수정 모드에 따라 다른 메서드 호출
        if (state.isEditMode) {
          await _update(); // 게시글 수정
        } else {
          await _submit(); // 게시글 생성
        }

      case NavigateBack(:final postId):
        // Root에서 처리하므로 여기서는 아무 것도 하지 않음
        break;
    }
  }

  void initWithPost(Post post) {
    if (state.isEditMode) return; // 이미 초기화된 경우 중복 방지

    state = state.copyWith(
      isEditMode: true,
      originalPostId: post.id,
      title: post.title,
      content: post.content,
      hashTags: post.hashTags,
      // 이미지는 별도 처리 필요 (URL → Uint8List 변환이 필요)
    );

    // 기존 이미지 로드 (이미지가 있는 경우)
    if (post.imageUrls.isNotEmpty) {
      _loadExistingImages(post.imageUrls);
    }
  }

  // 기존 이미지 로드 (URL → Uint8List)
  Future<void> _loadExistingImages(List<String> imageUrls) async {
    // 편의상 첫 번째 이미지만 로드 (필요시 여러 이미지 로드로 확장)
    if (imageUrls.isEmpty) return;

    try {
      final imageUrl = imageUrls.first;

      // 네트워크 이미지 로드 (http 패키지 사용)
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        state = state.copyWith(images: [imageBytes]);
      }
    } catch (e) {
      debugPrint('❌ 기존 이미지 로드 실패: $e');
      // 실패해도 계속 진행 (이미지 없이)
    }
  }

  Future<void> _submit() async {
    // 유효성 검사 (동일)
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
      debugPrint('🔄 CommunityWriteNotifier: 게시글 작성 시작');

      // 1. 게시글 ID 미리 생성
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;

      // 2. 이미지 업로드
      final List<Uri> imageUris = await _uploadImages(postId);

      // 3. 게시글 데이터 생성
      final usecase = ref.read(createPostUseCaseProvider);
      final createResult = await usecase.execute(
        postId: postId,
        title: state.title.trim(),
        content: state.content.trim(),
        hashTags: state.hashTags,
        imageUris: imageUris,
      );

      // AsyncValue 처리 - 즉시 return하거나 throw
      if (createResult case AsyncData(:final value)) {
        final createdPostId = value;

        debugPrint('✅ CommunityWriteNotifier: 게시글 생성 완료 - ID: $createdPostId');

        // 이벤트 발행
        ref
            .read(appEventNotifierProvider.notifier)
            .emit(AppEvent.postCreated(createdPostId));

        // 성공 상태 업데이트
        state = state.copyWith(submitting: false, createdPostId: createdPostId);
      } else if (createResult case AsyncError(:final error)) {
        throw Exception('게시글 생성 실패: $error');
      } else {
        throw Exception('게시글 생성 중 예상치 못한 상태');
      }
    } catch (e) {
      debugPrint('❌ CommunityWriteNotifier: 게시글 작성 실패 - $e');
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

  // 게시글 수정 메서드 추가
  Future<void> _update() async {
    // 유효성 검사 (기존 코드 재사용)
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

    // 원본 게시글 ID 확인
    final originalPostId = state.originalPostId;
    if (originalPostId == null) {
      state = state.copyWith(
        errorMessage: CommunityErrorMessages.postUpdateFailed,
      );
      return;
    }

    // 제출 시작
    state = state.copyWith(submitting: true, errorMessage: null);

    try {
      // 이미지 처리 (기존 이미지 교체 또는 유지)
      List<Uri> imageUris = [];
      if (state.images.isNotEmpty) {
        // 새 이미지 업로드
        imageUris = await _uploadImages(originalPostId);
      } else {
        // 기존 이미지 URL 그대로 유지하는 로직 (필요시)
      }

      // 게시글 업데이트
      final usecase = ref.read(updatePostUseCaseProvider);
      final updatedPostId = await usecase.execute(
        postId: originalPostId,
        title: state.title.trim(),
        content: state.content.trim(),
        hashTags: state.hashTags,
        imageUris: imageUris,
      );

      // 이벤트 발행
      if (updatedPostId.value != null) {
        ref
            .read(appEventNotifierProvider.notifier)
            .emit(AppEvent.postUpdated(updatedPostId.value!));
      } else {
        throw Exception('업데이트된 게시글 ID가 null입니다');
      }

      // 성공 상태 업데이트
      state = state.copyWith(
        submitting: false,
        updatedPostId: updatedPostId.value,
      );
    } catch (e) {
      debugPrint('❌ CommunityWriteNotifier: 게시글 수정 실패 - $e');
      // 실패 처리
      state = state.copyWith(
        submitting: false,
        errorMessage: CommunityErrorMessages.postUpdateFailed,
      );
    }
  }
}
