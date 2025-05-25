import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/attendance_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    // 로케일 초기화가 완료되기 전까지 로딩 화면 표시
    if (!state.isLocaleInitialized) {
      return _buildLoadingScreen();
    }

    return AttendanceScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case ShowDateAttendanceBottomSheet(:final date):
            await _showAttendanceBottomSheet(context, date, notifier);
          case NavigateToUserProfile(:final userId):
            // 사용자 프로필로 이동
            await context.push('/user/$userId/profile');
          default:
            await notifier.onAction(action);
        }
      },
    );
  }

  // 로딩 화면
  Widget _buildLoadingScreen() {
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

  // 출석 정보 버텀 시트 표시
  Future<void> _showAttendanceBottomSheet(
    BuildContext context,
    DateTime selectedDate,
    AttendanceNotifier notifier,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return AttendanceBottomSheet(
              selectedDate: selectedDate,
              notifier: notifier,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}
