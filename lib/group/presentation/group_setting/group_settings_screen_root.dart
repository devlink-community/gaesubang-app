// lib/group/presentation/group_setting/group_settings_screen_root.dart
import 'package:devlink_mobile_app/group/presentation/component/group_leave_dialog.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';

class GroupSettingsScreenRoot extends ConsumerWidget {
  final String groupId;

  const GroupSettingsScreenRoot({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 그룹 ID로 Provider 초기화 - 여기가 핵심!
    final state = ref.watch(groupSettingsNotifierProvider(groupId));
    final notifier = ref.read(groupSettingsNotifierProvider(groupId).notifier);

    // 성공 메시지 리스너
    ref.listen(
      groupSettingsNotifierProvider(
        groupId,
      ).select((value) => value.successMessage),
      (previous, next) {
        if (next != null && previous != next) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next)),
          );

          // 탈퇴 성공 시 그룹 목록으로 이동
          if (next.contains('탈퇴')) {
            context.go('/group');
          }
        }
      },
    );

    return GroupSettingsScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case SelectImage():
            // 갤러리에서 이미지 선택
            await _pickImageFromGallery(context, notifier);
            break;
          case LeaveGroup():
            // 새로운 트렌디한 탈퇴 다이얼로그 표시
            await _showNewLeaveConfirmDialog(context, state, notifier);
            break;
          default:
            // 나머지 액션은 Notifier에서 처리
            notifier.onAction(action);
        }
      },
    );
  }

  // 실제 이미지 선택 구현
  Future<void> _pickImageFromGallery(
    BuildContext context,
    GroupSettingsNotifier notifier,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final String localImagePath = 'file://${image.path}';
        notifier.onAction(GroupSettingsAction.imageUrlChanged(localImagePath));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 🔥 새로운 트렌디한 그룹 탈퇴 확인 다이얼로그
  Future<void> _showNewLeaveConfirmDialog(
    BuildContext context,
    GroupSettingsState state,
    GroupSettingsNotifier notifier,
  ) async {
    // 그룹 정보 확인
    final group = state.group.valueOrNull;
    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 정보를 불러올 수 없습니다')),
      );
      return;
    }

    // 방장 여부 확인
    final isOwner = state.isOwner;

    // 트렌디한 다이얼로그 표시
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => GroupLeaveDialog(
            group: group,
            isOwner: isOwner,
            onConfirmLeave: () {
              // 탈퇴 진행
              Navigator.of(context).pop();
              notifier.onAction(const GroupSettingsAction.leaveGroup());
            },
            onCancel: () {
              // 취소
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
