// lib/core/component/profile_tab_button.dart
import 'package:flutter/material.dart';

import '../styles/app_color_styles.dart';
import 'app_image.dart';

class ProfileTabButton extends StatelessWidget {
  final bool isSelected;
  final String? profileImageUrl;
  final VoidCallback onTap;

  const ProfileTabButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              isSelected
                  ? Border.all(color: AppColorStyles.primary100, width: 2.5)
                  : null,
        ),
        child: ClipOval(
          child: AppImage.profile(
            imagePath: profileImageUrl,
            size: 32,
            backgroundColor: Colors.grey.shade200,
            foregroundColor:
                isSelected ? AppColorStyles.primary100 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
