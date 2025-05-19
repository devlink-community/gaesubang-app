import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_notifier.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileEditNotifierProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditNotifierProvider);
    final notifier = ref.watch(profileEditNotifierProvider.notifier);

    // 저장 성공 시 단순히 뒤로 가기 (ProfileScreenRoot가 갱신을 처리함)
    ref.listen(profileEditNotifierProvider.select((s) => s.saveState), (
      previous,
      current,
    ) {
      if (current case AsyncData(:final value)) {
        if (value == true) {
          _showSuccessMessage(context);
          context.go('/profile'); // ProfileScreenRoot가 갱신 감지
        }
      }
    });

    // 에러 처리
    ref.listen(profileEditNotifierProvider.select((s) => s.saveState), (
      previous,
      current,
    ) {
      if (current.hasError) {
        _showErrorMessage(context, current.error.toString());
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
        content: Text(message.isNotEmpty ? message : '저장에 실패했습니다'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }
}
