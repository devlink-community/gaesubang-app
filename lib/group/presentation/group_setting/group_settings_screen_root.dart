// lib/group/presentation/group_setting/group_settings_screen_root.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/presentation/component/group_leave_dialog.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_state.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_notifier.dart';
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

    // 통합된 상태 변경 리스너
    ref.listen<GroupSettingsState>(
      groupSettingsNotifierProvider(groupId),
      (previous, current) async {
        // 작업 타입 분리
        final prevAction = previous?.currentAction;
        final currentAction = current.currentAction;

        // 로딩 상태 변경 감지
        final wasSubmitting = previous?.isSubmitting ?? false;
        final isSubmitting = current.isSubmitting;

        // 이미지 업로드 상태 변경 감지
        final prevUploadStatus = previous?.imageUploadStatus;
        final uploadStatus = current.imageUploadStatus;

        // 작업 시작 시 스낵바 표시
        if (!wasSubmitting && isSubmitting) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // 작업 타입에 따라 다른 메시지 표시
          String message = '';
          switch (current.currentAction) {
            case GroupAction.imageUpload:
              message = '이미지 업로드 중...';
              break;
            case GroupAction.save:
              message = '그룹 정보 저장 중...';
              break;
            case GroupAction.leave:
              message = '그룹 탈퇴 처리 중...';
              break;
            default:
              message = '처리 중...';
              break;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(message),
                ],
              ),
              backgroundColor: AppColorStyles.primary100,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }

        // 작업 완료 시 (로딩이 끝났을 때)
        if (wasSubmitting && !isSubmitting) {
          // 기본적으로 스낵바 숨기기
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        // 이미지 업로드 완료 시 성공 스낵바 표시
        if (prevUploadStatus != ImageUploadStatus.completed &&
            uploadStatus == ImageUploadStatus.completed) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('이미지 업로드가 완료되었습니다'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 이미지 업로드 실패 시 오류 스낵바 표시
        if (prevUploadStatus != ImageUploadStatus.failed &&
            uploadStatus == ImageUploadStatus.failed) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('이미지 업로드에 실패했습니다'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 성공 메시지 처리
        if (previous?.successMessage != current.successMessage &&
            current.successMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.successMessage!),
              backgroundColor: AppColorStyles.primary100,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // 🔥 수정: 탈퇴 성공 시 새로운 refresh 메서드 사용
          if (current.successMessage!.contains('탈퇴')) {
            try {
              // 그룹 리스트 새로고침
              await ref.read(groupListNotifierProvider.notifier).refresh();
              AppLogger.info('그룹 탈퇴 후 리스트 새로고침 완료', tag: 'GroupSettingsRoot');
            } catch (e) {
              AppLogger.error(
                '그룹 리스트 새로고침 실패',
                tag: 'GroupSettingsRoot',
                error: e,
              );
            }

            // 그룹 목록으로 이동
            context.go('/group');
          }
        }

        // 에러 메시지 처리
        if (previous?.errorMessage != current.errorMessage &&
            current.errorMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.errorMessage!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
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

  // 실제 이미지 선택 구현 - 개선된 버전
  Future<void> _pickImageFromGallery(
    BuildContext context,
    GroupSettingsNotifier notifier,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      // 이미지 선택 옵션 다이얼로그 표시
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
        // 초기 품질은 높게 설정 (압축은 나중에 처리)
        maxWidth: 1920,
        // 최대 해상도 제한
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear, // 후면 카메라 우선
      );

      if (image != null) {
        // 이미지 크기 확인 및 경고
        final fileSize = await image.length();
        final fileSizeKB = fileSize / 1024;
        final fileSizeMB = fileSizeKB / 1024;

        if (fileSizeMB > 10) {
          // 10MB 이상인 경우 경고
          final shouldContinue = await _showLargeImageWarning(
            context,
            fileSizeMB,
          );
          if (!shouldContinue) return;
        }

        // 이미지 경로 로깅 추가
        AppLogger.debug('선택된 이미지 경로: ${image.path}', tag: 'GroupSettingsRoot');

        // 로컬 파일 경로 (file:// 프로토콜 포함)
        String localImagePath = image.path;

        // 안드로이드에서는 file:// 접두사가 필요할 수 있음
        if (!localImagePath.startsWith('file://') &&
            !localImagePath.startsWith('content://')) {
          localImagePath = 'file://$localImagePath';
        }

        AppLogger.debug('최종 이미지 경로: $localImagePath', tag: 'GroupSettingsRoot');

        // ImageUrlChanged 액션으로 전달하면 Notifier에서 자동으로 업로드 처리
        notifier.onAction(GroupSettingsAction.imageUrlChanged(localImagePath));
      }
    } catch (e, st) {
      // 이미지 선택 중 오류 발생 시 처리
      AppLogger.error(
        '이미지 선택 오류',
        tag: 'GroupSettingsRoot',
        error: e,
        stackTrace: st,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // 이미지 소스 선택 다이얼로그
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이미지 선택'),
            content: const Text('그룹 이미지를 어떻게 가져오시겠어요?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('카메라'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ],
          ),
    );
  }

  // 대용량 이미지 경고 다이얼로그
  Future<bool> _showLargeImageWarning(
    BuildContext context,
    double sizeMB,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('큰 파일 크기'),
              ],
            ),
            content: Text(
              '선택한 이미지의 크기가 ${sizeMB.toStringAsFixed(1)}MB입니다.\n'
              '업로드 시간이 오래 걸릴 수 있습니다.\n'
              '계속 진행하시겠어요?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorStyles.primary100,
                  foregroundColor: Colors.white,
                ),
                child: const Text('계속'),
              ),
            ],
          ),
    );

    return result ?? false;
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
        const SnackBar(
          content: Text('그룹 정보를 불러올 수 없습니다'),
          backgroundColor: Colors.red,
        ),
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
