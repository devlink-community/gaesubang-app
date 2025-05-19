import 'package:devlink_mobile_app/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_action.dart';
import 'profile_notifier.dart';

class ProfileScreenRoot extends ConsumerStatefulWidget {
  const ProfileScreenRoot({super.key});

  @override
  ConsumerState<ProfileScreenRoot> createState() => _ProfileScreenRootState();
}

class _ProfileScreenRootState extends ConsumerState<ProfileScreenRoot> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 딱 한 번만 호출
    _maybeRefreshData();
  }

  // 필요한 경우에만 데이터 새로고침
  void _maybeRefreshData() {
    // 필요에 따라 새로고침 로직 추가
    // 현재는 build()에서 자동으로 로드되므로 생략
  }

  // 프로필 화면 데이터 새로고침
  void _refreshData() {
    debugPrint('프로필 화면 데이터 새로고침 실행');
    // 명시적으로 새로고침 액션 호출
    ref.read(profileNotifierProvider.notifier).onAction(const RefreshProfile());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(profileNotifierProvider.notifier);
    final state = ref.watch(profileNotifierProvider);

    return Scaffold(
      body: ProfileScreen(
        state: state,
        onAction: (action) async {
          switch (action) {
            case OpenSettings():
              debugPrint('설정 버튼 클릭됨 - 설정 화면으로 이동 시도');
              context.push('/settings');
              break;
            case RefreshProfile():
              debugPrint('새로고침 버튼 클릭됨');
              await notifier.onAction(action);
              break;
          }
        },
      ),
    );
  }
}
