import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class SearchBarComponent extends StatelessWidget {
  final VoidCallback onTap;
  final String hintText;
  final IconData? icon;
  final double height;
  final Color? backgroundColor;
  final BoxShadow? boxShadow;
  final double borderRadius;

  const SearchBarComponent({
    super.key,
    required this.onTap,
    this.hintText = '검색어를 입력하세요',
    this.icon = Icons.search,
    this.height = 56,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey.shade50,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow:
              boxShadow != null
                  ? [boxShadow!]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: AppColorStyles.gray100, size: 20),
            const SizedBox(width: 12),
            Text(
              hintText,
              style: AppTextStyles.body1Regular.copyWith(
                color: AppColorStyles.gray60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
