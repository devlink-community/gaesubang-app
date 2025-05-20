// lib/community/presentation/community_detail/community_detail_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_comment_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_comments_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_post_detail_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_bookmark_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_comment_like_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_like_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_state.dart';
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

  /* ---------- build ---------- */
  @override
  CommunityDetailState build(String postId) {
    _postId = postId;
    _fetchDetail = ref.watch(fetchPostDetailUseCaseProvider);
    _toggleLike = ref.watch(toggleLikeUseCaseProvider);
    _toggleBookmark = ref.watch(toggleBookmarkUseCaseProvider);
    _fetchComments = ref.watch(fetchCommentsUseCaseProvider);
    _createComment = ref.watch(createCommentUseCaseProvider);
    _toggleCommentLike = ref.watch(toggleCommentLikeUseCaseProvider);

    // 초기 상태 → 비동기 로드
    _loadAll();
    return const CommunityDetailState();
  }

  /* ---------- public actions ---------- */
  // lib/community/presentation/community_detail/community_detail_notifier.dart 의 onAction 메서드에 추가할 코드

  /* ---------- public actions ---------- */
  Future<void> onAction(CommunityDetailAction action) async {
    switch (action) {
      case Refresh():
        await _loadAll();

      case ToggleLike():
        state = state.copyWith(post: const AsyncLoading());
        final result = await _toggleLike.execute(_postId);
        state = state.copyWith(post: result);

      case ToggleBookmark():
        state = state.copyWith(post: const AsyncLoading());
        final result = await _toggleBookmark.execute(_postId);
        state = state.copyWith(post: result);

      case AddComment(:final content):
        state = state.copyWith(comments: const AsyncLoading());
        final result = await _createComment.execute(
          postId: _postId,
          content: content,
        );
        state = state.copyWith(comments: result);

      // 새로 추가된 액션 처리
      case ToggleCommentLike(:final commentId):
        // 기존 comments 배열 가져오기
        final currentComments = switch (state.comments) {
          AsyncData(:final value) => value,
          _ => <Comment>[], // 로딩 중이거나 에러일 경우 빈 배열 반환
        };

        // 해당 댓글에 대해서만 로딩 상태 표시 (전체 comments는 유지)
        // 나중에 UI에서 특정 댓글만 로딩 표시할 수 있도록 처리

        // toggleCommentLike UseCase 호출
        final result = await _toggleCommentLike.execute(_postId, commentId);

        // 결과에 따라 처리
        switch (result) {
          case AsyncData(:final value):
            // 성공: 변경된 댓글로 기존 댓글 업데이트
            final updatedComments =
                currentComments.map((comment) {
                  // 해당 ID의 댓글만 업데이트
                  if (comment.userId == value.userId &&
                      comment.createdAt == value.createdAt) {
                    return value; // 업데이트된 댓글
                  }
                  return comment; // 기존 댓글 유지
                }).toList();

            // 업데이트된 댓글 목록으로 상태 갱신
            state = state.copyWith(comments: AsyncData(updatedComments));

          case AsyncError(:final error, :final stackTrace):
            // 실패: 에러 상태로 갱신
            // 전체 comments 에러로 설정하기보다 토스트 메시지 등으로 처리하는 것이 좋을 수 있음
            // 여기서는 간단히 전체 갱신으로 처리
            state = state.copyWith(comments: AsyncError(error, stackTrace));

          case AsyncLoading():
            // 로딩: 무시 (이미 처리됨)
            break;
        }
    }
  }

  /* ---------- internal ---------- */
  Future<void> _loadAll() async {
    // 1) 로딩 표시
    state = const CommunityDetailState(
      post: AsyncLoading(),
      comments: AsyncLoading(),
    );

    // 2) 동시 요청
    final postResult = await _fetchDetail.execute(_postId);
    final commentResult = await _fetchComments.execute(_postId);

    state = state.copyWith(post: postResult, comments: commentResult);
  }
}
