// lib/onboarding/presentation/permission_request_card.dart
import 'package:flutter/material.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';

class PermissionRequestCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final bool isRequested;
  final VoidCallback onRequest;

  const PermissionRequestCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.isRequested,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              isRequested
                  ? AppColorStyles.primary60.withOpacity(0.3)
                  : AppColorStyles.gray40,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  isRequested
                      ? AppColorStyles.primary60.withOpacity(0.1)
                      : AppColorStyles.gray40.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color:
                  isRequested
                      ? AppColorStyles.primary100
                      : AppColorStyles.gray80,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color:
                        isRequested
                            ? AppColorStyles.primary100
                            : AppColorStyles.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.body2Regular.copyWith(
                    color: AppColorStyles.gray80,
                  ),
                ),
              ],
            ),
          ),

          // 요청 버튼
          ElevatedButton(
            onPressed: isRequested ? null : onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isRequested
                      ? AppColorStyles.primary60.withOpacity(0.2)
                      : AppColorStyles.primary100,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColorStyles.primary60.withOpacity(
                0.2,
              ),
              disabledForegroundColor: AppColorStyles.primary100.withOpacity(
                0.7,
              ),
              elevation: isRequested ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              isRequested ? '완료' : '허용',
              style: AppTextStyles.button2Regular.copyWith(
                color: isRequested ? AppColorStyles.primary100 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
