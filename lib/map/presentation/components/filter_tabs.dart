import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/map/module/filter_type.dart';
import 'package:flutter/material.dart';

class FilterTabs extends StatelessWidget {
  final FilterType selectedFilter;
  final Function(FilterType) onFilterChanged;

  const FilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab(context, FilterType.all, '모두', Icons.view_list),
          _buildTab(context, FilterType.users, '사용자', Icons.person),
          _buildTab(context, FilterType.groups, '그룹', Icons.group),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    FilterType type,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedFilter == type;

    return Expanded(
      child: InkWell(
        onTap: () => onFilterChanged(type),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? AppColorStyles.primary100 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? AppColorStyles.primary100
                        : AppColorStyles.gray80,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.captionRegular.copyWith(
                  color:
                      isSelected
                          ? AppColorStyles.primary100
                          : AppColorStyles.gray80,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
