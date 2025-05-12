import 'package:devlink_mobile_app/edit_intro/presentation/screens/edit_intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../edit_intro_action.dart';
import '../edit_intro_notifier.dart';

class EditIntroRoot extends ConsumerStatefulWidget {
  const EditIntroRoot({super.key});

  @override
  ConsumerState<EditIntroRoot> createState() => _EditIntroRootState();
}

class _EditIntroRootState extends ConsumerState<EditIntroRoot> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 프로필 정보 로드
    Future.microtask(
      () => ref.read(editIntroNotifierProvider.notifier).loadProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editIntroNotifierProvider);
    final notifier = ref.watch(editIntroNotifierProvider.notifier);

    return EditIntroScreen(
      state: state,
      onAction: (action) async {
        await notifier.onAction(action);

        // OnSave 액션 처리 후 성공적으로 저장되었다면 뒤로 가기
        if (action is OnSave && state.isSuccess && !state.isError) {
          if (context.mounted) {
            context.pop();
          }
        }
      },
    );
  }
}
