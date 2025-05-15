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
  // 저장 버튼 클릭 추적을 위한 변수
  bool _saveButtonPressed = false;

  @override
  void initState() {
    super.initState();
    // 미세한 지연을 두고 프로필 로드 시작
    Future.microtask(() {
      ref.read(editIntroNotifierProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editIntroNotifierProvider);
    final notifier = ref.watch(editIntroNotifierProvider.notifier);

    // 로딩 상태 감시
    ref.listen(editIntroNotifierProvider.select((s) => s.isLoading), (
      previous,
      current,
    ) {
      // 로딩이 끝났고 (이전에 로딩 중이었고, 현재는 아님) 저장 버튼을 눌렀던 경우
      if (previous == true && current == false && _saveButtonPressed) {
        // 저장 버튼 상태 초기화
        _saveButtonPressed = false;

        // 성공 여부 확인
        if (state.isSuccess && !state.isError) {
          // 토스트 메시지 표시
          _showSuccessMessage(context);

          // 약간의 지연 후 화면 전환
          Future.delayed(const Duration(milliseconds: 1500), () {
            context.go('/profile');
          });
        } else if (state.isError) {
          // 에러 시 에러 메시지 표시
          _showErrorMessage(context, state.errorMessage ?? '프로필 저장 실패');
        }
      }
    });

    return EditIntroScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case OnSave():
            // 저장 버튼이 눌렸음을 표시
            _saveButtonPressed = true;
            await notifier.onAction(action);
            break;
          default:
            await notifier.onAction(action);
        }
      },
    );
  }

  // 성공 메시지 표시 메서드
  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 성공적으로 저장되었습니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 에러 메시지 표시 메서드
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
