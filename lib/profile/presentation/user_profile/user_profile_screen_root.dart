// lib/profile/presentation/user_profile/user_profile_screen_root.dart
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_action.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_notifier.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserProfileScreenRoot extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreenRoot({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreenRoot> createState() =>
      _UserProfileScreenRootState();
}

class _UserProfileScreenRootState extends ConsumerState<UserProfileScreenRoot> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    print('🚀 사용자 프로필 화면 초기화 시작 - userId: ${widget.userId}');

    if (mounted) {
      final notifier = ref.read(userProfileNotifierProvider.notifier);
      await notifier.onAction(UserProfileAction.loadUserProfile(widget.userId));
    }

    _isInitialized = true;
    print('✅ 사용자 프로필 화면 초기화 완료');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileNotifierProvider);
    final notifier = ref.read(userProfileNotifierProvider.notifier);

    // 에러 메시지 리스너
    ref.listen(
      userProfileNotifierProvider.select((value) => value.errorMessage),
      (previous, next) {
        if (next != null && previous != next) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: '확인',
                textColor: Colors.white,
                onPressed: () {
                  notifier.onAction(const UserProfileAction.clearError());
                },
              ),
            ),
          );
        }
      },
    );

    // 성공 메시지 리스너
    ref.listen(
      userProfileNotifierProvider.select((value) => value.successMessage),
      (previous, next) {
        if (next != null && previous != next) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '확인',
                textColor: Colors.white,
                onPressed: () {
                  notifier.onAction(const UserProfileAction.clearSuccess());
                },
              ),
            ),
          );
        }
      },
    );

    // 초기화 중이거나 로딩 중인 경우
    if (!_isInitialized || state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('프로필 정보를 불러오는 중...'),
            ],
          ),
        ),
      );
    }

    // 프로필 로드 실패 시 에러 화면
    if (state.userProfile is AsyncError) {
      final error = (state.userProfile as AsyncError).error;
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          centerTitle: true,
        ),
        body: ErrorView(
          error: error,
          onRetry:
              () => notifier.onAction(const UserProfileAction.refreshProfile()),
        ),
      );
    }

    // 정상 화면 렌더링
    return UserProfileScreen(
      state: state,
      onAction: (action) async {
        if (!mounted) return;
        await notifier.onAction(action);
      },
    );
  }
}
