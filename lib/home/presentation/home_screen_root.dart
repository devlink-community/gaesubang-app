// lib/home/presentation/home_screen_root.dart - 대체 방안
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/module/auth_di.dart';
import '../../core/utils/app_logger.dart';
import 'home_action.dart';
import 'home_notifier.dart';
import 'home_screen.dart';

class HomeScreenRoot extends ConsumerStatefulWidget {
  const HomeScreenRoot({super.key});

  @override
  ConsumerState<HomeScreenRoot> createState() => _HomeScreenRootState();
}

class _HomeScreenRootState extends ConsumerState<HomeScreenRoot> {
  String? userSkills;

  @override
  void initState() {
    super.initState();
    // 초기화 시점에 사용자 스킬 정보 로드
    _loadUserSkills();
  }

  Future<void> _loadUserSkills() async {
    final currentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    final userResult = await currentUserUseCase.execute();

    userResult.when(
      data: (user) {
        setState(() {
          userSkills = user.skills;
          AppLogger.info(
            '사용자 스킬 정보 로드 완료: $userSkills',
            tag: 'HomeScreenRoot',
          );
        });
      },
      error: (error, stackTrace) {
        AppLogger.error(
          '사용자 정보 로드 실패',
          tag: 'HomeScreenRoot',
          error: error,
          stackTrace: stackTrace,
        );
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeNotifier = ref.watch(homeNotifierProvider.notifier);
    final homeState = ref.watch(homeNotifierProvider);

    return HomeScreen(
      state: homeState,
      userSkills: userSkills, // 상태 변수에 저장된 스킬 정보 전달
      onAction: (action) async {
        switch (action) {
          case RefreshHome():
            await homeNotifier.onAction(action);
            _loadUserSkills(); // 새로고침 시 스킬 정보도 다시 로드
            break;
          case OnTapNotice(:final noticeId):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('공지사항 $noticeId 클릭')));
            break;
          case OnTapGroup(:final groupId):
            context.push('/group/$groupId');
            break;
          case OnTapPopularPost(:final postId):
            context.push('/community/$postId');
            break;
          case OnTapSettings():
            context.push('/settings');
            break;
          case OnTapNotification():
            context.push('/notifications');
            break;
          default:
            await homeNotifier.onAction(action);
            break;
        }
      },
    );
  }
}
