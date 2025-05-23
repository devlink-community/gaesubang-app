// lib/group/presentation/group_detail/group_detail_notifier.dart
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_members_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/record_timer_activity_use_case.dart';
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
  RecordTimerActivityUseCase?
  _recordTimerActivityUseCase; // UseCase 의존성을 하나로 통합
  GetGroupDetailUseCase? _getGroupDetailUseCase;
  GetGroupMembersUseCase? _getGroupMembersUseCase;
  StreamGroupMemberTimerStatusUseCase? _streamGroupMemberTimerStatusUseCase;

  String _groupId = '';
  String _groupName = ''; // 🔧 알림용 그룹명 저장
  String? _currentUserId;
  DateTime? _localTimerStartTime;
  bool mounted = true;

  // 🔧 타이머 조건 관련 추가 변수
  Timer? _midnightTimer; // 자정 감지 타이머
  String? _lastProcessedActivityKey; // 중복 처리 방지용
  DateTime? _lastValidatedPauseTime; // 마지막 검증한 일시정지 시간

  @override
  GroupDetailState build() {
    print('🏗️ GroupDetailNotifier build() 호출');
    mounted = true;

    if (_recordTimerActivityUseCase == null) {
      _recordTimerActivityUseCase = ref.watch(
        recordTimerActivityUseCaseProvider,
      );
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
      mounted = false;
      _cleanupAllTimers(); // 메서드 호출로 통합
    });

    return const GroupDetailState();
  }

  // mounted 체크를 포함한 안전한 state 업데이트
  void _safeSetState(GroupDetailState Function() stateBuilder) {
    if (mounted) {
      try {
        state = stateBuilder();
      } catch (e) {
        print('❌ State 업데이트 실패: $e');
      }
    }
  }

  // 🔧 모든 타이머 정리 (수정)
  void _cleanupAllTimers() {
    print('🧹 모든 타이머 및 스트림 정리 시작');

    _timer?.cancel();
    _timer = null;

    // 스트림 정지 (개선된 메서드 호출)
    _stopRealTimeTimerStatusStream();

    _midnightTimer?.cancel();
    _midnightTimer = null;

    print('✅ 모든 타이머 및 스트림 정리 완료');
  }

  // 🔧 화면 활성 상태 관리
  void setScreenActive(bool isActive) {
    if (!mounted) {
      print('⚠️ Notifier가 mounted 상태가 아니어서 setScreenActive 무시');
      return;
    }
    if (state.isScreenActive == isActive) return;

    print('📱 화면 활성 상태 변경: ${state.isScreenActive} -> $isActive');

    try {
      state = state.copyWith(isScreenActive: isActive);

      if (_groupId.isNotEmpty) {
        _updateStreamSubscription();
      }
    } catch (e) {
      print('❌ setScreenActive 에러: $e');
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
    // 1. 먼저 스트림을 null로 설정하여 새 이벤트 차단
    final subscription = _timerStatusSubscription;
    _timerStatusSubscription = null;

    // 2. 타이머들 취소
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    // 3. 상태 업데이트 (mounted 체크)
    if (mounted) {
      state = state.copyWith(
        streamConnectionStatus: StreamConnectionStatus.disconnected,
        reconnectionAttempts: 0,
      );
    }

    // 4. 마지막에 스트림 구독 취소
    subscription?.cancel();
    print('✅ 스트림 구독 취소 완료');
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
        await _handleResumeTimer();

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
            await _handleResumeTimer();
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
      await _recordTimerActivityUseCase?.start(_groupId);
    } catch (e) {
      print('⚠️ StartTimer API 호출 실패: $e');
      // 로컬 상태는 그대로 유지 (사용자 경험 우선)
    }

    _startTimerCountdown();
    _startMidnightDetection(); // 추가: 자정 감지 시작
  }

  // 🔧 타이머 일시정지 처리
  Future<void> _handlePauseTimer() async {
    if (state.timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.paused);

    _updateCurrentUserInMemberList(isActive: false);

    // API 호출 (실패해도 로컬 상태는 유지)
    try {
      await _recordTimerActivityUseCase?.pause(_groupId);
    } catch (e) {
      print('⚠️ PauseTimer API 호출 실패: $e');
    }
  }

  // 🔧 타이머 재개 처리 (수정)
  Future<void> _handleResumeTimer() async {
    if (state.timerStatus != TimerStatus.paused) return;

    // 기존 elapsedSeconds 유지한 채로 resume
    state = state.copyWith(timerStatus: TimerStatus.running);

    // 새로운 세션 시작 시간은 현재로 설정하되
    // elapsedSeconds는 그대로 유지
    _localTimerStartTime = DateTime.now();

    // 서버 상태 업데이트
    _updateCurrentUserInMemberList(
      isActive: true,
      timerStartTime: _localTimerStartTime,
    );

    try {
      await _recordTimerActivityUseCase?.resume(_groupId);
    } catch (e) {
      print('⚠️ ResumeTimer API 호출 실패: $e');
    }

    _startTimerCountdown();
    _startMidnightDetection();
  }

  // 🔧 타이머 정지 처리 (재시도 포함)
  Future<void> _handleStopTimer() async {
    if (state.timerStatus == TimerStatus.stop) return;

    print('⏹️ 타이머 정지 처리 시작');

    // 1. 즉시 로컬 상태 변경 (중복 호출 방지)
    _timer?.cancel();
    _midnightTimer?.cancel(); // 추가: 자정 타이머 취소
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
      await _recordTimerActivityUseCase?.stop(_groupId);
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
    _midnightTimer?.cancel(); // 추가: 자정 타이머 취소
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

    if (!mounted) {
      print('⚠️ Notifier가 mounted 상태가 아니어서 로드 취소');
      return;
    }
    // Loading 상태 설정 전 체크
    if (mounted) {
      state = state.copyWith(groupMembersResult: const AsyncValue.loading());
    }

    try {
      final result = await _getGroupMembersUseCase?.execute(_groupId);

      // 비동기 작업 후 mounted 체크
      if (!mounted) {
        print('🔇 Notifier가 dispose되어 결과 무시');
        return;
      }

      if (result != null) {
        state = state.copyWith(groupMembersResult: result);
        print('✅ 최초 멤버 정보 로드 완료');

        // 추가: 초기 로드 시 타이머 상태 검증
        if (result is AsyncData<List<GroupMember>>) {
          _validateCurrentUserTimerState(result.value);
        }
      }
    } catch (e) {
      print('❌ 최초 멤버 정보 로드 실패: $e');
      state = state.copyWith(
        groupMembersResult: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  // 🔧 실시간 스트림 시작 (더 안전하게 수정)
  void _startRealTimeTimerStatusStream() {
    if (_timerStatusSubscription != null) {
      print('⚠️ 이미 활성화된 스트림이 있어서 시작을 건너뜁니다');
      return;
    }

    // mounted 체크
    if (!mounted) {
      print('⚠️ Notifier가 mounted 상태가 아니어서 스트림 시작을 건너뜁니다');
      return;
    }

    print('🔴 실시간 타이머 상태 스트림 시작');

    state = state.copyWith(
      streamConnectionStatus: StreamConnectionStatus.connecting,
      errorMessage: null,
    );

    // 스트림 구독 전에 한번 더 체크
    if (!mounted || _timerStatusSubscription != null) return;

    _timerStatusSubscription = _streamGroupMemberTimerStatusUseCase
        ?.execute(_groupId)
        .listen(
          (asyncValue) {
            // null 체크 추가
            if (_timerStatusSubscription == null) {
              print('🔇 스트림이 이미 취소되어 데이터 무시');
              return;
            }

            if (!mounted || !state.isActive) {
              print('🔇 화면 비활성 상태로 스트림 데이터 무시');
              return;
            }

            _handleStreamData(asyncValue);
          },
          onError: (error) {
            if (_timerStatusSubscription == null || !mounted || !state.isActive)
              return;

            print('❌ 실시간 스트림 구독 에러: $error');
            _handleStreamError(error);
          },
          onDone: () {
            print('✅ 실시간 스트림 완료');
            if (_timerStatusSubscription != null) {
              _timerStatusSubscription = null;
              if (mounted) {
                state = state.copyWith(
                  streamConnectionStatus: StreamConnectionStatus.disconnected,
                );
              }
            }
          },
          cancelOnError: false,
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
    if (!mounted || !state.isActive || _timerStatusSubscription == null) {
      print('🔇 Notifier가 dispose되어 스트림 데이터 무시');
      return;
    }

    try {
      print('🔄 실시간 타이머 상태 업데이트 수신: ${asyncValue.runtimeType}');

      switch (asyncValue) {
        case AsyncData(:final value):
          // 한번 더 체크
          if (!mounted || _timerStatusSubscription == null) return;

          final mergedMembers = _mergeLocalTimerStateWithRemoteData(value);

          _safeSetState(
            () => state.copyWith(
              groupMembersResult: AsyncData(mergedMembers),
              streamConnectionStatus: StreamConnectionStatus.connected,
              lastStreamUpdateTime: DateTime.now(),
              errorMessage: null,
              reconnectionAttempts: 0,
            ),
          );

          print('✅ 실시간 멤버 상태 업데이트 완료 (${mergedMembers.length}명)');

        case AsyncError(:final error):
          print('⚠️ 실시간 스트림 데이터 에러: $error');
          _handleStreamError(error);

        case AsyncLoading():
          print('🔄 실시간 스트림 로딩 중');
      }
    } catch (e) {
      print('❌ _handleStreamData 예외 발생: $e');
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

    // 단순히 1초씩 증가 (이미 서버에서 받은 초기값부터 시작)
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

  // ===== 타이머 조건 로직 추가 =====

  // 🔧 현재 사용자의 타이머 상태 검증
  void _validateCurrentUserTimerState(List<GroupMember> members) {
    if (_currentUserId == null) return;

    // 빈 리스트 체크
    if (members.isEmpty) {
      print('⚠️ 멤버 리스트가 비어있어 타이머 상태 검증을 건너뜁니다');
      return;
    }

    // 현재 사용자 찾기 (안전하게)
    final currentUserMember = members.firstWhereOrNull(
      (member) => member.userId == _currentUserId,
    );

    // 현재 사용자가 멤버 리스트에 없으면 스킵
    if (currentUserMember == null) {
      print('⚠️ 현재 사용자가 멤버 리스트에 없어 타이머 상태 검증을 건너뜁니다');
      return;
    }

    // 1. 활성 상태인 경우 처리
    if (currentUserMember.isActive &&
        currentUserMember.timerStartTime != null) {
      final elapsedTime = DateTime.now().difference(
        currentUserMember.timerStartTime!,
      );

      // 24시간 이상 경과했으면 비정상으로 판단
      if (elapsedTime.inHours > 24) {
        print('⚠️ 비정상 종료 감지 - 24시간 이상 경과');
        _handleAbnormalTermination(currentUserMember.timerStartTime!);
        return;
      }

      // 정상적인 활성 상태라면 복원
      print('✅ 서버에서 활성 타이머 감지 - 상태 복원');
      _restoreActiveState(currentUserMember);
      return;
    }

    // 2. 비활성 상태(pause)인 경우
    if (!currentUserMember.isActive &&
        currentUserMember.timerStartTime != null) {
      // 이미 검증한 일시정지 시간이면 스킵 (중복 처리 방지)
      if (_lastValidatedPauseTime == currentUserMember.timerStartTime) {
        return;
      }

      // 일시정지 제한 시간 확인
      final pauseLimit =
          state.groupDetailResult.whenOrNull(
            data: (group) => group.pauseTimeLimit,
          ) ??
          120; // 기본값 120분

      if (TimeFormatter.isPauseTimeExceeded(
        currentUserMember.timerStartTime!,
        pauseLimit,
      )) {
        print('⏰ 일시정지 제한 시간 초과 감지 - 자동 종료 처리');
        _handleAutoEnd(currentUserMember.timerStartTime!);
        _lastValidatedPauseTime = currentUserMember.timerStartTime;
      } else {
        // 제한 시간 내라면 이전 상태 복원
        print('⏸️ 일시정지 상태 복원 - 제한 시간 내');
        _restorePausedState(currentUserMember.timerStartTime!);
      }
    }
  }

  // 🔧 비정상 종료 처리 (서버 상태로 발견된 경우)
  Future<void> _handleAbnormalTermination(DateTime lastActiveTime) async {
    final activityKey = 'abnormal_${lastActiveTime.millisecondsSinceEpoch}';
    if (_lastProcessedActivityKey == activityKey) {
      print('⚠️ 이미 처리된 비정상 종료입니다: $activityKey');
      return;
    }

    _lastProcessedActivityKey = activityKey;

    // 마지막 활동 시간 + 1마이크로초로 end 기록
    final endTime = lastActiveTime.add(const Duration(microseconds: 1));

    print('🔧 비정상 종료 처리: lastActiveTime=$lastActiveTime, endTime=$endTime');

    // 로컬 상태 초기화
    _timer?.cancel();
    _midnightTimer?.cancel();
    _localTimerStartTime = null;

    state = state.copyWith(
      timerStatus: TimerStatus.stop,
      elapsedSeconds: 0,
    );

    _updateCurrentUserInMemberList(isActive: false);

    // API 호출 (특정 시간으로 end 기록)
    await _recordTimerActivityWithTimestamp(TimerActivityType.end, endTime);

    // 서버 비정상 종료는 알림 없음, 화면 내 메시지만 표시
    final elapsedTime = DateTime.now().difference(lastActiveTime);
    final elapsedHours = elapsedTime.inHours;
    final elapsedMinutes = elapsedTime.inMinutes % 60;

    String message;
    if (elapsedHours > 0) {
      message =
          '이전 타이머가 비정상 종료되어 자동으로 정리되었습니다. (약 ${elapsedHours}시간 ${elapsedMinutes}분 전)';
    } else if (elapsedMinutes > 0) {
      message = '이전 타이머가 비정상 종료되어 자동으로 정리되었습니다. (약 ${elapsedMinutes}분 전)';
    } else {
      message = '이전 타이머가 비정상 종료되어 자동으로 정리되었습니다.';
    }

    state = state.copyWith(
      errorMessage: message,
    );
  }

  // 🔧 자동 종료 처리 (일시정지 제한 시간 초과)
  Future<void> _handleAutoEnd(DateTime pauseTime) async {
    // 중복 처리 방지
    final activityKey = 'auto_end_${pauseTime.millisecondsSinceEpoch}';
    if (_lastProcessedActivityKey == activityKey) {
      print('⚠️ 이미 처리된 자동 종료 이벤트입니다: $activityKey');
      return;
    }

    _lastProcessedActivityKey = activityKey;

    // pause 시간 + 1마이크로초로 end 시간 계산
    final endTime = TimeFormatter.getAutoEndTime(pauseTime);

    print('🔧 자동 종료 처리: pauseTime=$pauseTime, endTime=$endTime');

    // 로컬 상태 업데이트
    _timer?.cancel();
    _midnightTimer?.cancel();
    _localTimerStartTime = null;

    state = state.copyWith(
      timerStatus: TimerStatus.stop,
      elapsedSeconds: 0,
    );

    _updateCurrentUserInMemberList(isActive: false);

    // API 호출 (특정 시간으로 end 기록)
    await _recordTimerActivityWithTimestamp(TimerActivityType.end, endTime);

    // 서버에서 발견된 경우 알림 없음, 화면 내 메시지만 표시
    final pauseLimit =
        state.groupDetailResult.whenOrNull(
          data: (group) => group.pauseTimeLimit,
        ) ??
        120;

    state = state.copyWith(
      errorMessage: '일시정지 시간이 ${pauseLimit}분을 초과하여 타이머가 자동으로 종료되었습니다.',
    );
  }

  // 🔧 일시정지 상태 복원
  void _restorePausedState(DateTime pauseTime) {
    // pause 시점부터 현재까지의 시간은 계산하지 않음
    // pause 시점의 상태 그대로 복원

    _localTimerStartTime = pauseTime;

    state = state.copyWith(
      timerStatus: TimerStatus.paused,
      // elapsedSeconds는 서버에서 받은 값 그대로 유지
    );

    print('⏸️ 일시정지 상태 복원 완료');
  }

  // 🔧 자정 감지 시작
  void _startMidnightDetection() {
    _midnightTimer?.cancel();

    final timeUntilMidnight = TimeFormatter.timeUntilMidnight();

    print('🌙 자정 감지 타이머 시작: ${timeUntilMidnight.inMinutes}분 후');

    _midnightTimer = Timer(timeUntilMidnight, () async {
      if (state.timerStatus == TimerStatus.running) {
        print('🌙 자정 감지 - 날짜 변경 처리');
        await _handleDateChange();
      }

      // 다음 자정 감지를 위해 재시작
      _startMidnightDetection();
    });
  }

  // 🔧 날짜 변경 처리
  Future<void> _handleDateChange() async {
    // 중복 처리 방지
    final dateKey = 'date_change_${TimeFormatter.formatDate(DateTime.now())}';
    if (_lastProcessedActivityKey == dateKey) {
      print('⚠️ 이미 처리된 날짜 변경 이벤트입니다: $dateKey');
      return;
    }

    _lastProcessedActivityKey = dateKey;

    print('📅 날짜 변경 처리 시작');

    // 1. 어제 23:59:59로 pause 기록
    final yesterdayLastSecond = TimeFormatter.getYesterdayLastSecond();
    await _recordTimerActivityWithTimestamp(
      TimerActivityType.pause,
      yesterdayLastSecond,
    );

    // 잠시 대기 (순서 보장)
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. 오늘 00:00:00로 resume 기록 (start가 아닌 resume)
    final todayFirstSecond = TimeFormatter.getTodayFirstSecond();
    await _recordTimerActivityWithTimestamp(
      TimerActivityType.resume,
      todayFirstSecond,
    );

    // 로컬 타이머 시작 시간 업데이트
    _localTimerStartTime = todayFirstSecond;

    print('✅ 날짜 변경 처리 완료');
  }

  // 🔧 특정 시간으로 타이머 활동 기록
  Future<void> _recordTimerActivityWithTimestamp(
    TimerActivityType type,
    DateTime timestamp,
  ) async {
    print('📝 타이머 활동 기록: type=$type, timestamp=$timestamp');

    final result = await _recordTimerActivityUseCase?.executeWithTimestamp(
      groupId: _groupId,
      activityType: type,
      timestamp: timestamp,
    );

    if (result is AsyncError) {
      print('❌ 타이머 활동 기록 실패: ${result.error}');
    } else {
      print('✅ 타이머 활동 기록 성공');
    }
  }

  // 🔧 활성 상태 복원 (새로 추가)
  void _restoreActiveState(GroupMember member) {
    // 서버의 시작 시간을 그대로 사용
    _localTimerStartTime = member.timerStartTime;

    // 서버 시작 시간부터 현재까지의 경과 시간 계산
    final elapsedSeconds = member.elapsedSeconds;

    state = state.copyWith(
      timerStatus: TimerStatus.running,
      elapsedSeconds: elapsedSeconds,
    );

    // 로컬 타이머 시작
    _startTimerCountdown();
    _startMidnightDetection();

    print('✅ 타이머 상태 복원 완료: ${elapsedSeconds}초 경과');
  }
}
