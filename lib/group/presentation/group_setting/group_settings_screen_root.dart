// lib/group/presentation/group_settings/group_settings_screen_root.dart
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen.dart';
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next)));

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
            // 탈퇴 확인 다이얼로그 표시
            await _showLeaveConfirmDialog(context, notifier);
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
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')));
    }
  }

  // 그룹 탈퇴 확인 다이얼로그
  Future<void> _showLeaveConfirmDialog(
    BuildContext context,
    GroupSettingsNotifier notifier,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('그룹 탈퇴'),
            content: const Text('정말로 이 그룹에서 탈퇴하시겠습니까?\n탈퇴 후에는 다시 초대를 받아야 합니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('탈퇴', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (result == true) {
      notifier.onAction(const GroupSettingsAction.leaveGroup());
    }
  }
}
