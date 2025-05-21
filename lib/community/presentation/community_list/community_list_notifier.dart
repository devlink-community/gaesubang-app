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
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_list_notifier.g.dart';

@riverpod
class CommunityListNotifier extends _$CommunityListNotifier {
  @override
  CommunityListState build() {
    _loadPostListUseCase = ref.watch(loadPostListUseCaseProvider);

    // 글쓰기 완료 감지하여 자동 갱신
    // TODO: 차후 공통 이벤트 상태 관리 시스템으로 리팩토링 필요
    // 현재는 Mock 상태이므로 글쓰기 완료를 직접 감지하여 목록 갱신
    // 추후 AppEventNotifier 같은 중앙 이벤트 관리자로 대체 예정
    ref.listen(
      communityWriteNotifierProvider.select((state) => state.createdPostId),
      (previous, current) {
        if (previous == null && current != null) {
          Future.microtask(() => _fetch());
        }
      },
    );

    // 앱 이벤트 리스너 추가 - 게시글/댓글 변경 감지
    ref.listen(appEventNotifierProvider, (previous, current) {
      if (previous != current) {
        final eventNotifier = ref.read(appEventNotifierProvider.notifier);

        // // 프로필 변경 이벤트가 있으면 - 작성자 정보 관련이므로 목록 갱신
        // if (eventNotifier.hasEventOfType<ProfileUpdated>()) {
        //   debugPrint('🔄 CommunityListNotifier: 프로필 업데이트 감지, 목록 갱신');
        //   Future.microtask(() => _fetch());
        //   return;
        // }

        // 게시글 관련 이벤트가 있으면 목록 갱신
        final hasPostEvents = current.any(
          (event) =>
              event is PostLiked ||
              event is PostBookmarked ||
              event is CommentAdded ||
              event is PostUpdated,
        );

        if (hasPostEvents) {
          debugPrint('🔄 CommunityListNotifier: 게시글 액션 이벤트 감지, 목록 갱신');
          Future.microtask(() => _fetch());
        }
      }
    });

    Future.microtask(_fetch);
    return const CommunityListState(currentTab: CommunityTabType.newest);
  }

  late final LoadPostListUseCase _loadPostListUseCase;

  /// 원격 새로고침
  Future<void> _fetch() async {
    print('CommunityListNotifier: _fetch() started');
    state = state.copyWith(postList: const AsyncLoading());

    try {
      final result = await _loadPostListUseCase.execute();
      print('CommunityListNotifier: UseCase executed, processing result...');

      // switch-case 패턴 사용
      switch (result) {
        case AsyncData(:final value):
          final sortedPosts = _applySort(value, state.currentTab);
          state = state.copyWith(postList: AsyncData(sortedPosts));
          print(
            'CommunityListNotifier: Successfully loaded ${sortedPosts.length} posts',
          );
          print(
            'CommunityListNotifier: First post title: ${sortedPosts.isNotEmpty ? sortedPosts.first.title : "No posts"}',
          );

        case AsyncError(:final error, :final stackTrace):
          state = state.copyWith(postList: AsyncError(error, stackTrace));
          print('CommunityListNotifier: Error loading posts: $error');

        case AsyncLoading():
          // 이미 위에서 AsyncLoading으로 설정했으므로 여기서는 처리 불필요
          print('CommunityListNotifier: Still loading...');
          break;
      }
    } catch (e) {
      print('CommunityListNotifier: Unexpected error in _fetch(): $e');
      state = state.copyWith(postList: AsyncError(e, StackTrace.current));
    }

    print('CommunityListNotifier: _fetch() completed');
  }

  /// 탭 변경·수동 새로고침 등 외부 Action 진입점
  Future<void> onAction(CommunityListAction action) async {
    print('CommunityListNotifier: onAction called with $action');

    switch (action) {
      case Refresh():
        print('CommunityListNotifier: Refresh action received');
        await _fetch(); // 전체 목록 다시 불러오기

      case ChangeTab(:final tab):
        print(
          'CommunityListNotifier: ChangeTab action received. New tab: $tab',
        );
        // 탭 변경 시 게시글 다시 불러오기 (추가)
        state = state.copyWith(currentTab: tab);
        await _fetch(); // 전체 목록 다시 불러온 후 정렬 적용

      case TapSearch():
        print(
          'CommunityListNotifier: TapSearch action received (handled by Root)',
        );
        // 화면 이동은 Root에서 처리하므로 여기서는 아무 작업도 수행하지 않음
        break;

      case TapWrite():
        print(
          'CommunityListNotifier: TapWrite action received (handled by Root)',
        );
        // 화면 이동은 Root에서 처리하므로 여기서는 아무 작업도 수행하지 않음
        break;

      case TapPost():
        print(
          'CommunityListNotifier: TapPost action received (handled by Root)',
        );
        // 화면 이동은 Root에서 처리하므로 여기서는 아무 작업도 수행하지 않음
        break;
    }

    print('CommunityListNotifier: onAction completed for $action');
  }

  List<Post> _applySort(List<Post> list, CommunityTabType tab) {
    print('CommunityListNotifier: Applying sort for tab: $tab');

    switch (tab) {
      case CommunityTabType.popular:
        final sorted = [...list]..sort(
          (a, b) => b.likeCount.compareTo(a.likeCount),
        ); // likeCount 필드 사용
        print(
          'CommunityListNotifier: Sorted by popularity (${sorted.length} posts)',
        );
        return sorted;

      case CommunityTabType.newest:
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print(
          'CommunityListNotifier: Sorted by newest (${sorted.length} posts)',
        );
        if (sorted.isNotEmpty) {
          print(
            'CommunityListNotifier: Newest post: ${sorted.first.title} (${sorted.first.createdAt})',
          );
        }
        return sorted;
    }
  }
}
