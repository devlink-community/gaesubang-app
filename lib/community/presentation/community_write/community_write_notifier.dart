// lib/community/presentation/community_write/community_write_notifier.dart
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_post_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_write_notifier.g.dart';

@riverpod
class CommunityWriteNotifier extends _$CommunityWriteNotifier {
  final _random = Random();

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
          state = state.copyWith(errorMessage: '이미지는 최대 5개까지 추가할 수 있습니다.');
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
    }
  }

  // lib/community/presentation/community_write/community_write_notifier.dart
  // _submit 메서드 수정

  Future<void> _submit() async {
    // 유효성 검사
    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: '제목을 입력해주세요.');
      return;
    }

    if (state.content.trim().isEmpty) {
      state = state.copyWith(errorMessage: '내용을 입력해주세요.');
      return;
    }

    // 제출 시작
    state = state.copyWith(submitting: true, errorMessage: null);

    try {
      // 1. 게시글 ID 미리 생성 (Firebase에서 자동 생성되는 ID)
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;

      // 2. 이미지 업로드 (해당 postId 사용)
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
        errorMessage: '게시글 작성에 실패했습니다: $e',
      );
    }
  }

  // 이미지 업로드 함수
  Future<List<Uri>> _uploadImages(String postId) async {
    if (state.images.isEmpty) {
      return [];
    }

    final storage = FirebaseStorage.instance;
    final List<Uri> uploadedUris = [];

    // 현재 사용자 ID (임시로 'user1' 사용)
    const currentUserId = 'user1';

    for (int i = 0; i < state.images.length; i++) {
      final imageBytes = state.images[i];

      // 더 간단한 파일명 사용
      final fileName = 'image_$i.jpg';

      // 경로 형식: posts/{작성한 유저의 uid}/{Post의 uid}/{파일}
      final storagePath = 'posts/$currentUserId/$postId/$fileName';

      try {
        // UploadTask 생성 및 메타데이터 설정
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': fileName},
        );

        // 바이트 데이터 직접 업로드 (임시 파일 생성 없이)
        final uploadTask = storage
            .ref(storagePath)
            .putData(imageBytes, metadata);

        // 업로드 완료 대기
        final taskSnapshot = await uploadTask;

        // 다운로드 URL 가져오기
        final downloadUrl = await taskSnapshot.ref.getDownloadURL();
        uploadedUris.add(Uri.parse(downloadUrl));

        print('이미지 업로드 성공: $fileName');
      } catch (e, stackTrace) {
        // 상세한 오류 정보 로깅
        print('이미지 업로드 실패: $e');
        print('스택 트레이스: $stackTrace');
      }
    }

    return uploadedUris;
  }
}
