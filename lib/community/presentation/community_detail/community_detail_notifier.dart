import 'dart:async';

import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_comment_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/delete_post_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_comments_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_post_detail_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_bookmark_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_comment_like_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_like_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_state.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart'; // 추가된 import
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart'; // 추가된 import
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_detail_notifier.g.dart';

@riverpod
class CommunityDetailNotifier extends _$CommunityDetailNotifier {
  /* ---------- private fields ---------- */
  late final String _postId;
  late final FetchPostDetailUseCase _fetchDetail;
  late final ToggleLikeUseCase _toggleLike;
  late final ToggleBookmarkUseCase _toggleBookmark;
  late final FetchCommentsUseCase _fetchComments;
  late final CreateCommentUseCase _createComment;
  late final ToggleCommentLikeUseCase _toggleCommentLike;
  late final DeletePostUseCase _deletePostUseCase;

  /* ---------- build ---------- */
  @override
  CommunityDetailState build(String postId) {
    debugPrint('🔄 CommunityDetailNotifier: build(postId: $postId)');

    _postId = postId;
    _fetchDetail = ref.watch(fetchPostDetailUseCaseProvider);
    _toggleLike = ref.watch(toggleLikeUseCaseProvider);
    _toggleBookmark = ref.watch(toggleBookmarkUseCaseProvider);
    _fetchComments = ref.watch(fetchCommentsUseCaseProvider);
    _createComment = ref.watch(createCommentUseCaseProvider);
    _toggleCommentLike = ref.watch(toggleCommentLikeUseCaseProvider);
    _deletePostUseCase = ref.watch(deletePostUseCaseProvider);

    // // 이벤트 리스너로 프로필 업데이트를 감지하여 화면 새로고침
    // ref.listen(appEventNotifierProvider, (previous, current) {
    //   if (previous != current) {
    //     final eventNotifier = ref.read(appEventNotifierProvider.notifier);
    //
    //     // 프로필 변경 이벤트가 있으면 화면 새로고침
    //     if (eventNotifier.hasEventOfType<ProfileUpdated>()) {
    //       debugPrint('🔄 CommunityDetailNotifier: 프로필 업데이트 감지, 게시글 새로고침');
    //       _loadAll();
    //     }
    //   }
    // });

    // 초기 상태 → 비동기 로드
    _loadAll();
    return const CommunityDetailState();
  }

  /* ---------- public actions ---------- */
  Future<void> onAction(CommunityDetailAction action) async {
    debugPrint('🔄 CommunityDetailNotifier: onAction($action)');

    switch (action) {
      case Refresh():
        await _loadAll();

      case ToggleLike():
        await _handleLike();

      case ToggleBookmark():
        await _handleBookmark();

      case AddComment(:final content):
        await _handleAddComment(content);

      // 댓글 좋아요 액션 처리
      case ToggleCommentLike(:final commentId):
        await _handleCommentLike(commentId);

      case DeletePost():
        await _handleDeletePost();

      case EditPost():
        debugPrint('📝 CommunityDetailNotifier: EditPost action received');
    }
  }

  Future<bool> _handleDeletePost() async {
    debugPrint('🔄 CommunityDetailNotifier: 게시글 삭제 시작');

    try {
      final result = await _deletePostUseCase.execute(_postId);

      switch (result) {
        case AsyncData(:final value) when value:
          // 삭제 성공 시 이벤트 발행
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.postDeleted(_postId));
          debugPrint('✅ CommunityDetailNotifier: 게시글 삭제 성공 및 이벤트 발행');
          return true;

        case AsyncError(:final error):
          debugPrint('❌ CommunityDetailNotifier: 게시글 삭제 오류: $error');
          return false;

        default:
          debugPrint('❌ CommunityDetailNotifier: 게시글 삭제 실패');
          return false;
      }
    } catch (e) {
      debugPrint('❌ CommunityDetailNotifier: 게시글 삭제 중 예외 발생: $e');
      return false;
    }
  }

  /* ---------- internal handlers ---------- */
  // 좋아요 처리 및 이벤트 발행
  Future<void> _handleLike() async {
    debugPrint('🔄 CommunityDetailNotifier: 좋아요 토글 시작');
    state = state.copyWith(post: const AsyncLoading());

    try {
      final result = await _toggleLike.execute(_postId);
      state = state.copyWith(post: result);

      // 이벤트 발행: 좋아요 상태 변경됨
      ref
          .read(appEventNotifierProvider.notifier)
          .emit(AppEvent.postLiked(_postId));

      debugPrint('✅ CommunityDetailNotifier: 좋아요 토글 완료 및 이벤트 발행');
    } catch (e) {
      debugPrint('❌ CommunityDetailNotifier: 좋아요 토글 오류: $e');
      // 에러 처리는 AsyncValue 내부에서 자동으로 처리됨
    }
  }

  // 북마크 처리 및 이벤트 발행
  Future<void> _handleBookmark() async {
    debugPrint('🔄 CommunityDetailNotifier: 북마크 토글 시작');
    state = state.copyWith(post: const AsyncLoading());

    try {
      final result = await _toggleBookmark.execute(_postId);
      state = state.copyWith(post: result);

      // 이벤트 발행: 북마크 상태 변경됨
      ref
          .read(appEventNotifierProvider.notifier)
          .emit(AppEvent.postBookmarked(_postId));

      debugPrint('✅ CommunityDetailNotifier: 북마크 토글 완료 및 이벤트 발행');
    } catch (e) {
      debugPrint('❌ CommunityDetailNotifier: 북마크 토글 오류: $e');
      // 에러 처리는 AsyncValue 내부에서 자동으로 처리됨
    }
  }

  // 댓글 추가 및 이벤트 발행
  Future<void> _handleAddComment(String content) async {
    debugPrint('🔄 CommunityDetailNotifier: 댓글 추가 시작');
    state = state.copyWith(comments: const AsyncLoading());

    try {
      final result = await _createComment.execute(
        postId: _postId,
        content: content,
      );
      state = state.copyWith(comments: result);

      // 이벤트 발행: 댓글 추가됨 (생성된 댓글 ID는 모르지만 POST_ID는 알고 있음)
      ref
          .read(appEventNotifierProvider.notifier)
          .emit(AppEvent.commentAdded(_postId, "unknown"));

      // 게시글 데이터도 함께 새로고침 (댓글 카운트 반영)
      await _refreshPostDetail();

      debugPrint('✅ CommunityDetailNotifier: 댓글 추가 완료 및 이벤트 발행');
    } catch (e) {
      debugPrint('❌ CommunityDetailNotifier: 댓글 추가 오류: $e');
      // 에러 처리는 AsyncValue 내부에서 자동으로 처리됨
    }
  }

  // 댓글 좋아요 처리 및 이벤트 발행
  Future<void> _handleCommentLike(String commentId) async {
    debugPrint(
      '🔄 CommunityDetailNotifier: 댓글 좋아요 토글 시작 (commentId: $commentId)',
    );

    try {
      // 기존 comments 배열 가져오기
      final currentComments = switch (state.comments) {
        AsyncData(:final value) => value,
        _ => <Comment>[], // 로딩 중이거나 에러일 경우 빈 배열 반환
      };

      // toggleCommentLike UseCase 호출
      final result = await _toggleCommentLike.execute(_postId, commentId);

      // 결과에 따라 처리
      switch (result) {
        case AsyncData(:final value):
          // 성공: 변경된 댓글로 기존 댓글 업데이트
          final updatedComments =
              currentComments.map((comment) {
                // ID가 일치하는 댓글만 업데이트
                if (comment.id == commentId) {
                  return value; // 업데이트된 댓글
                }
                return comment; // 기존 댓글 유지
              }).toList();

          // 업데이트된 댓글 목록으로 상태 갱신
          state = state.copyWith(comments: AsyncData(updatedComments));

          // 이벤트 발행: 댓글 좋아요 상태 변경됨
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.commentLiked(_postId, commentId));

          debugPrint('✅ CommunityDetailNotifier: 댓글 좋아요 토글 완료 및 이벤트 발행');

        case AsyncError(:final error, :final stackTrace):
          // 실패: 에러 상태로 갱신
          debugPrint('❌ CommunityDetailNotifier: 댓글 좋아요 토글 오류: $error');
        // 전체 comments 에러로 설정하기보다 토스트 메시지 등으로 처리할 수 있음
        // 여기서는 간단히 처리

        case AsyncLoading():
          // 로딩: 무시 (이미 처리됨)
          break;
      }
    } catch (e) {
      debugPrint('❌ CommunityDetailNotifier: 댓글 좋아요 토글 중 예외 발생: $e');
    }
  }

  /* ---------- internal utility methods ---------- */
  // 게시글과 댓글 모두 로드
  Future<void> _loadAll() async {
    debugPrint('🔄 CommunityDetailNotifier: 게시글 및 댓글 로드 시작');

    // 1) 로딩 표시
    state = const CommunityDetailState(
      post: AsyncLoading(),
      comments: AsyncLoading(),
    );

    // 2) 동시 요청
    final postResult = await _fetchDetail.execute(_postId);
    final commentResult = await _fetchComments.execute(_postId);

    state = state.copyWith(post: postResult, comments: commentResult);
    debugPrint('✅ CommunityDetailNotifier: 게시글 및 댓글 로드 완료');
  }

  // 게시글만 새로고침 (댓글 카운트 등 업데이트)
  Future<void> _refreshPostDetail() async {
    debugPrint('🔄 CommunityDetailNotifier: 게시글 정보만 새로고침');

    try {
      final postResult = await _fetchDetail.execute(_postId);
      state = state.copyWith(post: postResult);
      debugPrint('✅ CommunityDetailNotifier: 게시글 정보 새로고침 완료');
    } catch (e) {
      debugPrint('❌ CommunityDetailNotifier: 게시글 정보 새로고침 오류: $e');
      // 에러는 무시 (댓글 추가 후 게시글 정보 갱신 실패는 UX에 크게 영향 없음)
    }
  }
}
