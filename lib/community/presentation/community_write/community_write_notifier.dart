// lib/community/presentation/community_write/community_write_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:devlink_mobile_app/storage/module/storage_di.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_write_notifier.g.dart';

@riverpod
class CommunityWriteNotifier extends _$CommunityWriteNotifier {
  @override
  CommunityWriteState build() => const CommunityWriteState();

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
      // 1. 게시글 ID 미리 생성 (Firebase에서 자동 생성되는 ID)
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;

      // 2. 이미지 업로드 (리팩토링 부분)
      final List<Uri> imageUris = await _uploadImages(postId);

      // 3. 게시글 데이터 생성 (postId 전달)
      final usecase = ref.read(createPostUseCaseProvider);
      final createdPostId = await usecase.execute(
        postId: postId, // 미리 생성한 ID 전달
        title: state.title.trim(),
        content: state.content.trim(),
        hashTags: state.hashTags,
        imageUris: imageUris,
      );

      // 4. 성공 상태 업데이트
      state = state.copyWith(submitting: false, createdPostId: createdPostId);
    } catch (e) {
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
      const currentUserId = 'user1';

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
