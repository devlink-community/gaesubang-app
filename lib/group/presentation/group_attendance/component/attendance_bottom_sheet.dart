import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/attendance_summary_card.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/empty_attendance_view.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/member_attendance_card.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attendance_notifier.dart';

class AttendanceBottomSheet extends ConsumerWidget {
  final DateTime selectedDate;
  final AttendanceNotifier notifier;
  final ScrollController scrollController;

  const AttendanceBottomSheet({
    super.key,
    required this.selectedDate,
    required this.notifier,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 날짜 포맷팅은 notifier의 안전한 메서드 사용
    final dateStr = notifier.formatDateSafely(selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: AppColorStyles.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.blackOverlay(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColorStyles.gray40,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorStyles.primary100.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColorStyles.primary100,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: AppTextStyles.subtitle1Bold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '출석한 멤버 현황',
                        style: AppTextStyles.body2Regular.copyWith(
                          color: AppColorStyles.gray100,
                        ),
                      ),
                    ],
                  ),
                ),
                // 닫기 버튼
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: AppColorStyles.gray100,
                  ),
                  iconSize: 20,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 콘텐츠
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: _buildContent(ref),
            ),
          ),
        ],
      ),
    );
  }

  // 버텀 시트 콘텐츠
  Widget _buildContent(WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);

    return switch (state.attendanceList) {
      AsyncLoading() => _buildLoadingContent(),
      AsyncError(:final error) => _buildErrorContent(error),
      AsyncData() => _buildAttendanceContent(),
      _ => _buildLoadingContent(),
    };
  }

  Widget _buildLoadingContent() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColorStyles.primary100,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            '출석 정보를 불러오는 중...',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColorStyles.error,
          ),
          const SizedBox(height: 16),
          Text(
            '데이터를 불러올 수 없습니다',
            style: AppTextStyles.subtitle1Bold,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.gray100,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    final sortedEntries = notifier.getSortedMemberAttendances();

    if (sortedEntries.isEmpty) {
      return const EmptyAttendanceView();
    }

    // 총 학습 시간, 멤버 수, 평균 시간 계산은 notifier에서 가져옴
    final totalMinutes = notifier.getTotalMinutes();
    final memberCount = sortedEntries.length;
    final avgMinutes = notifier.getAverageMinutes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요약 정보
        AttendanceSummaryCard(
          totalMinutes: totalMinutes,
          memberCount: memberCount,
          avgMinutes: avgMinutes,
        ),
        const SizedBox(height: 24),

        // 멤버별 상세 정보
        Row(
          children: [
            Text(
              '출석한 멤버',
              style: AppTextStyles.subtitle1Bold,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${memberCount}명',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColorStyles.primary100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 멤버 리스트 (개선된 카드 사용)
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final userId = entry.value.key;
          final memberAttendances = entry.value.value;
          final totalMinutes = memberAttendances.fold<int>(
            0,
            (sum, attendance) => sum + attendance.timeInMinutes,
          );

          // 첫 번째 항목에서 멤버 정보 가져오기
          final memberInfo = memberAttendances.first;

          return MemberAttendanceCard(
            userName: memberInfo.userName,
            userId: userId,
            profileUrl: memberInfo.profileUrl,
            totalMinutes: totalMinutes,
            rank: index + 1,
          );
        }),
      ],
    );
  }
}
