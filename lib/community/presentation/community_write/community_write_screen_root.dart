// lib/community/presentation/community_write/community_write_screen_root.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunityWriteScreenRoot extends ConsumerWidget {
  const CommunityWriteScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 게시글 작성/수정 완료 감지
    ref.listen<CommunityWriteState>(communityWriteNotifierProvider, (
      previous,
      current,
    ) {
      final bool wasProcessing = previous?.submitting ?? false;
      final bool isCompleted =
          !current.submitting &&
          (current.createdPostId != null || current.updatedPostId != null);

      // 처리 중이었다가 완료된 경우 (생성 또는 수정)
      if (wasProcessing && isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            // 성공 메시지 표시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  current.isEditMode ? '게시글이 수정되었습니다' : '게시글이 등록되었습니다',
                ),
                duration: const Duration(seconds: 2),
              ),
            );

            // 화면 닫기
            if (context.canPop()) {
              context.pop({'refresh': true});
            } else {
              // 사용 중인 라우터에 따라 적절히 처리
              context.go('/community', extra: {'refresh': true});
            }
          }
        });
      }
    });

    // 현재 경로의 extra 데이터 가져오기 (수정 모드에서 전달된 게시글 데이터)
    final extra = GoRouterState.of(context).extra;

    // 게시글 데이터 초기화 (한 번만 수행되어야 함)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (extra is Map && extra.containsKey('post')) {
        // 게시글 데이터가 있으면 수정 모드로 초기화
        final post = extra['post'] as Post;
        ref.read(communityWriteNotifierProvider.notifier).initWithPost(post);
      }
    });

    final state = ref.watch(communityWriteNotifierProvider);
    final notifier = ref.watch(communityWriteNotifierProvider.notifier);

    return CommunityWriteScreen(state: state, onAction: notifier.onAction);
  }
}
