import 'package:devlink_mobile_app/group/presentation/group_detail/components/member_timer_item.dart';
import 'package:flutter/material.dart';

import '../../../../core/styles/app_color_styles.dart';
import '../../../../core/styles/app_text_styles.dart';

class MemberGrid extends StatelessWidget {
  final List<MemberTimer> members;
  final Function(String) onMemberTap;

  const MemberGrid({
    super.key,
    required this.members,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        // 화면 너비에 따라 적절한 열 수 계산 (3~5 사이)
        final int crossAxisCount = (maxWidth / 100).floor().clamp(3, 5);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.95,
            // 이용자 간 간격 줄이기
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
          ),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            // 멤버가 활성 상태인지 확인
            final bool isActive =
                member.status == 'active' || member.status == 'studying';

            return GestureDetector(
              onTap: () => onMemberTap(member.memberId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color:
                      isActive
                          ? AppColorStyles.primary100.withValues(alpha: 0.03)
                          : Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 프로필 이미지와 타이머
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 배경 효과 (활성 상태인 경우)
                          if (isActive)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColorStyles.primary80.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // MemberTimerItem 컴포넌트
                    MemberTimerItem(
                      imageUrl: member.imageUrl,
                      status: member.status,
                      timeDisplay: member.timeDisplay,
                    ),

                    Text(
                      '이용자${index + 1}',
                      style: AppTextStyles.captionRegular.copyWith(
                        color:
                            isActive
                                ? AppColorStyles.primary100
                                : AppColorStyles.gray100,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
