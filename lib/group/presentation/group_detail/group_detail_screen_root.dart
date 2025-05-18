import 'package:devlink_mobile_app/core/component/custom_alert_dialog.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupDetailScreenRoot extends ConsumerStatefulWidget {
  const GroupDetailScreenRoot({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreenRoot> createState() =>
      _GroupDetailScreenRootState();
}

class _GroupDetailScreenRootState extends ConsumerState<GroupDetailScreenRoot>
    with WidgetsBindingObserver {
  // 화면 상태 관리
  bool _isInitialized = false;
  bool _wasInBackground = false;
  bool _hasNotificationPermission = false;

  // 초기화 중 생명주기 이벤트 무시
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    // 앱 상태 변화 감지를 위한 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 초기화 플래그 설정
    _isInitializing = true;

    // 화면 초기화를 위젯 빌드 이후로 지연
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // 화면 초기화 (최초 진입 시에만 호출)
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    print('🚀 화면 초기화 시작 - groupId: ${widget.groupId}');

    if (mounted) {
      final notifier = ref.read(groupDetailNotifierProvider.notifier);
      await notifier.onAction(GroupDetailAction.setGroupId(widget.groupId));
      await _requestNotificationPermission();
    }

    _isInitialized = true;

    // 초기화 완료 후 생명주기 이벤트 처리 재개
    _isInitializing = false;

    print('✅ 화면 초기화 완료');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 초기화 중이면 생명주기 이벤트 무시
    if (_isInitializing) {
      print('🔄 초기화 중이므로 생명주기 이벤트 무시: $state');
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        // paused 상태에서만 백그라운드 처리 (중복 방지)
        if (_isInitialized && !_isInitializing && !_wasInBackground) {
          print('📱 앱이 백그라운드로 전환됨');
          _wasInBackground = true;

          // 타이머가 실행 중이면 종료
          if (mounted) {
            final notifier = ref.read(groupDetailNotifierProvider.notifier);
            notifier.onAction(const GroupDetailAction.stopTimer());
          }
        }
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // inactive와 detached는 로그만 남기고 처리하지 않음
        print('🔄 생명주기 상태 변경: $state (처리 안함)');
        break;

      case AppLifecycleState.resumed:
        // 실제 백그라운드에서 돌아온 경우만 처리
        if (_wasInBackground && mounted && _isInitialized && !_isInitializing) {
          print('🔄 백그라운드에서 앱 재개 - 데이터 갱신');
          // 데이터 갱신을 다음 프레임으로 지연
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final notifier = ref.read(groupDetailNotifierProvider.notifier);
              notifier.onScreenReenter();
              _showAppResumedMessage();
            }
          });
        }
        _wasInBackground = false;
        break;

      case AppLifecycleState.hidden:
        // hidden 상태는 특별한 처리 없음
        print('🔄 생명주기 상태 변경: $state');
        break;
    }
  }

  @override
  void dispose() {
    // 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
              notificationService.openNotificationSettings();
            },
          ),
        ),
      );
    }

    _hasNotificationPermission = hasPermission;
  }

  // 앱 재개 시 사용자에게 메시지 표시
  void _showAppResumedMessage() {
    // 잠시 후에 상태를 확인하여 타이머가 초기화되었는지 확인
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final currentState = ref.read(groupDetailNotifierProvider);
        // 타이머가 초기 상태가 되었다면 백그라운드에서 중지되었다는 뜻
        if (currentState.timerStatus == TimerStatus.initial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('앱이 백그라운드에 있는 동안 타이머가 중지되었습니다.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
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
    if (!mounted) return;

    final state = ref.read(groupDetailNotifierProvider);
    final notifier = ref.read(groupDetailNotifierProvider.notifier);

    // 타이머가 실행 중인지 확인
    if (state.timerStatus == TimerStatus.running) {
      // 경고창 표시 후 사용자 확인
      final shouldNavigate = await _showNavigationWarningDialog(context);

      if (shouldNavigate && mounted) {
        // 타이머 종료 후 화면 이동
        await notifier.onAction(const GroupDetailAction.stopTimer());
        navigationAction();
      }
    } else {
      // 타이머가 실행 중이 아니면 바로 화면 이동
      navigationAction();
    }
  }

  // 다른 화면에서 돌아올 때 감지 및 처리
  void _handleScreenReturn() {
    if (mounted && _isInitialized && !_isInitializing) {
      print('🔄 다른 화면에서 돌아옴 - 데이터 갱신');
      // 데이터 갱신을 다음 프레임으로 지연
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final notifier = ref.read(groupDetailNotifierProvider.notifier);
          notifier.onScreenReenter();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독
    final state = ref.watch(groupDetailNotifierProvider);
    final notifier = ref.read(groupDetailNotifierProvider.notifier);

    return PopScope(
      canPop: state.timerStatus != TimerStatus.running,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // 실제로 pop이 발생했을 때 - 이전 화면으로 돌아감
          // 여기서는 아무것도 하지 않음 (상위 화면으로 나가는 것)
        } else {
          // pop이 취소되었을 때 - 타이머 실행 중이어서 경고창 표시
          _showNavigationWarningDialog(context).then((shouldPop) {
            if (shouldPop && mounted) {
              // 타이머 종료 후 pop 실행
              notifier.onAction(const GroupDetailAction.stopTimer()).then((_) {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            }
          });
        }
      },
      child: GroupDetailScreen(
        state: state,
        onAction: (action) async {
          if (!mounted) return;

          switch (action) {
            case NavigateToAttendance():
              // 출석부(캘린더) 화면으로 이동 - 경고창 표시 후 처리
              await _handleNavigation(() async {
                await context.push('/group/${widget.groupId}/group_attendance');
                // 화면에서 돌아왔을 때 데이터 갱신
                _handleScreenReturn();
              });

            case NavigateToSettings():
              // 그룹 설정 화면으로 이동 - 경고창 표시 후 처리
              await _handleNavigation(() async {
                await context.push('/group/${widget.groupId}/settings');
                // 화면에서 돌아왔을 때 데이터 갱신
                _handleScreenReturn();
              });

            case NavigateToUserProfile(:final userId):
              // 사용자 프로필 화면으로 이동 - 경고창 표시 후 처리
              await _handleNavigation(() async {
                await context.push('/user/$userId/profile');
                // 화면에서 돌아왔을 때 데이터 갱신
                _handleScreenReturn();
              });

            default:
              // 기타 액션은 Notifier에 위임
              if (mounted) {
                await notifier.onAction(action);
              }
          }
        },
      ),
    );
  }
}
