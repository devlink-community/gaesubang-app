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
    required this.profileImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColorStyles.primary100 : Colors.transparent,
            width: 2,
          ),
        ),
        child: AppImage.profile(
          imagePath: profileImageUrl,
          size: 36, // 테두리를 고려한 내부 이미지 크기
          backgroundColor: Colors.grey.shade200,
          foregroundColor: AppColorStyles.primary60,
        ),
      ),
    );
  }
}
