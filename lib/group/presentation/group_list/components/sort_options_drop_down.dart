import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_sort_type.dart';
import 'package:flutter/material.dart';

class SortOptionsDropdown extends StatelessWidget {
  final GroupSortType currentSortType;
  final Function(GroupListAction) onAction;
  final LayerLink layerLink;

  const SortOptionsDropdown({
    super.key,
    required this.currentSortType,
    required this.onAction,
    required this.layerLink,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 투명한 오버레이 - 드롭다운 외부 터치 시 닫히도록
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // 드롭다운 닫기 (빈 액션 호출)
                onAction(GroupListAction.onChangeSortType(currentSortType));
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 드롭다운 메뉴
          CompositedTransformFollower(
            link: layerLink,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8), // 버튼 아래 간격
            child: Container(
              width: 180, // 드롭다운 너비
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSortOption(
                    context,
                    GroupSortType.latest,
                    Icons.access_time,
                    '최신순',
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColorStyles.gray40.withValues(alpha: 0.3),
                  ),
                  _buildSortOption(
                    context,
                    GroupSortType.popular,
                    Icons.trending_up,
                    '인기순',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    GroupSortType sortType,
    IconData icon,
    String title,
  ) {
    final isSelected = currentSortType == sortType;

    return InkWell(
      onTap: () {
        onAction(GroupListAction.onChangeSortType(sortType));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected
                      ? AppColorStyles.primary100
                      : AppColorStyles.gray80,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.body2Regular.copyWith(
                color:
                    isSelected
                        ? AppColorStyles.primary100
                        : AppColorStyles.gray100,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: AppColorStyles.primary100,
              ),
          ],
        ),
      ),
    );
  }
}
