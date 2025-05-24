import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:flutter/material.dart';

import '../../domain/model/group.dart';

class GroupFullDialog extends StatelessWidget {
  final Group group;
  final void Function(GroupListAction action) onAction;

  const GroupFullDialog({
    super.key,
    required this.group,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorStyles.primary100.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: AppColorStyles.primary100,
          ),
          const SizedBox(height: 12),
          Text(
            '모집 마감',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: AppColorStyles.primary100,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '이 그룹은 모집 마감으로\n참여하실 수 없습니다',
            textAlign: TextAlign.center,
            style: AppTextStyles.body1Regular.copyWith(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColorStyles.gray40.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppColorStyles.gray100,
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.memberCount}/${group.maxMemberCount}명',
                  style: AppTextStyles.body2Regular.copyWith(
                    color: AppColorStyles.gray100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => onAction(const GroupListAction.onCloseDialog()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorStyles.primary100,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '확인',
            style: AppTextStyles.subtitle2Regular.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}