import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../../../group/domain/model/group.dart';

class GroupSection extends StatelessWidget {
  final AsyncValue<List<Group>> groups;
  final Function(String groupId) onTapGroup;

  const GroupSection({
    super.key,
    required this.groups,
    required this.onTapGroup,
  });

  @override
  Widget build(BuildContext context) {
    return groups.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState();
        }
        return _buildGroupList(context, data);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildGroupList(BuildContext context, List<Group> data) {
    return SizedBox(
      height: 180, // 충분한 높이 확보
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: data.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == data.length) {
            return _buildAddGroupButton();
          }
          final group = data[index];
          return _buildGroupItem(context, group, index);
        },
      ),
    );
  }

  Widget _buildGroupItem(BuildContext context, Group group, int index) {
    // 그라데이션 색상 세트
    final gradientSets = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CCED), const Color(0xFF5583EE)],
    ];

    final gradientIndex = index % gradientSets.length;

    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8), // 그림자 여백 확보
      width: 120,
      child: GestureDetector(
        onTap: () => onTapGroup(group.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 164, // 명시적 높이 설정 (180 - 상하마진 16)
          decoration: BoxDecoration(
            gradient: group.imageUrl == null
                ? LinearGradient(
              colors: gradientSets[gradientIndex],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientSets[gradientIndex][0].withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            image: group.imageUrl != null
                ? DecorationImage(
              image: NetworkImage(group.imageUrl!),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.2),
                BlendMode.darken,
              ),
            )
                : null,
          ),
          child: Stack(
            children: [
              // 그라데이션 오버레이 (이미지가 있는 경우)
              if (group.imageUrl != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

              // 컨텐츠 영역
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단: 멤버 수 뱃지 (고정 높이)
                    SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: gradientSets[gradientIndex][0],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.memberCount}',
                                  style: AppTextStyles.captionRegular.copyWith(
                                    color: gradientSets[gradientIndex][0],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 중간 여백을 Spacer로 유연하게 처리
                    const Spacer(),

                    // 하단: 그룹 정보 (유연한 높이)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 기본 아이콘 (이미지가 없는 경우)
                        if (group.imageUrl == null)
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                        // 그룹명 (최대 2줄)
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 36, // 2줄 최대 높이 제한
                          ),
                          child: Text(
                            group.name,
                            style: AppTextStyles.subtitle1Bold.copyWith(
                              color: Colors.white,
                              height: 1.2, // 줄간격 조정
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 해시태그 (고정 높이)
                        if (group.hashTags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 16,
                            child: Text(
                              '#${group.hashTags.first}',
                              style: AppTextStyles.captionRegular.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 탭 영역 (전체 영역)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTapGroup(group.id),
                    borderRadius: BorderRadius.circular(24),
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      width: 120,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 164,
        decoration: BoxDecoration(
          color: AppColorStyles.primary80.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColorStyles.primary80.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to create/join group
            },
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColorStyles.primary80.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColorStyles.primary80,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '그룹 추가',
                  style: AppTextStyles.subtitle2Regular.copyWith(
                    color: AppColorStyles.primary80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorStyles.primary80.withValues(alpha: 0.05),
            AppColorStyles.primary80.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColorStyles.primary80.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorStyles.primary80.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add_rounded,
                size: 32,
                color: AppColorStyles.primary80,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 가입한 그룹이 없어요',
              style: AppTextStyles.body1Regular.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Navigate to group search
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColorStyles.primary80,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '그룹 찾아보기',
                    style: AppTextStyles.body2Regular,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            width: 120,
            height: 164,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 뱃지 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 하단 정보 영역
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColorStyles.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColorStyles.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: AppColorStyles.error,
            ),
            const SizedBox(height: 12),
            Text(
              '그룹 목록을 불러오는데 실패했습니다',
              style: AppTextStyles.body2Regular.copyWith(
                color: AppColorStyles.error,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Retry logic
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColorStyles.error,
              ),
              child: Text(
                '다시 시도',
                style: AppTextStyles.body2Regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}