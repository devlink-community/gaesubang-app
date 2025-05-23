// lib/community/presentation/community_list/community_list_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/usecase/load_post_list_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_notifier.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_list_notifier.g.dart';

@riverpod
class CommunityListNotifier extends _$CommunityListNotifier {
  @override
  CommunityListState build() {
    _loadPostListUseCase = ref.watch(loadPostListUseCaseProvider);

    // 글쓰기 완료 감지하여 자동 갱신
    ref.listen(
      communityWriteNotifierProvider.select((state) => state.createdPostId),
      (previous, current) {
        if (previous == null && current != null) {
          AppLogger.communityInfo('새 게시글 작성 완료 감지, 목록 갱신 시작: $current');
          Future.microtask(() => _fetch());
        }
      },
    );

    // 앱 이벤트 리스너 추가 - 게시글/댓글 변경 감지
    ref.listen(appEventNotifierProvider, (previous, current) {
      if (previous != current) {
        // 게시글 관련 이벤트 필터링
        final postEvents =
            current
                .where(
                  (event) =>
                      event is PostLiked ||
                      event is PostBookmarked ||
                      event is CommentAdded ||
                      event is PostUpdated ||
                      event is PostDeleted,
                )
                .toList();

        if (postEvents.isNotEmpty) {
          final eventTypes = postEvents
              .map((event) => event.runtimeType.toString())
              .join(', ');

          AppLogger.communityInfo('게시글 액션 이벤트 감지, 목록 갱신: [$eventTypes]');
          Future.microtask(() => _fetch());
        }
      }
    });

    AppLogger.communityInfo('CommunityListNotifier 초기화 완료');
    return const CommunityListState(currentTab: CommunityTabType.newest);
  }

  late final LoadPostListUseCase _loadPostListUseCase;

  /// 원격 새로고침
  Future<void> _fetch() async {
    AppLogger.communityInfo('게시글 목록 로드 시작');
    state = state.copyWith(postList: const AsyncLoading());

    try {
      final result = await _loadPostListUseCase.execute();

      // switch-case 패턴 사용
      switch (result) {
        case AsyncData(:final value):
          final sortedPosts = _applySort(value, state.currentTab);
          state = state.copyWith(postList: AsyncData(sortedPosts));
          AppLogger.communityInfo(
            '게시글 목록 로드 완료: ${sortedPosts.length}개 (탭: ${state.currentTab.name})',
          );

        case AsyncError(:final error, :final stackTrace):
          state = state.copyWith(postList: AsyncError(error, stackTrace));
          AppLogger.communityError(
            '게시글 목록 로드 실패',
            error: error,
            stackTrace: stackTrace,
          );

        case AsyncLoading():
          // 로딩 상태는 이미 설정됨
          break;
      }
    } catch (e, st) {
      state = state.copyWith(postList: AsyncError(e, st));
      AppLogger.communityError('게시글 목록 로드 중 예외 발생', error: e, stackTrace: st);
    }
  }

  /// 탭 변경·수동 새로고침 등 외부 Action 진입점
  Future<void> onAction(CommunityListAction action) async {
    switch (action) {
      case Refresh():
        AppLogger.communityInfo('사용자 요청으로 게시글 목록 새로고침');
        await _fetch();

      case ChangeTab(:final tab):
        AppLogger.communityInfo('탭 변경: ${state.currentTab.name} → ${tab.name}');
        state = state.copyWith(currentTab: tab);
        await _fetch();

      case TapSearch():
        AppLogger.ui('검색 버튼 클릭');
        break;

      case TapWrite():
        AppLogger.ui('글쓰기 버튼 클릭');
        break;

      case TapPost(:final postId):
        AppLogger.ui('게시글 클릭: $postId');
        break;
    }
  }

  List<Post> _applySort(List<Post> list, CommunityTabType tab) {
    AppLogger.debug('게시글 정렬 적용: ${tab.name}, 개수: ${list.length}');

    switch (tab) {
      case CommunityTabType.popular:
        final sorted = [...list]..sort(
          (a, b) => b.likeCount.compareTo(a.likeCount),
        );
        return sorted;

      case CommunityTabType.newest:
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
    }
  }

  Future<void> loadInitialData() async {
    AppLogger.communityInfo('초기 데이터 로드 시작');
    await _fetch();
  }
}
