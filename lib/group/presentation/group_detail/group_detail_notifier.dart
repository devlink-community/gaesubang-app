// lib/group/presentation/group_detail/group_detail_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_members_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/pause_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/start_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/stop_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/stream_group_member_timer_status_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_detail_notifier.g.dart';

@riverpod
class GroupDetailNotifier extends _$GroupDetailNotifier {
  Timer? _timer;
  StreamSubscription? _timerStatusSubscription;

  // 🔧 재연결 관리
  Timer? _reconnectionTimer;
  Timer? _healthCheckTimer;

  // 🔧 알림 서비스
  final NotificationService _notificationService = NotificationService();

  // UseCase 의존성들
  StartTimerUseCase? _startTimerUseCase;
  StopTimerUseCase? _stopTimerUseCase;
  PauseTimerUseCase? _pauseTimerUseCase;
  GetGroupDetailUseCase? _getGroupDetailUseCase;
  GetGroupMembersUseCase? _getGroupMembersUseCase;
  StreamGroupMemberTimerStatusUseCase? _streamGroupMemberTimerStatusUseCase;

  String _groupId = '';
  String _groupName = ''; // 🔧 알림용 그룹명 저장
  String? _currentUserId;
  DateTime? _localTimerStartTime;
  bool mounted = true;

  @override
  GroupDetailState build() {
    print('🏗️ GroupDetailNotifier build() 호출');
    mounted = true;

    if (_startTimerUseCase == null) {
      _startTimerUseCase = ref.watch(startTimerUseCaseProvider);
      _stopTimerUseCase = ref.watch(stopTimerUseCaseProvider);
      _pauseTimerUseCase = ref.watch(pauseTimerUseCaseProvider);
      _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider);
      _getGroupMembersUseCase = ref.watch(getGroupMembersUseCaseProvider);
      _streamGroupMemberTimerStatusUseCase = ref.watch(
        streamGroupMemberTimerStatusUseCaseProvider,
      );

      print('🔧 UseCase 의존성 주입 완료');
    }

    final currentUser = ref.watch(currentUserProvider);
    _currentUserId = currentUser?.uid;

    ref.onDispose(() {
      print('🗑️ GroupDetailNotifier dispose - 모든 리소스 정리');
      _cleanupAllTimers();
      mounted = false;
    });

    return const GroupDetailState();
  }

  // 🔧 모든 타이머 정리
  void _cleanupAllTimers() {
    _timer?.cancel();
    _timer = null;

    _timerStatusSubscription?.cancel();
    _timerStatusSubscription = null;

    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  // 🔧 화면 활성 상태 관리
  void setScreenActive(bool isActive) {
    if (state.isScreenActive == isActive) return;

    print('📱 화면 활성 상태 변경: ${state.isScreenActive} -> $isActive');

    state = state.copyWith(isScreenActive: isActive);

    if (_groupId.isNotEmpty) {
      _updateStreamSubscription();
    }
  }

  // 🔧 앱 포그라운드 상태 관리
  void setAppForeground(bool isForeground) {
    if (state.isAppInForeground == isForeground) return;

    print('🌅 앱 포그라운드 상태 변경: ${state.isAppInForeground} -> $isForeground');

    state = state.copyWith(isAppInForeground: isForeground);

    if (_groupId.isNotEmpty) {
      _updateStreamSubscription();
    }
  }

  // 🔧 백그라운드 진입 시 타이머 강제 종료 (앱 종료 대응 포함)
  Future<void> handleBackgroundTransition() async {
    if (state.timerStatus != TimerStatus.running) return;

    print('📱 백그라운드 진입 - 타이머 즉시 종료');

    final currentElapsedSeconds = state.elapsedSeconds;

    // 🔧 1. 즉시 로컬 상태 완전 정리 (동기 처리)
    _timer?.cancel();
    _localTimerStartTime = null;
    state = state.copyWith(
      timerStatus: TimerStatus.stop,
      elapsedSeconds: 0,
    );
    _updateCurrentUserInMemberList(isActive: false);

    // 🔧 2. 즉시 알림 발송 (await 없이 시작)
    _notificationService.showTimerEndedNotification(
      groupName: _groupName,
      elapsedSeconds: currentElapsedSeconds,
      titlePrefix: '[타이머 강제 종료] ',
    );

    // 🔧 3. API 호출은 Fire-and-forget 방식 (앱 종료되어도 상관없음)
    _stopTimerWithRetry().catchError((e) {
      print('🔧 백그라운드 API 호출 실패 (무시): $e');
    });

    print('✅ 백그라운드 타이머 종료 처리 완료');
  }

  // 🔧 스트림 구독 상태 업데이트
  void _updateStreamSubscription() {
    final shouldBeActive = state.isActive && mounted;
    final isCurrentlyActive = _timerStatusSubscription != null;

    print(
      '🔄 스트림 구독 상태 확인: shouldBeActive=$shouldBeActive, isCurrentlyActive=$isCurrentlyActive',
    );

    if (shouldBeActive && !isCurrentlyActive) {
      _startRealTimeTimerStatusStream();
    } else if (!shouldBeActive && isCurrentlyActive) {
      _stopRealTimeTimerStatusStream();
    }
  }

  // 🔧 실시간 스트림 정지
  void _stopRealTimeTimerStatusStream() {
    print('🔴 실시간 타이머 상태 스트림 정지');

    _timerStatusSubscription?.cancel();
    _timerStatusSubscription = null;

    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    state = state.copyWith(
      streamConnectionStatus: StreamConnectionStatus.disconnected,
      reconnectionAttempts: 0,
    );
  }

  // 화면 재진입 시 데이터 갱신
  Future<void> onScreenReenter() async {
    if (_groupId.isEmpty) {
      print('⚠️ 그룹 ID가 설정되지 않아 데이터 갱신을 건너뜁니다');
      return;
    }

    print('🔄 화면 재진입 감지 - 상태 복원 및 데이터 새로고침');

    setScreenActive(true);

    state = state.copyWith(
      errorMessage: null,
      reconnectionAttempts: 0,
    );

    await refreshAllData();
  }

  // 액션 처리
  Future<void> onAction(GroupDetailAction action) async {
    switch (action) {
      case StartTimer():
        await _handleStartTimer();

      case PauseTimer():
        await _handlePauseTimer();

      case ResumeTimer():
        _handleResumeTimer();

      case StopTimer():
        await _handleStopTimer();

      case ResetTimer():
        await _handleResetTimer();

      case SetGroupId(:final groupId):
        await _handleSetGroupId(groupId);

      case RefreshSessions():
        await refreshAllData();

      case TimerTick():
        _handleTimerTick();

      case ToggleTimer():
        if (state.timerStatus == TimerStatus.running) {
          await _handlePauseTimer();
        } else if (state.timerStatus == TimerStatus.paused ||
            state.timerStatus == TimerStatus.stop) {
          if (state.timerStatus == TimerStatus.stop) {
            await _handleStartTimer();
          } else {
            _handleResumeTimer();
          }
        }
        break;

      // 네비게이션 액션들 - Root에서 처리
      case NavigateToAttendance():
      case NavigateToMap():
      case NavigateToSettings():
      case NavigateToUserProfile():
      case NavigateToChat():
        break;

      case SetGroupInfo():
        break;
    }
  }

  // 🔧 타이머 시작 처리
  Future<void> _handleStartTimer() async {
    if (state.timerStatus == TimerStatus.running) return;

    _localTimerStartTime = DateTime.now();

    state = state.copyWith(
      timerStatus: TimerStatus.running,
      errorMessage: null,
      elapsedSeconds: 0,
    );

    _updateCurrentUserInMemberList(
      isActive: true,
      timerStartTime: _localTimerStartTime,
    );

    // API 호출 (실패해도 로컬 상태는 유지)
    try {
      await _startTimerUseCase?.execute(_groupId);
    } catch (e) {
      print('⚠️ StartTimer API 호출 실패: $e');
      // 로컬 상태는 그대로 유지 (사용자 경험 우선)
    }

    _startTimerCountdown();
  }

  // 🔧 타이머 일시정지 처리
  Future<void> _handlePauseTimer() async {
    if (state.timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.paused);

    _updateCurrentUserInMemberList(isActive: false);

    // API 호출 (실패해도 로컬 상태는 유지)
    try {
      await _pauseTimerUseCase?.execute(_groupId);
    } catch (e) {
      print('⚠️ PauseTimer API 호출 실패: $e');
    }
  }

  // 🔧 타이머 재개 처리
  void _handleResumeTimer() {
    if (state.timerStatus != TimerStatus.paused) return;

    _localTimerStartTime = DateTime.now();
    state = state.copyWith(timerStatus: TimerStatus.running);

    _updateCurrentUserInMemberList(
      isActive: true,
      timerStartTime: _localTimerStartTime,
    );

    _startTimerCountdown();
  }

  // 🔧 타이머 정지 처리 (재시도 포함)
  Future<void> _handleStopTimer() async {
    if (state.timerStatus == TimerStatus.stop) return;

    print('⏹️ 타이머 정지 처리 시작');

    // 1. 즉시 로컬 상태 변경 (중복 호출 방지)
    _timer?.cancel();
    _localTimerStartTime = null;

    state = state.copyWith(
      timerStatus: TimerStatus.stop,
      elapsedSeconds: 0, // 완전 초기화
    );

    _updateCurrentUserInMemberList(isActive: false);

    // 2. API 호출 (재시도 포함)
    await _stopTimerWithRetry();
  }

  // 🔧 StopTimer API 재시도 로직
  Future<void> _stopTimerWithRetry({int attempt = 0}) async {
    try {
      await _stopTimerUseCase?.execute(_groupId);
      print('✅ StopTimer API 호출 성공');
    } catch (e) {
      if (attempt < 2) {
        // 최대 2회 재시도
        print('🔄 StopTimer 재시도 ${attempt + 1}/3');
        await Future.delayed(Duration(seconds: attempt + 1));
        return _stopTimerWithRetry(attempt: attempt + 1);
      }
      print('❌ StopTimer 최종 실패: $e');
      // 로컬 상태는 이미 변경되었으므로 그대로 유지
    }
  }

  // 🔧 타이머 리셋 처리
  Future<void> _handleResetTimer() async {
    _timer?.cancel();
    _localTimerStartTime = null;

    state = state.copyWith(timerStatus: TimerStatus.stop, elapsedSeconds: 0);
    _updateCurrentUserInMemberList(isActive: false);
  }

  // 그룹 ID 설정
  Future<void> _handleSetGroupId(String groupId) async {
    print('📊 Setting group ID in notifier: $groupId');
    _groupId = groupId;
    await _loadInitialData();
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    if (_groupId.isEmpty) return;

    print('🔄 초기 데이터 로드 시작 - groupId: $_groupId');

    try {
      await Future.wait([
        _loadGroupDetail(),
        _loadInitialGroupMembers(),
      ], eagerError: false);

      _updateStreamSubscription();

      print('✅ 초기 데이터 로드 완료');
    } catch (e, s) {
      print('❌ _loadInitialData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 최초 멤버 정보 로드
  Future<void> _loadInitialGroupMembers() async {
    print('📥 최초 멤버 정보 로드 시작');

    state = state.copyWith(groupMembersResult: const AsyncValue.loading());

    try {
      final result = await _getGroupMembersUseCase?.execute(_groupId);
      if (result != null) {
        state = state.copyWith(groupMembersResult: result);
        print('✅ 최초 멤버 정보 로드 완료');
      }
    } catch (e) {
      print('❌ 최초 멤버 정보 로드 실패: $e');
      state = state.copyWith(
        groupMembersResult: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  // 🔧 실시간 스트림 시작
  void _startRealTimeTimerStatusStream() {
    if (_timerStatusSubscription != null) {
      print('⚠️ 이미 활성화된 스트림이 있어서 시작을 건너뜁니다');
      return;
    }

    print('🔴 실시간 타이머 상태 스트림 시작');

    state = state.copyWith(
      streamConnectionStatus: StreamConnectionStatus.connecting,
      errorMessage: null,
    );

    _timerStatusSubscription = _streamGroupMemberTimerStatusUseCase
        ?.execute(_groupId)
        .listen(
          (asyncValue) {
            if (!mounted || !state.isActive) {
              print('🔇 화면 비활성 상태로 스트림 데이터 무시');
              return;
            }

            _handleStreamData(asyncValue);
          },
          onError: (error) {
            print('❌ 실시간 스트림 구독 에러: $error');
            _handleStreamError(error);
          },
          onDone: () {
            print('✅ 실시간 스트림 완료');
            _timerStatusSubscription = null;
            state = state.copyWith(
              streamConnectionStatus: StreamConnectionStatus.disconnected,
            );
          },
        );

    _startStreamHealthCheck();
  }

  // 🔧 스트림 헬스 체크
  void _startStreamHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) {
        if (!mounted || !state.isActive) return;

        final isHealthy = state.isStreamHealthy;
        print('💓 스트림 헬스 체크: ${isHealthy ? '정상' : '비정상'}');

        if (!isHealthy &&
            state.streamConnectionStatus == StreamConnectionStatus.connected) {
          state = state.copyWith(
            errorMessage: '실시간 업데이트가 지연되고 있습니다.',
          );
        }
      },
    );
  }

  // 🔧 스트림 데이터 처리
  void _handleStreamData(AsyncValue<List<GroupMember>> asyncValue) {
    print('🔄 실시간 타이머 상태 업데이트 수신: ${asyncValue.runtimeType}');

    switch (asyncValue) {
      case AsyncData(:final value):
        final mergedMembers = _mergeLocalTimerStateWithRemoteData(value);

        state = state.copyWith(
          groupMembersResult: AsyncData(mergedMembers),
          streamConnectionStatus: StreamConnectionStatus.connected,
          lastStreamUpdateTime: DateTime.now(),
          errorMessage: null,
          reconnectionAttempts: 0,
        );

        print('✅ 실시간 멤버 상태 업데이트 완료 (${mergedMembers.length}명)');

      case AsyncError(:final error):
        print('⚠️ 실시간 스트림 데이터 에러: $error');
        _handleStreamError(error);

      case AsyncLoading():
        print('🔄 실시간 스트림 로딩 중');
    }
  }

  // 🔧 스트림 에러 처리
  void _handleStreamError(Object error) {
    if (!mounted || !state.isActive) {
      print('🔇 화면 비활성 상태로 에러 처리 건너뜀');
      return;
    }

    state = state.copyWith(
      streamConnectionStatus: StreamConnectionStatus.failed,
      errorMessage: '실시간 업데이트 연결에 문제가 발생했습니다.',
    );

    if (state.shouldAttemptReconnection) {
      _scheduleReconnection();
    }
  }

  // 🔧 재연결 스케줄링
  void _scheduleReconnection() {
    final currentAttempts = state.reconnectionAttempts;
    final newAttempts = currentAttempts + 1;

    print('🔄 재연결 스케줄링: $newAttempts/3');

    state = state.copyWith(
      reconnectionAttempts: newAttempts,
      streamConnectionStatus: StreamConnectionStatus.disconnected,
    );

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(
      Duration(seconds: 2 * newAttempts),
      () {
        if (!mounted || !state.isActive) return;

        print('🔄 재연결 시도 실행: $newAttempts/3');

        _timerStatusSubscription?.cancel();
        _timerStatusSubscription = null;

        _startRealTimeTimerStatusStream();
      },
    );
  }

  // 현재 사용자 멤버 리스트 업데이트
  void _updateCurrentUserInMemberList({
    required bool isActive,
    DateTime? timerStartTime,
  }) {
    if (_currentUserId == null) {
      print('⚠️ 현재 사용자 ID가 없어서 멤버 리스트 업데이트를 건너뜁니다');
      return;
    }

    final currentMembersResult = state.groupMembersResult;
    if (currentMembersResult is! AsyncData<List<GroupMember>>) {
      print('⚠️ 멤버 리스트가 AsyncData 상태가 아니어서 업데이트를 건너뜁니다');
      return;
    }

    final currentMembers = currentMembersResult.value;
    if (currentMembers.isEmpty) {
      print('⚠️ 멤버 리스트가 비어있어서 업데이트를 건너뜁니다');
      return;
    }

    final int elapsedSeconds =
        isActive && timerStartTime != null
            ? DateTime.now().difference(timerStartTime).inSeconds
            : 0;

    final updatedMembers =
        currentMembers.map((member) {
          if (member.userId == _currentUserId) {
            return member.copyWith(
              isActive: isActive,
              timerStartTime: timerStartTime,
              elapsedSeconds: elapsedSeconds,
              elapsedMinutes: (elapsedSeconds / 60).floor(),
            );
          }
          return member;
        }).toList();

    state = state.copyWith(
      groupMembersResult: AsyncData(updatedMembers),
    );

    print(
      '🔧 현재 사용자 멤버 상태 즉시 업데이트: isActive=$isActive, elapsedSeconds=$elapsedSeconds',
    );
  }

  // 로컬 타이머 상태와 원격 데이터 병합
  List<GroupMember> _mergeLocalTimerStateWithRemoteData(
    List<GroupMember> remoteMembers,
  ) {
    if (_currentUserId == null) return remoteMembers;

    final isLocalTimerActive = state.timerStatus == TimerStatus.running;
    final localStartTime = _localTimerStartTime;

    return remoteMembers.map((member) {
      if (member.userId == _currentUserId) {
        final serverIsActive = member.isActive;
        final serverStartTime = member.timerStartTime;

        if (_shouldValidateTimerState(
          serverIsActive,
          serverStartTime,
          isLocalTimerActive,
          localStartTime,
        )) {
          print('🔧 타이머 상태 불일치 감지 - 서버 상태로 동기화');

          if (!serverIsActive && isLocalTimerActive) {
            print('🔧 서버에서 타이머가 중지된 것을 감지 - 로컬 타이머 중지');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleStopTimer();
              }
            });
          } else if (serverIsActive &&
              !isLocalTimerActive &&
              serverStartTime != null) {
            print('🔧 서버에서 타이머가 시작된 것을 감지 - 로컬 타이머 동기화');
            _localTimerStartTime = serverStartTime;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                state = state.copyWith(timerStatus: TimerStatus.running);
                _startTimerCountdown();
              }
            });
          }
        }

        final elapsedSeconds =
            isLocalTimerActive && localStartTime != null
                ? DateTime.now().difference(localStartTime).inSeconds
                : (serverIsActive && serverStartTime != null
                    ? DateTime.now().difference(serverStartTime).inSeconds
                    : 0);

        return member.copyWith(
          isActive: isLocalTimerActive,
          timerStartTime: localStartTime ?? serverStartTime,
          elapsedSeconds: elapsedSeconds,
          elapsedMinutes: (elapsedSeconds / 60).floor(),
        );
      } else {
        final elapsedSeconds =
            member.isActive && member.timerStartTime != null
                ? DateTime.now().difference(member.timerStartTime!).inSeconds
                : member.elapsedSeconds;

        return member.copyWith(
          elapsedSeconds: elapsedSeconds,
          elapsedMinutes: (elapsedSeconds / 60).floor(),
        );
      }
    }).toList();
  }

  // 타이머 상태 검증 필요 여부 확인
  bool _shouldValidateTimerState(
    bool serverIsActive,
    DateTime? serverStartTime,
    bool localIsActive,
    DateTime? localStartTime,
  ) {
    if (serverIsActive != localIsActive) {
      return true;
    }

    if (serverIsActive &&
        localIsActive &&
        serverStartTime != null &&
        localStartTime != null) {
      final timeDifference = (serverStartTime.difference(localStartTime)).abs();
      if (timeDifference.inSeconds > 5) {
        print('🔧 타이머 시작 시간 차이 감지: ${timeDifference.inSeconds}초');
        return true;
      }
    }

    if (serverIsActive && serverStartTime != null && localStartTime == null) {
      return true;
    }

    return false;
  }

  // 타이머 카운트다운 시작
  void _startTimerCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onAction(const GroupDetailAction.timerTick()),
    );
  }

  // 타이머 틱 처리
  void _handleTimerTick() {
    if (state.timerStatus != TimerStatus.running) return;

    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);

    if (_localTimerStartTime != null) {
      _updateCurrentUserInMemberList(
        isActive: true,
        timerStartTime: _localTimerStartTime,
      );
    }
  }

  // 모든 데이터 새로고침
  Future<void> refreshAllData() async {
    if (_groupId.isEmpty) return;

    print('🔄 데이터 새로고침 시작 - groupId: $_groupId');

    try {
      await _loadGroupDetail();
      _updateStreamSubscription();
      print('✅ 데이터 새로고침 완료');
    } catch (e, s) {
      print('❌ refreshAllData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 그룹 상세 정보 로드
  Future<void> _loadGroupDetail() async {
    state = state.copyWith(groupDetailResult: const AsyncValue.loading());
    final result = await _getGroupDetailUseCase?.execute(_groupId);
    if (result != null) {
      state = state.copyWith(groupDetailResult: result);

      // 🔧 그룹명 저장 (알림용)
      if (result is AsyncData && result.value != null) {
        _groupName = result.value!.name;
      }
    }
  }
}
