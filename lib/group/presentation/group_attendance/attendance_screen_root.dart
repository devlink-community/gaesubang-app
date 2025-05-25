import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'attendance_action.dart';
import 'attendance_notifier.dart';
import 'attendance_screen.dart';

class AttendanceScreenRoot extends ConsumerStatefulWidget {
  final String groupId;

  const AttendanceScreenRoot({super.key, required this.groupId});

  @override
  ConsumerState<AttendanceScreenRoot> createState() =>
      _AttendanceScreenRootState();
}

class _AttendanceScreenRootState extends ConsumerState<AttendanceScreenRoot> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 로케일 초기화와 그룹 ID 설정을 순차적으로 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(attendanceNotifierProvider.notifier);

      // 1. 먼저 로케일 초기화
      await notifier.onAction(const AttendanceAction.initializeLocale());

      // 2. 그다음 그룹 ID 설정
      await notifier.onAction(AttendanceAction.setGroupId(widget.groupId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.watch(attendanceNotifierProvider.notifier);

    // 🔧 로케일 초기화가 완료되기 전까지 로딩 화면 표시
    if (!state.isLocaleInitialized) {
      return Scaffold(
        backgroundColor: AppColorStyles.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: AppColorStyles.primary100,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '출석부를 준비하는 중...',
                style: AppTextStyles.subtitle1Bold,
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려 주세요',
                style: AppTextStyles.body2Regular.copyWith(
                  color: AppColorStyles.gray100,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AttendanceScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case ShowDateAttendanceBottomSheet(:final date):
            await _showAttendanceBottomSheet(context, date, state, notifier);
          case NavigateToUserProfile(:final userId):
            // 사용자 프로필로 이동
            await context.push('/user/$userId/profile');
          default:
            await notifier.onAction(action);
        }
      },
    );
  }

  // 출석 정보 버텀 시트 표시
  Future<void> _showAttendanceBottomSheet(
    BuildContext context,
    DateTime selectedDate,
    dynamic state,
    dynamic notifier,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _buildAttendanceBottomSheet(selectedDate, state, notifier),
    );
  }

  // 세련된 버텀 시트
  Widget _buildAttendanceBottomSheet(
    DateTime selectedDate,
    dynamic state,
    dynamic notifier,
  ) {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    // 🔧 notifier의 안전한 날짜 포맷팅 사용
    final dateStr = notifier.formatDateSafely(selectedDate);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
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
                  child: _buildBottomSheetContent(selectedDateStr, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 버텀 시트 콘텐츠
  Widget _buildBottomSheetContent(String selectedDateStr, dynamic state) {
    switch (state.attendanceList) {
      case AsyncLoading():
        return _buildLoadingContent();
      case AsyncError():
        return _buildErrorContent();
      case AsyncData(:final value):
        return _buildAttendanceContent(value, selectedDateStr);
      default:
        return _buildLoadingContent();
    }
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

  Widget _buildErrorContent() {
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
            '네트워크 연결을 확인해 주세요',
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent(
    List<dynamic> attendances,
    String selectedDateStr,
  ) {
    // 선택된 날짜의 출석 데이터 필터링
    final attendancesForDate =
        attendances
            .where(
              (a) => DateFormat('yyyy-MM-dd').format(a.date) == selectedDateStr,
            )
            .toList();

    if (attendancesForDate.isEmpty) {
      return _buildEmptyContent();
    }

    // 멤버별로 그룹화
    final groupedByMember = <String, List<dynamic>>{};
    for (final attendance in attendancesForDate) {
      final userId = attendance.userId;
      groupedByMember.putIfAbsent(userId, () => []);
      groupedByMember[userId]!.add(attendance);
    }

    // 총 학습 시간별로 정렬 (내림차순)
    final sortedEntries =
        groupedByMember.entries.toList()..sort((a, b) {
          final totalA = a.value.fold<int>(
            0,
            (sum, attendance) => sum + (attendance.timeInMinutes as int),
          );
          final totalB = b.value.fold<int>(
            0,
            (sum, attendance) => sum + (attendance.timeInMinutes as int),
          );
          return totalB.compareTo(totalA);
        });

    // 총 학습 시간 계산
    final totalMinutes = attendancesForDate.fold<int>(
      0,
      (sum, attendance) => sum + (attendance.timeInMinutes as int),
    );

    // 평균 학습 시간 계산
    final memberCount = groupedByMember.length;
    final avgMinutes = memberCount > 0 ? totalMinutes ~/ memberCount : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요약 정보
        _buildSummaryCard(totalMinutes, memberCount, avgMinutes),
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
                '${sortedEntries.length}명',
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
          final memberAttendances = entry.value.value;
          final totalMinutes = memberAttendances.fold<int>(
            0,
            (sum, attendance) => sum + (attendance.timeInMinutes as int),
          );

          return _buildMemberCard(
            memberAttendances.first,
            totalMinutes,
            index + 1,
          );
        }),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorStyles.gray40.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 32,
              color: AppColorStyles.gray100,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '이 날짜에는 출석한 멤버가 없습니다',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '그룹 타이머를 사용해서 함께 공부해 보세요!',
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalMinutes, int memberCount, int avgMinutes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColorStyles.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary100.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColorStyles.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '일일 요약',
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: AppColorStyles.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 학습시간',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMinutes(totalMinutes),
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorStyles.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '참여 멤버',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$memberCount명',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorStyles.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평균 시간',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMinutes(avgMinutes),
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 활동량 시각화 (추가)
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppColorStyles.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width:
                      (totalMinutes > 0)
                          ? (totalMinutes /
                              (totalMinutes + 120) *
                              MediaQuery.of(context).size.width *
                              0.8)
                          : 0,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColorStyles.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(dynamic attendance, int totalMinutes, int rank) {
    final color = _getColorByTime(totalMinutes);
    final icon = _getIconByTime(totalMinutes);

    return InkWell(
      // 탭 가능한 위젯으로 변경
      onTap: () {
        // 사용자 ID가 있을 때만 네비게이션 수행
        final userId = attendance.userId;
        if (userId != null && userId.isNotEmpty) {
          context.push('/user/$userId/profile');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 순위
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: rank <= 3 ? _getRankColor(rank) : AppColorStyles.gray80,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 프로필 - 프로필 이미지 사용 또는 이니셜 표시
            _buildProfileAvatar(attendance, color),
            const SizedBox(width: 16),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        attendance.userName ?? '멤버 ${attendance.userId}',
                        style: AppTextStyles.subtitle1Bold,
                      ),
                      if (rank == 1) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '학습시간: ${_formatMinutes(totalMinutes)}',
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.gray100,
                    ),
                  ),
                ],
              ),
            ),

            // 상태 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            // 프로필 이동 아이콘 추가
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColorStyles.gray80,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 프로필 아바타 빌드 (URL 또는 이니셜)
  Widget _buildProfileAvatar(dynamic attendance, Color color) {
    // 프로필 URL이 있으면 네트워크 이미지 사용
    if (attendance.profileUrl != null && attendance.profileUrl.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(attendance.profileUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 프로필 URL이 없으면 이니셜 표시
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitial(attendance.userName),
          style: AppTextStyles.subtitle1Bold.copyWith(
            color: AppColorStyles.white,
          ),
        ),
      ),
    );
  }

  // 유틸리티 메서드들
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // 금
      case 2:
        return Colors.grey[400]!; // 은
      case 3:
        return Colors.brown[400]!; // 동
      default:
        return AppColorStyles.gray80;
    }
  }

  Color _getColorByTime(int minutes) {
    if (minutes >= 240) {
      return AppColorStyles.primary100; // 4시간 이상
    } else if (minutes >= 120) {
      return AppColorStyles.primary80; // 2시간 이상
    } else if (minutes >= 30) {
      return AppColorStyles.primary60; // 30분 이상
    } else {
      return AppColorStyles.gray100; // 30분 미만
    }
  }

  IconData _getIconByTime(int minutes) {
    if (minutes >= 240) {
      return Icons.star; // 4시간 이상
    } else if (minutes >= 120) {
      return Icons.thumb_up; // 2시간 이상
    } else if (minutes >= 30) {
      return Icons.check_circle; // 30분 이상
    } else {
      return Icons.access_time; // 30분 미만
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours시간 ${mins > 0 ? "$mins분" : ""}';
    } else {
      return '$mins분';
    }
  }

  // 이름에서 이니셜 추출
  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.substring(0, 1);
  }
}
