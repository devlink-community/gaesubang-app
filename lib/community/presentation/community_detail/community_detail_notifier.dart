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
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
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
    AppLogger.communityInfo('CommunityDetailNotifier 초기화 시작: $postId');

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
    //       AppLogger.communityInfo('프로필 업데이트 감지, 게시글 새로고침: $postId');
    //       _loadAll();
    //     }
    //   }
    // });

    // 초기 상태 → 비동기 로드
    _loadAll();
    AppLogger.communityInfo('CommunityDetailNotifier 초기화 완료: $postId');
    return const CommunityDetailState();
  }

  /* ---------- public actions ---------- */
  Future<void> onAction(CommunityDetailAction action) async {
    AppLogger.debug(
      'CommunityDetailAction 수신: ${action.runtimeType}',
      tag: 'CommunityDetail',
    );

    switch (action) {
      case Refresh():
        AppLogger.communityInfo('사용자 요청으로 게시글 새로고침: $_postId');
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
        AppLogger.communityInfo('게시글 수정 요청: $_postId');
    }
  }

  Future<bool> _handleDeletePost() async {
    AppLogger.logBox('게시글 삭제', '게시글 삭제 프로세스 시작: $_postId');

    try {
      final result = await _deletePostUseCase.execute(_postId);

      switch (result) {
        case AsyncData(:final value) when value:
          // 삭제 성공 시 이벤트 발행
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.postDeleted(_postId));
          AppLogger.communityInfo('게시글 삭제 성공 및 이벤트 발행: $_postId');
          return true;

        case AsyncError(:final error):
          AppLogger.communityError('게시글 삭제 실패', error: error);
          return false;

        default:
          AppLogger.communityError('게시글 삭제 실패: 예상치 못한 결과');
          return false;
      }
    } catch (e, st) {
      AppLogger.communityError('게시글 삭제 중 예외 발생', error: e, stackTrace: st);
      return false;
    }
  }

  /* ---------- internal handlers ---------- */
  // 좋아요 처리 및 이벤트 발행
  Future<void> _handleLike() async {
    AppLogger.communityInfo('좋아요 토글 시작: $_postId');
    state = state.copyWith(post: const AsyncLoading());

    try {
      final result = await _toggleLike.execute(_postId);
      state = state.copyWith(post: result);

      // 결과에 따른 로깅
      switch (result) {
        case AsyncData(:final value):
          final likeStatus = value.isLikedByCurrentUser ? '추가' : '취소';
          AppLogger.communityInfo(
            '좋아요 $likeStatus 완료: $_postId (총 ${value.likeCount}개)',
          );

          // 이벤트 발행: 좋아요 상태 변경됨
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.postLiked(_postId));

        case AsyncError(:final error):
          AppLogger.communityError('좋아요 토글 실패', error: error);
      }
    } catch (e, st) {
      AppLogger.communityError('좋아요 토글 중 예외 발생', error: e, stackTrace: st);
    }
  }

  // 북마크 처리 및 이벤트 발행
  Future<void> _handleBookmark() async {
    AppLogger.communityInfo('북마크 토글 시작: $_postId');
    state = state.copyWith(post: const AsyncLoading());

    try {
      final result = await _toggleBookmark.execute(_postId);
      state = state.copyWith(post: result);

      // 결과에 따른 로깅
      switch (result) {
        case AsyncData(:final value):
          final bookmarkStatus = value.isBookmarkedByCurrentUser ? '추가' : '제거';
          AppLogger.communityInfo('북마크 $bookmarkStatus 완료: $_postId');

          // 이벤트 발행: 북마크 상태 변경됨
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.postBookmarked(_postId));

        case AsyncError(:final error):
          AppLogger.communityError('북마크 토글 실패', error: error);
      }
    } catch (e, st) {
      AppLogger.communityError('북마크 토글 중 예외 발생', error: e, stackTrace: st);
    }
  }

  // 댓글 추가 및 이벤트 발행
  Future<void> _handleAddComment(String content) async {
    AppLogger.communityInfo('댓글 추가 시작: $_postId, 내용 길이: ${content.length}자');
    state = state.copyWith(comments: const AsyncLoading());

    try {
      final result = await _createComment.execute(
        postId: _postId,
        content: content,
      );
      state = state.copyWith(comments: result);

      // 결과에 따른 로깅
      switch (result) {
        case AsyncData(:final value):
          AppLogger.communityInfo('댓글 추가 완료: $_postId (총 ${value.length}개)');

          // 이벤트 발행: 댓글 추가됨
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.commentAdded(_postId, "unknown"));

          // 게시글 데이터도 함께 새로고침 (댓글 카운트 반영)
          await _refreshPostDetail();

        case AsyncError(:final error):
          AppLogger.communityError('댓글 추가 실패', error: error);
      }
    } catch (e, st) {
      AppLogger.communityError('댓글 추가 중 예외 발생', error: e, stackTrace: st);
    }
  }

  // 댓글 좋아요 처리 및 이벤트 발행
  Future<void> _handleCommentLike(String commentId) async {
    AppLogger.communityInfo('댓글 좋아요 토글 시작: $_postId, 댓글: $commentId');

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

          final likeStatus = value.isLikedByCurrentUser ? '추가' : '취소';
          AppLogger.communityInfo(
            '댓글 좋아요 $likeStatus 완료: $commentId (총 ${value.likeCount}개)',
          );

          // 이벤트 발행: 댓글 좋아요 상태 변경됨
          ref
              .read(appEventNotifierProvider.notifier)
              .emit(AppEvent.commentLiked(_postId, commentId));

        case AsyncError(:final error, :final stackTrace):
          // 실패: 에러 상태로 갱신
          AppLogger.communityError(
            '댓글 좋아요 토글 실패',
            error: error,
            stackTrace: stackTrace,
          );

        case AsyncLoading():
          // 로딩: 무시 (이미 처리됨)
          break;
      }
    } catch (e, st) {
      AppLogger.communityError('댓글 좋아요 토글 중 예외 발생', error: e, stackTrace: st);
    }
  }

  /* ---------- internal utility methods ---------- */
  // 게시글과 댓글 모두 로드
  Future<void> _loadAll() async {
    AppLogger.logStep(1, 3, '게시글 및 댓글 로드 시작: $_postId');

    // 1) 로딩 표시
    state = const CommunityDetailState(
      post: AsyncLoading(),
      comments: AsyncLoading(),
    );

    try {
      AppLogger.logStep(2, 3, '게시글 상세 정보 요청');
      final postResult = await _fetchDetail.execute(_postId);

      AppLogger.logStep(3, 3, '댓글 목록 요청');
      final commentResult = await _fetchComments.execute(_postId);

      state = state.copyWith(post: postResult, comments: commentResult);

      // 결과 로깅
      final postStatus = switch (postResult) {
        AsyncData(:final value) => '성공 (제목: ${value.title})',
        AsyncError() => '실패',
        _ => '로딩중',
      };

      final commentStatus = switch (commentResult) {
        AsyncData(:final value) => '성공 (${value.length}개)',
        AsyncError() => '실패',
        _ => '로딩중',
      };

      AppLogger.communityInfo(
        '데이터 로드 완료: $_postId | 게시글: $postStatus, 댓글: $commentStatus',
      );
    } catch (e, st) {
      AppLogger.communityError('데이터 로드 중 예외 발생', error: e, stackTrace: st);
    }
  }

  // 게시글만 새로고침 (댓글 카운트 등 업데이트)
  Future<void> _refreshPostDetail() async {
    AppLogger.debug('게시글 정보만 새로고침: $_postId');

    try {
      final postResult = await _fetchDetail.execute(_postId);
      state = state.copyWith(post: postResult);

      if (postResult case AsyncData(:final value)) {
        AppLogger.debug('게시글 정보 새로고침 완료: ${value.commentCount}개 댓글');
      }
    } catch (e, st) {
      AppLogger.warning('게시글 정보 새로고침 실패 (무시됨)', error: e, stackTrace: st);
      // 에러는 무시 (댓글 추가 후 게시글 정보 갱신 실패는 UX에 크게 영향 없음)
    }
  }
}
