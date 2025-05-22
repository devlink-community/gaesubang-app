// lib/group/presentation/group_detail/group_detail_screen_root.dart
import 'package:devlink_mobile_app/core/component/custom_alert_dialog.dart';
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
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
  // 🔥 Root 역할: 생명주기 관리 및 초기화
  bool _isInitialized = false;
  bool _wasInBackground = false;
  bool _isInitializing = false;

  // 🔧 새로 추가: 상태 메시지 표시 관리
  String? _lastShownStatusMessage;
  DateTime? _lastStatusMessageTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isInitializing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    // 🔧 개선: dispose 시 화면 비활성 상태 알림
    if (_isInitialized) {
      print('🔄 화면 dispose - Notifier에 비활성 상태 알림');
      final notifier = ref.read(groupDetailNotifierProvider.notifier);
      notifier.setScreenActive(false);
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔧 개선된 생명주기 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isInitializing) {
      print('🔄 초기화 중이므로 생명주기 이벤트 무시: $state');
      return;
    }

    final notifier = ref.read(groupDetailNotifierProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        if (_isInitialized && !_isInitializing && !_wasInBackground) {
          print('📱 앱이 백그라운드로 전환됨');
          _wasInBackground = true;

          // 🔧 Notifier에 포그라운드 상태 변경 알림
          notifier.setAppForeground(false);

          // 타이머 실행 중이면 중지
          if (mounted) {
            final currentState = ref.read(groupDetailNotifierProvider);
            if (currentState.timerStatus == TimerStatus.running) {
              notifier.onAction(const GroupDetailAction.stopTimer());
            }
          }
        }
        break;

      case AppLifecycleState.resumed:
        if (_wasInBackground && mounted && _isInitialized && !_isInitializing) {
          print('🔄 백그라운드에서 앱 재개 - 데이터 갱신');

          // 🔧 Notifier에 포그라운드 상태 변경 알림
          notifier.setAppForeground(true);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              notifier.onScreenReenter();
              _showAppResumedMessage();
            }
          });
        }
        _wasInBackground = false;
        break;

      case AppLifecycleState.inactive:
        // 🔧 추가: 일시적 비활성 상태 (전화 수신, 알림 패널 등)
        if (_isInitialized && !_wasInBackground) {
          print('📱 앱이 일시적으로 비활성화됨');
          notifier.setAppForeground(false);
        }
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        print('🔄 생명주기 상태 변경: $state');
        // 앱이 완전히 종료되거나 숨겨진 상태
        if (_isInitialized) {
          notifier.setAppForeground(false);
          notifier.setScreenActive(false);
        }
        break;
    }
  }

  // 🔥 Root 역할: 화면 초기화
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    print('🚀 화면 초기화 시작 - groupId: ${widget.groupId}');

    if (mounted) {
      final notifier = ref.read(groupDetailNotifierProvider.notifier);

      // 🔧 화면 활성 상태 설정
      notifier.setScreenActive(true);
      notifier.setAppForeground(true);

      await notifier.onAction(GroupDetailAction.setGroupId(widget.groupId));
      await _requestNotificationPermission();
    }

    _isInitialized = true;
    _isInitializing = false;
    print('✅ 화면 초기화 완료');
  }

  // 🔧 새로운 메서드: 상태 메시지 처리
  void _handleStatusMessage(String? statusMessage) {
    if (statusMessage == null || statusMessage.isEmpty) return;

    // 🔧 같은 메시지를 짧은 시간 내에 중복 표시하지 않음
    if (_lastShownStatusMessage == statusMessage &&
        _lastStatusMessageTime != null &&
        DateTime.now().difference(_lastStatusMessageTime!).inSeconds < 5) {
      return;
    }

    _lastShownStatusMessage = statusMessage;
    _lastStatusMessageTime = DateTime.now();

    print('📢 상태 메시지 표시: $statusMessage');

    // 🔧 스낵바 우선순위에 따라 다른 duration 설정
    Duration duration;
    Color? backgroundColor;

    if (statusMessage.contains('연결 중')) {
      duration = const Duration(seconds: 2);
      backgroundColor = Colors.blue.shade100;
    } else if (statusMessage.contains('재연결')) {
      duration = const Duration(seconds: 3);
      backgroundColor = Colors.orange.shade100;
    } else if (statusMessage.contains('문제가 발생')) {
      duration = const Duration(seconds: 5);
      backgroundColor = Colors.red.shade100;
    } else {
      duration = const Duration(seconds: 3);
    }

    // 🔧 기존 스낵바 제거 후 새 스낵바 표시
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // 🔧 상태에 따른 아이콘 표시
            Icon(
              statusMessage.contains('연결 중')
                  ? Icons.wifi_find
                  : statusMessage.contains('재연결')
                  ? Icons.refresh
                  : statusMessage.contains('문제가 발생')
                  ? Icons.error_outline
                  : Icons.info_outline,
              color:
                  statusMessage.contains('문제가 발생') ? Colors.red : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action:
            statusMessage.contains('문제가 발생')
                ? SnackBarAction(
                  label: '새로고침',
                  onPressed: () {
                    final notifier = ref.read(
                      groupDetailNotifierProvider.notifier,
                    );
                    notifier.onAction(
                      const GroupDetailAction.refreshSessions(),
                    );
                  },
                )
                : null,
      ),
    );
  }

  // 🔥 Root 역할: context 기반 작업 (알림 권한)
  Future<void> _requestNotificationPermission() async {
    final notificationService = NotificationService();
    final hasPermission = await notificationService.requestPermission();

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
  }

  // 🔥 Root 역할: context 기반 작업 (메시지 표시)
  void _showAppResumedMessage() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final currentState = ref.read(groupDetailNotifierProvider);
        if (currentState.timerStatus == TimerStatus.stop) {
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

  // 🔥 Root 역할: context 기반 작업 (경고창)
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

  // 🔥 Root 역할: context 기반 작업 (네비게이션 처리)
  Future<void> _handleNavigation(Function() navigationAction) async {
    if (!mounted) return;

    final state = ref.read(groupDetailNotifierProvider);
    final notifier = ref.read(groupDetailNotifierProvider.notifier);

    if (state.timerStatus == TimerStatus.running) {
      final shouldNavigate = await _showNavigationWarningDialog(context);

      if (shouldNavigate && mounted) {
        await notifier.onAction(const GroupDetailAction.stopTimer());

        // 🔧 네비게이션 전 화면 비활성 상태 알림
        notifier.setScreenActive(false);

        navigationAction();
      }
    } else {
      // 🔧 네비게이션 전 화면 비활성 상태 알림
      notifier.setScreenActive(false);
      navigationAction();
    }
  }

  // 🔥 Root 역할: 화면 복귀 처리
  void _handleScreenReturn() {
    if (mounted && _isInitialized && !_isInitializing) {
      print('🔄 다른 화면에서 돌아옴 - 데이터 갱신');

      // 🔧 화면 활성 상태 복원
      final notifier = ref.read(groupDetailNotifierProvider.notifier);
      notifier.setScreenActive(true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.onScreenReenter();
        }
      });
    }
  }

  // 🔥 Root 역할: AsyncValue 상태 검사 메서드들
  bool _isCurrentlyLoading(GroupDetailState state) {
    final isGroupLoading = state.groupDetailResult is AsyncLoading;
    final isMembersLoading = state.groupMembersResult is AsyncLoading;
    return isGroupLoading || isMembersLoading;
  }

  bool _hasError(GroupDetailState state) {
    return state.groupDetailResult is AsyncError;
  }

  Object? _getErrorObject(GroupDetailState state) {
    return switch (state.groupDetailResult) {
      AsyncError(:final error) => error,
      _ => null,
    };
  }

  Group? _getGroupData(GroupDetailState state) {
    return switch (state.groupDetailResult) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Root 역할: 상태 구독
    final state = ref.watch(groupDetailNotifierProvider);
    final notifier = ref.read(groupDetailNotifierProvider.notifier);

    // 🔧 새로 추가: 상태 메시지 처리
    final statusMessage = state.statusMessage;
    if (statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleStatusMessage(statusMessage);
        }
      });
    }

    // 🔥 Root 역할: AsyncValue 상태 분기 처리
    final isLoading = _isCurrentlyLoading(state);
    final hasError = _hasError(state);
    final group = _getGroupData(state);

    // 🔥 Root 역할: 에러 화면 렌더링
    if (hasError) {
      final error = _getErrorObject(state);
      return Scaffold(
        appBar: AppBar(title: const Text('그룹 정보')),
        body: ErrorView(
          error: error,
          onRetry:
              () =>
                  notifier.onAction(const GroupDetailAction.refreshSessions()),
        ),
      );
    }

    // 🔥 Root 역할: 로딩 화면 렌더링
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('그룹 정보 불러오는 중...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 🔥 Root 역할: 데이터 없음 화면 렌더링
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('그룹 정보')),
        body: ErrorView(
          error: '그룹 정보를 불러올 수 없습니다.',
          onRetry:
              () =>
                  notifier.onAction(const GroupDetailAction.refreshSessions()),
        ),
      );
    }

    // 🔥 Root 역할: PopScope 처리
    return PopScope(
      canPop: state.timerStatus != TimerStatus.running,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // 🔧 실제로 pop이 발생했을 때 화면 비활성 상태 알림
          notifier.setScreenActive(false);
        } else {
          // pop이 취소되었을 때 - 타이머 실행 중이어서 경고창 표시
          _showNavigationWarningDialog(context).then((shouldPop) {
            if (shouldPop && mounted) {
              notifier.onAction(const GroupDetailAction.stopTimer()).then((_) {
                if (mounted) {
                  // 🔧 pop 전 화면 비활성 상태 알림
                  notifier.setScreenActive(false);
                  Navigator.of(context).pop();
                }
              });
            }
          });
        }
      },
      child: Stack(
        children: [
          // 🔧 메인 컨텐츠
          GroupDetailScreen(
            state: state,
            onAction: (action) async {
              if (!mounted) return;

              // 🔥 Root 역할: 네비게이션 액션 처리
              switch (action) {
                case NavigateToAttendance():
                  await _handleNavigation(() async {
                    await context.push('/group/${widget.groupId}/attendance');
                    _handleScreenReturn();
                  });

                case NavigateToSettings():
                  await _handleNavigation(() async {
                    await context.push('/group/${widget.groupId}/settings');
                    _handleScreenReturn();
                  });

                case NavigateToUserProfile(:final userId):
                  await _handleNavigation(() async {
                    await context.push('/user/$userId/profile');
                    _handleScreenReturn();
                  });

                case NavigateToMap():
                  await _handleNavigation(() async {
                    await context.push('/group/${widget.groupId}/map');
                    _handleScreenReturn();
                  });

                case NavigateToChat():
                  await _handleNavigation(() async {
                    await context.push('/group/${widget.groupId}/chat');
                    _handleScreenReturn();
                  });

                default:
                  // 🔥 Root 역할: 기타 액션은 Notifier에 위임
                  if (mounted) {
                    await notifier.onAction(action);
                  }
              }
            },
          ),

          // 🔧 새로 추가: 스트림 연결 상태 표시 (상단 인디케이터)
          if (state.streamConnectionStatus == StreamConnectionStatus.connecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
