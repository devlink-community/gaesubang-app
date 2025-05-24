import 'package:devlink_mobile_app/core/utils/app_logger.dart';
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
    AppLogger.debug('ProfileEditScreenRoot: initState 호출됨', tag: 'ProfileEditScreenRoot');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.debug('ProfileEditScreenRoot: 프로필 로드 시작', tag: 'ProfileEditScreenRoot');
      ref.read(profileEditNotifierProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditNotifierProvider);
    final notifier = ref.watch(profileEditNotifierProvider.notifier);

    AppLogger.debug('ProfileEditScreenRoot: build 호출됨', tag: 'ProfileEditScreenRoot');

    // 저장 성공 시 단순히 뒤로 가기 (ProfileScreenRoot가 갱신을 처리함)
    ref.listen(profileEditNotifierProvider.select((s) => s.saveState), (
      previous,
      current,
    ) {
      AppLogger.debug(
        'ProfileEditScreenRoot: saveState 변화 감지 - $current',
        tag: 'ProfileEditScreenRoot',
      );

      if (current case AsyncData(:final value)) {
        if (value == true) {
          AppLogger.info(
            'ProfileEditScreenRoot: 저장 성공! 프로필 화면으로 이동',
            tag: 'ProfileEditScreenRoot',
          );
          _showSuccessMessage(context);

          // 여기서 /profile로 이동
          AppLogger.debug(
            'ProfileEditScreenRoot: context.go("/profile") 호출',
            tag: 'ProfileEditScreenRoot',
          );
          context.go('/profile');
        }
      }
    });

    // 에러 처리
    ref.listen(profileEditNotifierProvider.select((s) => s.saveState), (
      previous,
      current,
    ) {
      if (current.hasError) {
        AppLogger.error(
          'ProfileEditScreenRoot: 저장 에러',
          tag: 'ProfileEditScreenRoot',
          error: current.error,
        );
        _showErrorMessage(context, current.error.toString());
      }
    });

    return ProfileEditScreen(state: state, onAction: notifier.onAction);
  }

  void _showSuccessMessage(BuildContext context) {
    AppLogger.debug(
      'ProfileEditScreenRoot: 성공 메시지 표시',
      tag: 'ProfileEditScreenRoot',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 성공적으로 저장되었습니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    AppLogger.debug(
      'ProfileEditScreenRoot: 에러 메시지 표시 - $message',
      tag: 'ProfileEditScreenRoot',
    );
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