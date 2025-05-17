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
  bool _isTimerStopped = false;
  bool _hasNotificationPermission = false;

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
      _requestNotificationPermission();
    });
  }

  // 알림 권한 확인 및 요청
  Future<void> _requestNotificationPermission() async {
    final notificationService = NotificationService();
    final hasPermission = await notificationService.requestPermission();

    // 권한 없을 때 안내 메시지 표시
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('타이머 종료 알림을 받으려면 알림 권한을 허용해주세요.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '설정',
            onPressed: () {
              // 앱 설정 화면으로 이동 (앱 설정에서 알림 권한 설정 가능)
              notificationService.openNotificationSettings();
            },
          ),
        ),
      );
    }

    // 알림 권한 상태 기록 (권한이 없어도 타이머는 동작하도록)
    _hasNotificationPermission = hasPermission;
  }

  @override
  void dispose() {
    // dispose 될 때 타이머 종료
    _stopTimerIfRunning(isAppTerminating: true);

    // 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱 상태 변화 감지 (백그라운드 전환 등)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 백그라운드로 전환되거나 비활성화될 때 타이머가 실행 중이면 종료
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // detached는 앱 종료 상태를 나타낼 수 있음
      bool isAppTerminating = state == AppLifecycleState.detached;
      _stopTimerIfRunning(isAppTerminating: isAppTerminating);
    }
    // 앱이 다시 활성화될 때(백그라운드에서 돌아왔을 때) 타이머 상태 리셋
    else if (state == AppLifecycleState.resumed) {
      // 앱이 재개되었을 때 처리
      if (_isTimerStopped) {
        // 타이머가 중지된 상태면 상태를 초기화
        final notifier = ref.read(groupTimerNotifierProvider.notifier);
        notifier.onAction(const GroupTimerAction.resetTimer());
        _isTimerStopped = false;

        // 사용자에게 타이머가 중지되었음을 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('앱이 백그라운드에 있는 동안 타이머가 중지되었습니다.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // 타이머 상태와 상관없이 데이터 새로고침
      final notifier = ref.read(groupTimerNotifierProvider.notifier);
      notifier.refreshAllData();
    }
  }

  // 타이머가 실행 중인 경우 종료하는 메서드
  Future<void> _stopTimerIfRunning({bool isAppTerminating = false}) async {
    // 이미 타이머가 중지된 경우 처리하지 않음
    if (_isTimerStopped) return;

    // 현재 타이머 상태 확인
    final timerState = ref.read(groupTimerNotifierProvider);

    // 타이머가 실행 중이거나 일시 중지 상태인 경우 처리
    if (timerState.timerStatus == TimerStatus.running ||
        timerState.timerStatus == TimerStatus.paused) {
      final notifier = ref.read(groupTimerNotifierProvider.notifier);

      // 타이머 종료 액션 실행
      await notifier.onAction(const GroupTimerAction.stopTimer());

      // 타이머 종료 플래그 설정
      _isTimerStopped = true;

      // 로컬 알림 표시 (실행 중이었을 때만)
      if (timerState.timerStatus == TimerStatus.running) {
        await _showTimerEndedNotification(
          timerState,
          isAppTerminating: isAppTerminating,
        );
      }
    }
  }

  // 로컬 알림 표시 메서드
  Future<void> _showTimerEndedNotification(
    GroupTimerState state, {
    bool isAppTerminating = false,
  }) async {
    // 알림 메시지에 앱 종료 표시 추가
    final String titlePrefix = isAppTerminating ? '앱 종료: ' : '';

    // NotificationService를 통한 알림 표시
    await NotificationService().showTimerEndedNotification(
      groupName: state.groupName,
      elapsedSeconds: state.elapsedSeconds,
      titlePrefix: titlePrefix,
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
        _isTimerStopped = true;
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
                _isTimerStopped = true;
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
