// lib/community/presentation/community_detail/community_detail_notifier.dart

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';

import 'package:devlink_mobile_app/community/domain/usecase/fetch_post_detail_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_like_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_bookmark_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_comments_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_comment_use_case.dart';

import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';

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

  /* ---------- build ---------- */
  @override
  CommunityDetailState build(String postId) {
    _postId = postId;
    _fetchDetail = ref.watch(fetchPostDetailUseCaseProvider);
    _toggleLike = ref.watch(toggleLikeUseCaseProvider);
    _toggleBookmark = ref.watch(toggleBookmarkUseCaseProvider);
    _fetchComments = ref.watch(fetchCommentsUseCaseProvider);
    _createComment = ref.watch(createCommentUseCaseProvider);

    // 초기 상태 → 비동기 로드
    _loadAll();
    return const CommunityDetailState();
  }

  /* ---------- public actions ---------- */
  Future<void> onAction(CommunityDetailAction action) async {
    switch (action) {
      case ToggleLike():
        final result = await _toggleLike.execute(_postId);
        state = state.copyWith(post: result);

      case ToggleBookmark():
        final result = await _toggleBookmark.execute(_postId);
        state = state.copyWith(post: result);

      case AddComment(:final content):
        final result = await _createComment.execute(
          postId: _postId,
          memberId: 'me', // TODO: 실제 로그인 유저 ID
          content: content,
        );
        state = state.copyWith(comments: result);
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

    state = state.copyWith(
      post: postResult,
      comments: commentResult,
    );
  }
}