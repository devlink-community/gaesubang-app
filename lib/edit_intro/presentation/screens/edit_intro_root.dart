import 'package:devlink_mobile_app/edit_intro/presentation/screens/edit_intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../edit_intro_action.dart';
import '../edit_intro_notifier.dart';

class EditIntroRoot extends ConsumerWidget {
  const EditIntroRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // editIntroNotifierProvider로 변경
    final state = ref.watch(editIntroNotifierProvider);
    final notifier = ref.watch(editIntroNotifierProvider.notifier);

    return EditIntroScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case OnSave():
            await notifier.onAction(action);
            if (!state.isError && state.isSuccess) {
              context.pop(); // 저장 성공 시 이전 화면으로 이동
            }
            break;
          default:
            await notifier.onAction(action);
        }
      },
    );
  }
}
