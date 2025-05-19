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

  // 초기화 중 생명주기 이벤트 무시
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

    debugPrint('🚀 프로필 화면 초기화 시작');

    if (mounted) {
      await ref.read(profileNotifierProvider.notifier).loadData();
    }

    _isInitialized = true;
    _isInitializing = false;

    debugPrint('✅ 프로필 화면 초기화 완료');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 초기화 중이면 생명주기 이벤트 무시
    if (_isInitializing) {
      debugPrint('🔄 초기화 중이므로 생명주기 이벤트 무시: $state');
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        if (_isInitialized && !_isInitializing && !_wasInBackground) {
          debugPrint('📱 앱이 백그라운드로 전환됨');
          _wasInBackground = true;
        }
        break;

      case AppLifecycleState.resumed:
        // 실제 백그라운드에서 돌아온 경우만 처리
        if (_wasInBackground && mounted && _isInitialized && !_isInitializing) {
          debugPrint('🔄 백그라운드에서 앱 재개 - 프로필 데이터 갱신');
          // 데이터 갱신을 다음 프레임으로 지연
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(profileNotifierProvider.notifier).loadData();
            }
          });
        }
        _wasInBackground = false;
        break;

      default:
        // 다른 상태들은 로그만 남김
        debugPrint('🔄 생명주기 상태 변경: $state');
        break;
    }
  }

  @override
  void dispose() {
    // 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 다른 화면에서 돌아올 때 감지 및 처리
  void _handleScreenReturn() {
    if (mounted && _isInitialized && !_isInitializing) {
      debugPrint('🔄 다른 화면에서 프로필로 돌아옴 - 데이터 갱신');
      // 데이터 갱신을 다음 프레임으로 지연
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(profileNotifierProvider.notifier).loadData();
        }
      });
    }
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
              await context.push('/settings');
              // 화면에서 돌아왔을 때 데이터 갱신
              _handleScreenReturn();
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
