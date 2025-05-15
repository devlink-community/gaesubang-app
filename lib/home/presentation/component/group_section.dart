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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(),
        const SizedBox(height: 12),
        _buildGroupList(context),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColorStyles.primary80, size: 20),
        const SizedBox(width: 8),
        Text('My Groups', style: AppTextStyles.subtitle1Bold),
      ],
    );
  }

  Widget _buildGroupList(BuildContext context) {
    return groups.when(
      data: (data) {
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('가입한 그룹이 없습니다')),
          );
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final group = data[index];
              return _buildGroupItem(context, group);
            },
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '그룹 목록을 불러오는데 실패했습니다: $error',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.error,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildGroupItem(BuildContext context, Group group) {
    // 임시 색상 배열 (실제로는 이미지를 사용)
    final colors = [
      AppColorStyles.primary80,
      AppColorStyles.secondary01,
      AppColorStyles.info,
    ];

    // 색상 인덱스 계산 (그룹 ID의 해시값으로 인덱스 결정)
    final colorIndex = group.id.hashCode % colors.length;

    return GestureDetector(
      onTap: () => onTapGroup(group.id),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // 원형 그룹 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[colorIndex],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                image:
                    group.imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(group.imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  group.imageUrl == null
                      ? Center(
                        child: Text(
                          group.name.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.heading2Bold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
