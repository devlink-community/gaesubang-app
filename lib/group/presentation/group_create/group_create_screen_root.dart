// lib/group/presentation/group_create/group_create_screen_root.dart
import 'dart:io';

import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';

import '../group_list/group_list_action.dart';

class GroupCreateScreenRoot extends ConsumerWidget {
  const GroupCreateScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupCreateNotifierProvider);
    final notifier = ref.read(groupCreateNotifierProvider.notifier);

    // 그룹 생성 완료 감지
    ref.listen(
      groupCreateNotifierProvider.select((value) => value.createdGroupId),
      (previous, next) {
        if (next != null && previous == null) {
          // 성공 메시지 표시
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('그룹이 성공적으로 생성되었습니다')));

          // 디버깅 정보 출력
          AppLogger.navigation('Navigating to group with ID: $next');

          // 🔥 추가: 그룹 리스트 새로고침
          ref
              .read(groupListNotifierProvider.notifier)
              .onAction(
                const GroupListAction.onLoadGroupList(),
              );

          // 그룹 상세 페이지로 이동 (확실하게 경로 지정)
          context.pushReplacement('/group/$next');
        }
      },
    );

    return GroupCreateScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case SelectImage():
            // 갤러리에서 이미지 선택
            await _pickImageFromGallery(context, notifier);
            break;
          case Cancel():
            // 뒤로가기
            context.pop();
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
    GroupCreateNotifier notifier,
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

        notifier.onAction(GroupCreateAction.imageUrlChanged(localImagePath));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')));
    }
  }

  // 백업: 모의 이미지 선택 다이얼로그 (테스트용)
  void _showMockImagePicker(
    BuildContext context,
    GroupCreateNotifier notifier,
  ) {
    final mockImageUrls = [
      'https://picsum.photos/id/237/200/200',
      'https://picsum.photos/id/238/200/200',
      'https://picsum.photos/id/239/200/200',
      'https://picsum.photos/id/240/200/200',
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이미지 선택'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: mockImageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      notifier.onAction(
                        GroupCreateAction.imageUrlChanged(mockImageUrls[index]),
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(mockImageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          ),
    );
  }
}
