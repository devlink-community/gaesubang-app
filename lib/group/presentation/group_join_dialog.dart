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
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorStyles.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더 영역 (그룹 이미지 포함)
            // _buildDialogHeader(), // -> 2차 개발

            // 콘텐츠 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 그룹 이름과 참여 확인 메시지
                  _buildTitle(),

                  // 멤버 정보
                  _buildMemberInfo(),

                  // 그룹 설명
                  _buildDescription(),

                  // 해시태그
                  _buildHashTags(),

                  const SizedBox(height: 24),

                  // 액션 버튼들
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 헤더 (그룹 이미지)
  Widget _buildDialogHeader() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: AppColorStyles.gray40.withOpacity(0.3),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child:
            group.imageUrl != null
                ? Image.network(
                  group.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder:
                      (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.groups_rounded,
                          size: 60,
                          color: AppColorStyles.gray60,
                        ),
                      ),
                )
                : Center(
                  child: Icon(
                    Icons.groups_rounded,
                    size: 60,
                    color: AppColorStyles.gray60,
                  ),
                ),
      ),
    );
  }

  // 제목 영역
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: AppTextStyles.heading6Bold.copyWith(
              color: AppColorStyles.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '이 그룹에 참여하시겠습니까?',
            style: AppTextStyles.subtitle1Medium.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
        ],
      ),
    );
  }

  // 멤버 정보
  Widget _buildMemberInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColorStyles.primary100.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 22,
            color: AppColorStyles.primary100,
          ),
          const SizedBox(width: 8),
          Text(
            '현재 ${group.memberCount}명이 참여 중입니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.primary100,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '최대 ${group.limitMemberCount}명',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
        ],
      ),
    );
  }

  // 그룹 설명
  Widget _buildDescription() {
    final description = group.description.trim() ?? '';

    if (description.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        description,
        style: AppTextStyles.body1Regular.copyWith(
          color: AppColorStyles.textPrimary,
          height: 1.5,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 해시태그
  Widget _buildHashTags() {
    if (group.hashTags.isEmpty) {
      return const SizedBox();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          group.hashTags
              .take(5)
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorStyles.gray40.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${tag.content}',
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.gray100,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  // 액션 버튼
  Widget _buildActionButtons() {
    return Row(
      children: [
        // 취소 버튼
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColorStyles.gray40.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => onAction(const GroupListAction.onCloseDialog()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '취소',
                style: AppTextStyles.button1Medium.copyWith(
                  color: AppColorStyles.gray100,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 참여하기 버튼
        Expanded(
          child: ElevatedButton(
            onPressed: () => onAction(GroupListAction.onJoinGroup(group.id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorStyles.primary100,
              foregroundColor: AppColorStyles.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '참여',
              style: AppTextStyles.button1Medium.copyWith(
                color: AppColorStyles.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
