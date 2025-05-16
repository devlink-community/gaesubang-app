import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:flutter/material.dart';

class GroupListItem extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final bool isCurrentMemberJoined;

  const GroupListItem({
    super.key,
    required this.group,
    required this.onTap,
    this.isCurrentMemberJoined = false,
  });

  // 최대 인원수 확인 메서드
  bool get _isGroupFull => group.memberCount >= group.limitMemberCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지
            _buildGroupImageContainer(),
            const SizedBox(width: 16),

            // 그룹 정보 컨테이너
            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 영역
                    _buildGroupNameWithOwner(),
                    const SizedBox(height: 8),
                    _buildHashTags(),
                    const Spacer(),
                    // 하단정보 행
                    _buildBottomInfoRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 그룹 이미지 컨테이너
  Widget _buildGroupImageContainer() {
    return Stack(
      children: [
        // 이미지
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColorStyles.primary100.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildGroupImage(),
          ),
        ),

        // 꽉찬 경우 오버레이 표시
        if (_isGroupFull && !isCurrentMemberJoined)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '인원 마감',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 활성 상태 표시 (참여 중인 경우)
        if (isCurrentMemberJoined)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColorStyles.secondary01,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColorStyles.secondary01.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  // 그룹 이름과 방장 정보
  Widget _buildGroupNameWithOwner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.name,
          style: AppTextStyles.subtitle1Bold.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            // 꽉찬 경우 회색으로 표시하되 이미 참여 중이면 정상 색상
            color:
                (_isGroupFull && !isCurrentMemberJoined)
                    ? AppColorStyles.gray80
                    : AppColorStyles.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColorStyles.gray40,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    group.owner.image.isNotEmpty
                        ? Image.network(
                          group.owner.image,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 10,
                                color: AppColorStyles.gray100,
                              ),
                        )
                        : const Icon(
                          Icons.person,
                          size: 10,
                          color: AppColorStyles.gray100,
                        ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              group.owner.nickname,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColorStyles.gray80,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  // 하단 정보 행 (멤버 수, 참여중 등)
  Widget _buildBottomInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 생성 일자 표시
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: AppColorStyles.gray60,
            ),
            const SizedBox(width: 4),
            Text(
              group.formattedCreatedDate,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColorStyles.gray60,
              ),
            ),
          ],
        ),

        // 참여 상태, 인원 수 또는 마감 상태
        if (isCurrentMemberJoined)
          _buildJoinedLabel()
        else if (_isGroupFull)
          _buildFullCapacityLabel()
        else
          _buildMemberCountDisplay(),
      ],
    );
  }

  // 그룹 이미지 위젯
  Widget _buildGroupImage() {
    if (group.imageUrl == null) {
      return Container(
        color: AppColorStyles.primary100.withOpacity(0.2),
        child: Center(
          child: Icon(
            Icons.groups_rounded,
            size: 40,
            color: AppColorStyles.primary100.withOpacity(0.7),
          ),
        ),
      );
    }

    if (group.imageUrl!.startsWith('assets/') ||
        group.imageUrl!.startsWith('asset/')) {
      return Image.asset(
        group.imageUrl!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    } else {
      return Image.network(
        group.imageUrl!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }
  }

  // 이미지 에러 위젯
  Widget _buildImageErrorWidget() {
    return Container(
      color: AppColorStyles.primary100.withOpacity(0.2),
      child: Icon(
        Icons.broken_image_rounded,
        size: 30,
        color: AppColorStyles.primary100.withOpacity(0.7),
      ),
    );
  }

  // 참여중 라벨
  Widget _buildJoinedLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorStyles.secondary01.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColorStyles.secondary01,
          ),
          const SizedBox(width: 4),
          Text(
            '참여중',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.secondary01,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 멤버 수 표시
  Widget _buildMemberCountDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorStyles.primary100.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 14, color: AppColorStyles.primary100),
          const SizedBox(width: 4),
          Text(
            '${group.memberCount}/${group.limitMemberCount}',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.primary100,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 인원 마감 라벨
  Widget _buildFullCapacityLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorStyles.gray40.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColorStyles.gray100,
          ),
          const SizedBox(width: 4),
          Text(
            '인원 마감',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.gray100,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 해시태그 목록
  Widget _buildHashTags() {
    final textColor =
        (_isGroupFull && !isCurrentMemberJoined)
            ? AppColorStyles.gray80
            : AppColorStyles.gray100;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...group.hashTags
            .take(3)
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${tag.content}',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.primary100,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

        // 3개 초과 시 '외 N개' 표시
        if (group.hashTags.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColorStyles.gray40.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '외 ${group.hashTags.length - 3}',
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColorStyles.gray100,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
