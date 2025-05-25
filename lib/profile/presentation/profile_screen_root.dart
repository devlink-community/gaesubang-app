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

class _ProfileScreenRootState extends ConsumerState<ProfileScreenRoot>
    with WidgetsBindingObserver {
  // 화면 상태 관리
  bool _isInitialized = false;
  bool _wasInBackground = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    // 앱 상태 변화 감지를 위한 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 초기화 플래그 설정
    _isInitializing = true;

    // 화면 초기화를 위젯 빌드 이후로 지연
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // 화면 초기화 (최초 진입 시에만 호출)
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    if (mounted) {
      // 초기 데이터 로드 (ProfileNotifier의 loadData 메서드 호출)
      await ref.read(profileNotifierProvider.notifier).loadData();
    }

    _isInitialized = true;
    _isInitializing = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 초기화 중이면 생명주기 이벤트 무시
    if (_isInitializing) return;

    switch (state) {
      case AppLifecycleState.paused:
        if (_isInitialized && !_isInitializing && !_wasInBackground) {
          _wasInBackground = true;
        }
        break;

      case AppLifecycleState.resumed:
        // 실제 백그라운드에서 돌아온 경우만 처리
        if (_wasInBackground && mounted && _isInitialized && !_isInitializing) {
          // 백그라운드에서 돌아왔을 때 자동 갱신
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(profileNotifierProvider.notifier).loadData();
            }
          });
        }
        _wasInBackground = false;
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    // 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
              await context.push('/settings');
              // 설정에서 돌아왔을 때도 갱신 가능성이 있으므로 처리
              if (mounted) {
                notifier.loadData();
              }
              break;
            case RefreshProfile():
              // 수동 새로고침
              await notifier.onAction(action);
              break;
          }
        },
      ),
    );
  }
}
