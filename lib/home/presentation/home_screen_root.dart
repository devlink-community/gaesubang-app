// lib/home/presentation/home_screen_root.dart

import 'package:devlink_mobile_app/auth/domain/model/member.dart'; // Member 모델 임포트
import 'package:devlink_mobile_app/core/auth/auth_provider.dart'; // authNotifierProvider 임포트 (실제 경로로 수정)
import 'package:devlink_mobile_app/core/auth/auth_state.dart'; // AuthState, Authenticated, AuthLoading 등 임포트 (실제 경로로 수정)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// getCurrentUserUseCaseProvider는 이 방식에서는 직접 사용하지 않으므로 주석 처리 가능
// import '../../auth/module/auth_di.dart';
import 'home_action.dart';
import 'home_notifier.dart';
import 'home_screen.dart';

class HomeScreenRoot extends ConsumerWidget {
  const HomeScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeNotifier = ref.watch(homeNotifierProvider.notifier);
    final homeState = ref.watch(homeNotifierProvider);

    // authNotifierProvider를 watch하여 인증 상태 및 사용자 정보를 가져옵니다.
    final authState = ref.watch(authNotifierProvider);

    String? userSkills;
    // Member? currentUser; // 직접적인 사용처가 없다면 이 변수는 불필요할 수 있습니다.

    if (authState is Authenticated) {
      // Authenticated 상태일 때 Member 객체에서 스킬 정보를 가져옵니다.
      // authState.user가 nullable일 수 있으므로 null safety를 적용합니다.
      userSkills = authState.user?.skills;
      debugPrint('HomeScreenRoot: 사용자 스킬 (from AuthState) - $userSkills');
    } else if (authState is AuthLoading) {
      // 인증 상태 로딩 중이면 로딩 인디케이터를 표시합니다.
      // Scaffold로 감싸서 전체 화면을 덮도록 하는 것이 좋습니다.
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            key: Key('auth_loading_indicator_homescreenroot'),
          ),
        ),
      );
    } else {
      // Unauthenticated 또는 Error 상태 처리
      // 이 경우, 일반적으로 로그인 페이지로 리디렉션하거나 오류 메시지를 표시합니다.
      // 현재는 스킬 없이 홈 화면을 보여주도록 되어 있지만,
      // 실제 앱에서는 리디렉션 로직이 필요할 수 있습니다.
      // 예: context.go('/login');
      debugPrint(
        'HomeScreenRoot: 인증되지 않았거나 인증 상태 오류입니다. AuthState: $authState',
      );
      // 인증되지 않은 사용자는 홈 화면에 접근할 수 없도록 처리하는 것이 일반적입니다.
      // 예를 들어, 로그인 화면으로 리디렉션하거나 빈 화면 또는 오류 화면을 보여줄 수 있습니다.
      // 여기서는 일단 userSkills가 null인 상태로 HomeScreen을 반환하도록 두겠습니다.
      // 하지만 라우팅 가드 등을 통해 이전에 로그인 페이지로 보내는 것이 더 나은 UX일 수 있습니다.
    }

    // authState가 Authenticated가 아니거나, Authenticated 상태여도 user.skills가 null 또는 비어있을 수 있습니다.
    // HomeScreen은 userSkills가 null일 가능성을 처리해야 합니다. (이미 그렇게 되어 있습니다.)
    return HomeScreen(
      state: homeState,
      userSkills: userSkills, // 추출한 스킬 정보를 HomeScreen에 전달
      onAction: (action) async {
        // homeNotifier에 모든 액션을 위임할 수 있습니다.
        // 개별 case 처리가 필요 없다면 더 간단하게 작성 가능합니다.
        switch (action) {
          case RefreshHome():
            await homeNotifier.onAction(action);
            break;
          case OnTapNotice(:final noticeId):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('공지사항 $noticeId 클릭')));
            // TODO: 알림 상세 로직 또는 라우팅 구현
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
          // default 케이스나 모든 HomeAction 타입을 명시적으로 처리하는 것이 좋습니다.
          // 예를 들어, HomeAction이 sealed class이고 모든 하위 타입을 여기서 처리하지 않는다면,
          // notifier.onAction(action)으로 일괄 전달하는 것을 고려할 수 있습니다.
          // 현재 default 블록은 모든 HomeAction 타입을 homeNotifier.onAction으로 전달하게 됩니다.
          default:
            if (action is HomeAction) {
              await homeNotifier.onAction(action);
            }
            break;
        }
      },
    );
  }
}
