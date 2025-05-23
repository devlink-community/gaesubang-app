// lib/community/presentation/community_write/community_write_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
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

    AppLogger.communityInfo('CommunityWriteNotifier 초기화 완료');
    return const CommunityWriteState();
  }

  Future<void> onAction(CommunityWriteAction action) async {
    AppLogger.debug(
      'CommunityWriteAction 수신: ${action.runtimeType}',
      tag: 'CommunityWrite',
    );

    switch (action) {
      case TitleChanged(:final title):
        AppLogger.debug('제목 변경: ${title.length}자');
        state = state.copyWith(title: title);

      case ContentChanged(:final content):
        AppLogger.debug('내용 변경: ${content.length}자');
        state = state.copyWith(content: content);

      case TagAdded(:final tag):
        if (tag.trim().isEmpty) {
          AppLogger.warning('빈 태그 추가 시도 무시');
          return;
        }
        // 이미 존재하는 태그라면 추가하지 않음
        if (state.hashTags.contains(tag.trim())) {
          AppLogger.warning('중복 태그 추가 시도: $tag');
          return;
        }

        final newTags = [...state.hashTags, tag.trim()];
        state = state.copyWith(hashTags: newTags);
        AppLogger.info('태그 추가: $tag (총 ${newTags.length}개)');

      case TagRemoved(:final tag):
        final newTags = state.hashTags.where((t) => t != tag).toList();
        state = state.copyWith(hashTags: newTags);
        AppLogger.info('태그 제거: $tag (남은 ${newTags.length}개)');

      case ImageAdded(:final bytes):
        // 이미지 최대 5개로 제한
        if (state.images.length >= 5) {
          AppLogger.warning('이미지 최대 개수 초과: ${state.images.length}개');
          state = state.copyWith(
            errorMessage: CommunityErrorMessages.tooManyImages,
          );
          return;
        }

        state = state.copyWith(
          images: [...state.images, bytes],
          errorMessage: null,
        );
        AppLogger.info(
          '이미지 추가: ${bytes.length}바이트 (총 ${state.images.length}개)',
        );

      case ImageRemoved(:final index):
        if (index < 0 || index >= state.images.length) {
          AppLogger.warning('잘못된 이미지 인덱스 제거 시도: $index');
          return;
        }

        final newImages = [...state.images];
        newImages.removeAt(index);
        state = state.copyWith(images: newImages);
        AppLogger.info('이미지 제거: 인덱스 $index (남은 ${newImages.length}개)');

      case Submit():
        // 수정 모드에 따라 다른 메서드 호출
        if (state.isEditMode) {
          AppLogger.logBox('게시글 수정', '게시글 수정 프로세스 시작: ${state.originalPostId}');
          await _update(); // 게시글 수정
        } else {
          AppLogger.logBox('게시글 작성', '새 게시글 작성 프로세스 시작');
          await _submit(); // 게시글 생성
        }

      case NavigateBack(:final postId):
        AppLogger.navigation('게시글 작성 완료 후 뒤로가기: $postId');
        // Root에서 처리하므로 여기서는 아무 것도 하지 않음
        break;
    }
  }

  void initWithPost(Post post) {
    if (state.isEditMode) {
      AppLogger.warning('이미 수정 모드로 초기화됨 - 중복 초기화 방지');
      return; // 이미 초기화된 경우 중복 방지
    }

    AppLogger.communityInfo('게시글 수정 모드 초기화: ${post.id}');

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
      AppLogger.info('기존 이미지 로드 시작: ${post.imageUrls.length}개');
      _loadExistingImages(post.imageUrls);
    }
  }

  // 기존 이미지 로드 (URL → Uint8List)
  Future<void> _loadExistingImages(List<String> imageUrls) async {
    // 편의상 첫 번째 이미지만 로드 (필요시 여러 이미지 로드로 확장)
    if (imageUrls.isEmpty) return;

    try {
      final imageUrl = imageUrls.first;
      AppLogger.debug('기존 이미지 다운로드 시작: $imageUrl');

      // 네트워크 이미지 로드 (http 패키지 사용)
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        state = state.copyWith(images: [imageBytes]);
        AppLogger.info('기존 이미지 로드 완료: ${imageBytes.length}바이트');
      } else {
        AppLogger.warning('기존 이미지 로드 실패: HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      AppLogger.warning('기존 이미지 로드 실패 (계속 진행)', error: e, stackTrace: st);
      // 실패해도 계속 진행 (이미지 없이)
    }
  }

  Future<void> _submit() async {
    AppLogger.logStep(1, 5, '게시글 작성 유효성 검사');

    // 유효성 검사
    if (state.title.trim().isEmpty) {
      AppLogger.warning('제목 누락으로 게시글 작성 실패');
      state = state.copyWith(
        errorMessage: CommunityErrorMessages.titleRequired,
      );
      return;
    }

    if (state.content.trim().isEmpty) {
      AppLogger.warning('내용 누락으로 게시글 작성 실패');
      state = state.copyWith(
        errorMessage: CommunityErrorMessages.contentRequired,
      );
      return;
    }

    // 제출 시작
    state = state.copyWith(submitting: true, errorMessage: null);
    AppLogger.logStep(2, 5, '게시글 작성 프로세스 시작');

    try {
      // 1. 게시글 ID 미리 생성
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      AppLogger.logStep(3, 5, '게시글 ID 생성 완료: $postId');

      // 2. 이미지 업로드
      AppLogger.logStep(4, 5, '이미지 업로드 시작: ${state.images.length}개');
      final List<Uri> imageUris = await _uploadImages(postId);
      AppLogger.info('이미지 업로드 완료: ${imageUris.length}개');

      // 3. 게시글 데이터 생성
      AppLogger.logStep(5, 5, '게시글 데이터 저장');
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

        AppLogger.communityInfo('게시글 생성 성공: $createdPostId');

        // 이벤트 발행
        ref
            .read(appEventNotifierProvider.notifier)
            .emit(AppEvent.postCreated(createdPostId));

        // 성공 상태 업데이트
        state = state.copyWith(submitting: false, createdPostId: createdPostId);

        AppLogger.logBanner('새 게시글 작성 완료! 🎉');
      } else if (createResult case AsyncError(:final error)) {
        throw Exception('게시글 생성 실패: $error');
      } else {
        throw Exception('게시글 생성 중 예상치 못한 상태');
      }
    } catch (e, st) {
      AppLogger.communityError('게시글 작성 실패', error: e, stackTrace: st);
      state = state.copyWith(
        submitting: false,
        errorMessage: CommunityErrorMessages.postCreateFailed,
      );
    }
  }

  // 리팩토링된 이미지 업로드 메서드
  Future<List<Uri>> _uploadImages(String postId) async {
    if (state.images.isEmpty) {
      AppLogger.debug('업로드할 이미지 없음');
      return [];
    }

    try {
      // 현재 사용자 ID
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception(CommunityErrorMessages.loginRequired);
      }
      final currentUserId = currentUser.uid;

      AppLogger.info(
        '이미지 업로드 시작: ${state.images.length}개, 사용자: $currentUserId',
      );

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
    } catch (e, st) {
      // 에러 처리
      AppLogger.networkError('이미지 업로드 실패', error: e, stackTrace: st);
      throw Exception('이미지 업로드에 실패했습니다: $e');
    }
  }

  // 게시글 수정 메서드 추가
  Future<void> _update() async {
    AppLogger.logStep(1, 4, '게시글 수정 유효성 검사');

    // 원본 게시글 ID 확인
    final originalPostId = state.originalPostId;
    if (originalPostId == null) {
      AppLogger.communityError('원본 게시글 ID 누락으로 수정 실패');
      state = state.copyWith(
        errorMessage: CommunityErrorMessages.postUpdateFailed,
      );
      return;
    }

    // 제출 시작
    state = state.copyWith(submitting: true, errorMessage: null);
    AppLogger.logStep(2, 4, '게시글 수정 프로세스 시작: $originalPostId');

    try {
      // 이미지 처리
      AppLogger.logStep(3, 4, '이미지 처리: ${state.images.length}개');
      List<Uri> imageUris = [];
      if (state.images.isNotEmpty) {
        imageUris = await _uploadImages(originalPostId);
      }

      // 게시글 업데이트
      AppLogger.logStep(4, 4, '게시글 데이터 업데이트');
      final usecase = ref.read(updatePostUseCaseProvider);
      final updateResult = await usecase.execute(
        postId: originalPostId,
        title: state.title.trim(),
        content: state.content.trim(),
        hashTags: state.hashTags,
        imageUris: imageUris,
      );

      // AsyncValue 처리
      if (updateResult case AsyncData(:final value)) {
        final updatedPostId = value;

        AppLogger.communityInfo('게시글 수정 성공: $updatedPostId');

        // 이벤트 발행
        ref
            .read(appEventNotifierProvider.notifier)
            .emit(AppEvent.postUpdated(updatedPostId));

        // 성공 상태 업데이트
        state = state.copyWith(submitting: false, updatedPostId: updatedPostId);

        AppLogger.logBanner('게시글 수정 완료! ✨');
      } else if (updateResult case AsyncError(:final error)) {
        throw Exception('게시글 수정 실패: $error');
      } else {
        throw Exception('게시글 수정 중 예상치 못한 상태');
      }
    } catch (e, st) {
      AppLogger.communityError('게시글 수정 실패', error: e, stackTrace: st);
      state = state.copyWith(
        submitting: false,
        errorMessage: CommunityErrorMessages.postUpdateFailed,
      );
    }
  }
}
