// lib/community/presentation/community_list/community_list_notifier.dart

import 'dart:async';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/usecase/load_post_list_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';

import 'package:devlink_mobile_app/community/presentation/community_list/community_list_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_list_notifier.g.dart';


@riverpod
class CommunityListNotifier extends _$CommunityListNotifier {
  @override
  CommunityListState build() {
    _loadPostListUseCase = ref.watch(loadPostListUseCaseProvider);
    // 비동기 로딩 → 결과 반영
    Future.microtask(_fetch);
    return const CommunityListState(currentTab: CommunityTabType.newest); // 최신순으로 기본값 설정
  }

  late final LoadPostListUseCase _loadPostListUseCase;

  /// 원격 새로고침
  Future<void> _fetch() async {
    state = state.copyWith(postList: const AsyncLoading());
    final result = await _loadPostListUseCase.execute();
    
    // switch-case 패턴 사용
    switch (result) {
      case AsyncData(:final value):
        state = state.copyWith(
          postList: AsyncData(_applySort(value, state.currentTab))
        );
      case AsyncError(:final error, :final stackTrace):
        state = state.copyWith(postList: AsyncError(error, stackTrace));
      case AsyncLoading():
        // 이미 위에서 AsyncLoading으로 설정했으므로 여기서는 처리 불필요
        break;
    }
  }

  /// 탭 변경·수동 새로고침 등 외부 Action 진입점
  Future<void> onAction(CommunityListAction action) async {
    switch (action) {
      case Refresh():
        await _fetch(); // 전체 목록 다시 불러오기
        
      case ChangeTab(:final tab):
        // 탭 변경 시 게시글 다시 불러오기 (추가)
        state = state.copyWith(currentTab: tab);
        await _fetch(); // 전체 목록 다시 불러온 후 정렬 적용
        
      case TapSearch():
        // 화면 이동은 Root에서 처리하므로 여기서는 아무 작업도 수행하지 않음
        break;
      case TapWrite():
        // 화면 이동은 Root에서 처리하므로 여기서는 아무 작업도 수행하지 않음
        break;
      case TapPost():
        // 화면 이동은 Root에서 처리하므로 여기서는 아무 작업도 수행하지 않음
        break;
    }
  }

  List<Post> _applySort(List<Post> list, CommunityTabType tab) {
    switch (tab) {
      case CommunityTabType.popular:
        final sorted = [...list]..sort((a, b) => b.like.length.compareTo(a.like.length));
        return sorted;
      case CommunityTabType.newest:
        final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
    }
  }
}