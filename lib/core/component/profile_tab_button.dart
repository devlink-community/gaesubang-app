// lib/core/component/profile_tab_button.dart
import 'dart:io';

import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileTabButton extends ConsumerWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const ProfileTabButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: FutureBuilder(
          future: getCurrentUserUseCase.execute(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.hasValue) {
              final user = snapshot.data!.value!;
              final imageUrl = user.image;

              if (imageUrl.isNotEmpty) {
                // 프로필 이미지가 있는 경우
                return Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        isSelected
                            ? Border.all(
                              color: AppColorStyles.primary100,
                              width: 2,
                            )
                            : null,
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        imageUrl.startsWith('/')
                            ? FileImage(File(imageUrl))
                            : NetworkImage(imageUrl) as ImageProvider,
                    backgroundColor: AppColorStyles.gray40,
                  ),
                );
              }
            }

            // 기본 아이콘
            return Icon(
              Icons.person_outline,
              color:
                  isSelected
                      ? AppColorStyles.primary100
                      : AppColorStyles.gray60,
              size: 28,
            );
          },
        ),
      ),
    );
  }
}
