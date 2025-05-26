// lib/group/presentation/group_detail/group_detail_screen_root.dart
import 'package:devlink_mobile_app/core/component/custom_alert_dialog.dart';
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
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
  bool _isDisposing = false; // 🔧 dispose 상태 추가

  // 🔧 상태 메시지 표시 관리
  String? _lastShownStatusMessage;
  DateTime? _lastStatusMessageTime;

  @override
  void initState() {
    super.initState();

    AppLogger.debug(
      'GroupDetailScreenRoot initState - groupId: ${widget.groupId}',
      tag: 'GroupDetailRoot',
    );

    WidgetsBinding.instance.addObserver(this);
    _isInitializing = true;

    // Future.microtask를 사용하여 안전한 초기화
    Future.microtask(() {
      if (mounted && !_isDisposing) {
        _initializeScreen();
      }
    });
  }

  @override
  void dispose() {
    // 🔧 dispose 시작 플래그 설정
    _isDisposing = true;

    AppLogger.debug('화면 dispose 시작', tag: 'GroupDetailRoot');

    // 🔧 안전한 notifier 정리
    _safeNotifierCleanup();

    // 🔧 생명주기 observer 제거
    WidgetsBinding.instance.removeObserver(this);

    AppLogger.debug('화면 dispose 완료', tag: 'GroupDetailRoot');

    // 🔧 부모 dispose 호출
    super.dispose();
  }

  /// 🔧 안전한 notifier 정리 메서드
  void _safeNotifierCleanup() {
    if (!_isInitialized || _isDisposing) {
      AppLogger.debug(
        'Notifier 정리 건너뛰기: 초기화되지 않았거나 이미 dispose 중',
        tag: 'GroupDetailRoot',
      );
      return;
    }

    try {
      // 🔧 mounted 상태 다시 확인
      if (mounted) {
        final notifier = ref.read(groupDetailNotifierProvider.notifier);

        // 🔧 비동기 정리를 동기로 변경하여 즉시 처리
        notifier.setScreenActive(false);

        AppLogger.debug('Notifier 정리 완료', tag: 'GroupDetailRoot');
      }
    } catch (e) {
      // 🔧 dispose 중 ref 접근 실패는 정상적인 경우
      AppLogger.debug(
        'Notifier 정리 중 예상된 에러 (정상): ${e.runtimeType}',
        tag: 'GroupDetailRoot',
      );
    }
  }

  /// 🔧 생명주기 상태 변경 처리 - dispose 상태 체크 추가
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 🔧 dispose 중이면 생명주기 이벤트 무시
    if (_isDisposing || !mounted) {
      return;
    }

    if (_isInitializing) {
      AppLogger.debug('초기화 중이므로 생명주기 이벤트 무시: $state', tag: 'GroupDetailRoot');
      return;
    }

    // 🔧 안전한 notifier 접근
    _safeLifecycleNotifierAccess(state);
  }

  /// 🔧 안전한 생명주기 notifier 접근
  void _safeLifecycleNotifierAccess(AppLifecycleState state) {
    try {
      if (!mounted || _isDisposing) return;

      final notifier = ref.read(groupDetailNotifierProvider.notifier);

      switch (state) {
        case AppLifecycleState.paused:
          if (_isInitialized && !_isInitializing && !_wasInBackground) {
            AppLogger.info('앱이 백그라운드로 전환됨', tag: 'GroupDetailRoot');
            _wasInBackground = true;
            notifier.setAppForeground(false);
            if (mounted && !_isDisposing) {
              notifier.handleBackgroundTransition();
            }
          }
          break;

        case AppLifecycleState.resumed:
          if (_wasInBackground &&
              mounted &&
              _isInitialized &&
              !_isInitializing &&
              !_isDisposing) {
            AppLogger.info('백그라운드에서 앱 재개 - 데이터 갱신', tag: 'GroupDetailRoot');
            notifier.setAppForeground(true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposing) {
                notifier.onScreenReenter();
                _showAppResumedMessage();
              }
            });
          }
          _wasInBackground = false;
          break;

        // 기타 생명주기 상태들...
        default:
          break;
      }
    } catch (e) {
      AppLogger.debug(
        '생명주기 처리 중 notifier 접근 실패: ${e.runtimeType}',
        tag: 'GroupDetailRoot',
      );
    }
  }

  /// 🔧 안전한 화면 초기화
  Future<void> _initializeScreen() async {
    // 중복 초기화 방지
    if (_isInitialized || _isDisposing) return;

    AppLogger.info(
      '화면 초기화 시작 - groupId: ${widget.groupId}',
      tag: 'GroupDetailRoot',
    );

    try {
      // 🔧 mounted 상태 확인
      if (!mounted || _isDisposing) return;

      final notifier = ref.read(groupDetailNotifierProvider.notifier);

      // 1. 먼저 화면 활성 상태 설정
      notifier.setScreenActive(true);
      notifier.setAppForeground(true);

      // 2. 약간의 지연을 주어 Widget 트리가 안정화되도록 함
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. 그룹 ID 설정 및 데이터 로드
      if (mounted && !_isDisposing) {
        await notifier.onAction(GroupDetailAction.setGroupId(widget.groupId));

        // 4. 알림 권한 요청
        await _requestNotificationPermission();
      }

      _isInitialized = true;
      _isInitializing = false;
      AppLogger.info('화면 초기화 완료', tag: 'GroupDetailRoot');
    } catch (e) {
      AppLogger.error('화면 초기화 실패', tag: 'GroupDetailRoot', error: e);
      _isInitializing = false;
    }
  }

  // 🔧 상태 메시지 처리
  void _handleStatusMessage(String? statusMessage) {
    if (statusMessage == null || statusMessage.isEmpty) return;

    // 🔧 같은 메시지를 짧은 시간 내에 중복 표시하지 않음
    if (_lastShownStatusMessage == statusMessage &&
        _lastStatusMessageTime != null &&
        TimeFormatter.nowInSeoul()
                .difference(_lastStatusMessageTime!)
                .inSeconds <
            5) {
      return;
    }

    _lastShownStatusMessage = statusMessage;
    _lastStatusMessageTime = TimeFormatter.nowInSeoul();

    AppLogger.info('상태 메시지 표시: $statusMessage', tag: 'GroupDetailRoot');

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

  // 🔥 Root 역할: context 기반 작업 (앱 재개 메시지)
  void _showAppResumedMessage() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final currentState = ref.read(groupDetailNotifierProvider);
        // 🔧 실제로 타이머가 실행 중이었고 백그라운드에서 종료된 경우만 메시지 표시
        if (currentState.timerStatus == TimerStatus.stop &&
            currentState.elapsedSeconds == 0) {
          // 현재 stop 상태이고 경과시간이 0이면 백그라운드에서 강제 종료된 것으로 추정
          // 하지만 이것만으로는 정확한 판단이 어려움
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('앱이 백그라운드에 있는 동안 타이머가 종료되었습니다.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  // 🔥 Root 역할: context 기반 작업 (네비게이션 경고창)
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
        // 🔧 경고창에서 확인 시 타이머 종료
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
      AppLogger.info('다른 화면에서 돌아옴 - 데이터 갱신', tag: 'GroupDetailRoot');

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

    // 🔧 상태 메시지 처리
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

    // 🔥 Root 역할: PopScope 처리 (타이머 실행 중 뒤로가기 방지)
    return PopScope(
      canPop: state.timerStatus != TimerStatus.running,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // 🔧 실제로 pop이 발생했을 때 화면 비활성 상태 알림
          notifier.setScreenActive(false);
        } else {
          // 🔧 pop이 취소되었을 때 - 타이머 실행 중이어서 경고창 표시
          _showNavigationWarningDialog(context).then((shouldPop) {
            if (shouldPop && mounted) {
              // 🔧 사용자가 이동을 확인했을 때만 타이머 종료 후 pop
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

          // 🔧 스트림 연결 상태 표시 (상단 인디케이터)
          if (state.streamConnectionStatus == StreamConnectionStatus.connecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
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
