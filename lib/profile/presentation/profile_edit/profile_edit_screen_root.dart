import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_notifier.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_screen.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileEditScreenRoot extends ConsumerStatefulWidget {
  const ProfileEditScreenRoot({super.key});

  @override
  ConsumerState<ProfileEditScreenRoot> createState() =>
      _ProfileEditScreenRootState();
}

class _ProfileEditScreenRootState extends ConsumerState<ProfileEditScreenRoot> {
  @override
  void initState() {
    super.initState();
    // 프로필 로드 시작
    ref.read(profileEditNotifierProvider.notifier).loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditNotifierProvider);
    final notifier = ref.watch(profileEditNotifierProvider.notifier);

    // 성공 시 처리
    ref.listen(profileEditNotifierProvider.select((s) => s.isSuccess), (
      previous,
      current,
    ) {
      if (current && !state.isLoading) {
        _showSuccessMessage(context);
        // 프로필 화면 새로고침 후 이동
        ref.invalidate(profileNotifierProvider);
        context.go('/profile');
      }
    });

    // 에러 시 처리
    ref.listen(profileEditNotifierProvider.select((s) => s.hasError), (
      previous,
      current,
    ) {
      if (current) {
        _showErrorMessage(context, state.errorMessage ?? '프로필 저장 실패');
      }
    });

    return ProfileEditScreen(state: state, onAction: notifier.onAction);
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 성공적으로 저장되었습니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('저장에 실패하였습니다.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }
}
