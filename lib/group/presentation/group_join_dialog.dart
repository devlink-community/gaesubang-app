import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:flutter/material.dart';

class GroupJoinDialog extends StatelessWidget {
  final Group group;
  final Function(GroupListAction) onAction;

  const GroupJoinDialog({
    super.key,
    required this.group,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${group.name}"',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: AppColorStyles.primary100,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text('스터디에 참여하시겠습니까?', style: AppTextStyles.subtitle1Medium),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 20,
                color: AppColorStyles.primary100,
              ),
              const SizedBox(width: 4),
              Text(
                '${group.memberCount}명 / ${group.limitMemberCount}명',
                style: AppTextStyles.body2Regular.copyWith(
                  color: AppColorStyles.primary100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 6,
            children: [
              Text(
                group.description ?? '설명이 없습니다.',
                style: AppTextStyles.body2Regular,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // 버튼들을 Row로 감싸서 좌우로 배치
        Row(
          children: [
            // 취소 버튼
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      () => onAction(const GroupListAction.onCloseDialog()),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('취소', style: AppTextStyles.button2Regular),
                  ),
                ),
              ),
            ),

            // 참여하기 버튼
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorStyles.primary100,
                    foregroundColor: AppColorStyles.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      () => onAction(GroupListAction.onJoinGroup(group.id)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '참여하기',
                      style: AppTextStyles.button2Regular.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
