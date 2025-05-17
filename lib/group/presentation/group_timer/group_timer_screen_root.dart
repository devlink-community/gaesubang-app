import 'package:devlink_mobile_app/core/component/custom_alert_dialog.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupTimerScreenRoot extends ConsumerStatefulWidget {
  const GroupTimerScreenRoot({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupTimerScreenRoot> createState() =>
      _GroupTimerScreenRootState();
}

class _GroupTimerScreenRootState extends ConsumerState<GroupTimerScreenRoot>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // 앱 상태 변화 감지를 위한 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 초기 그룹 ID 설정 및 데이터 로드
    Future.microtask(() {
      final notifier = ref.read(groupTimerNotifierProvider.notifier);
      notifier.onAction(GroupTimerAction.setGroupId(widget.groupId));

      // 알림 권한 요청
      _checkNotificationPermission();
    });
  }

  // 알림 권한 확인 및 요청
  Future<void> _checkNotificationPermission() async {
    final hasPermission = await NotificationService().requestPermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('타이머 종료 알림을 받으려면 알림 권한을 허용해주세요.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    // 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱 상태 변화 감지 (백그라운드 전환 등)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 현재 타이머 상태 확인
    final timerState = ref.read(groupTimerNotifierProvider);
    final notifier = ref.read(groupTimerNotifierProvider.notifier);

    // 앱이 백그라운드로 전환되거나 비활성화될 때 타이머가 실행 중이면 종료
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.detached) &&
        timerState.timerStatus == TimerStatus.running) {
      // 타이머 종료 액션 실행
      notifier.onAction(const GroupTimerAction.stopTimer());

      // 로컬 알림 표시
      _showTimerEndedNotification(timerState);
    }
  }

  // 로컬 알림 표시 메서드
  void _showTimerEndedNotification(GroupTimerState state) {
    // NotificationService를 통한 알림 표시
    NotificationService().showTimerEndedNotification(
      groupName: state.groupName,
      elapsedSeconds: state.elapsedSeconds,
    );
  }

  // 화면 이동 전 경고창 표시
  Future<bool> _showNavigationWarningDialog(BuildContext context) async {
    if (mounted) {
      return await showDialog<bool>(
            context: context,
            builder:
                (context) => CustomAlertDialog(
                  title: '타이머가 실행 중입니다',
                  message: '화면을 이동하면 타이머가 종료됩니다. 계속하시겠습니까?',
                  cancelText: '취소',
                  confirmText: '이동',
                  onCancel: () => Navigator.of(context).pop(false),
                  onConfirm: () => Navigator.of(context).pop(true),
                ),
          ) ??
          false;
    }
    return true;
  }

  // 타이머 실행 중 화면 이동시 경고창 표시 후 처리
  Future<void> _handleNavigation(Function() navigationAction) async {
    final state = ref.read(groupTimerNotifierProvider);
    final notifier = ref.read(groupTimerNotifierProvider.notifier);

    // 타이머가 실행 중인지 확인
    if (state.timerStatus == TimerStatus.running) {
      // 경고창 표시 후 사용자 확인
      final shouldNavigate = await _showNavigationWarningDialog(context);

      if (shouldNavigate) {
        // 타이머 종료 후 화면 이동
        await notifier.onAction(const GroupTimerAction.stopTimer());
        navigationAction();
      }
    } else {
      // 타이머가 실행 중이 아니면 바로 화면 이동
      navigationAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독
    final state = ref.watch(groupTimerNotifierProvider);
    final notifier = ref.read(groupTimerNotifierProvider.notifier);

    // 디버깅 로그 추가
    print(
      '🔄 GroupTimerScreenRoot building with groupId: ${widget.groupId}, groupName: ${state.groupName}',
    );

    return PopScope(
      canPop: state.timerStatus != TimerStatus.running,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showNavigationWarningDialog(context).then((shouldPop) {
            if (shouldPop) {
              // 타이머 종료 후 pop 실행
              notifier.onAction(const GroupTimerAction.stopTimer()).then((_) {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            }
          });
        }
      },
      child: GroupTimerScreen(
        state: state,
        onAction: (action) async {
          switch (action) {
            case NavigateToAttendance():
              // 출석부(캘린더) 화면으로 이동 - 경고창 표시 후 처리
              await _handleNavigation(() {
                context.push('/group/${widget.groupId}/attendance');
              });

            case NavigateToSettings():
              // 그룹 설정 화면으로 이동 - 경고창 표시 후 처리
              await _handleNavigation(() {
                context.push('/group/${widget.groupId}/settings');
              });

            case NavigateToUserProfile(:final userId):
              // 사용자 프로필 화면으로 이동 - 경고창 표시 후 처리
              await _handleNavigation(() {
                context.push('/user/$userId/profile');
              });

            default:
              // 기타 액션은 Notifier에 위임
              await notifier.onAction(action);
          }
        },
      ),
    );
  }
}
