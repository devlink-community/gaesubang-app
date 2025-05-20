import 'dart:async';

import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_member_timers_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_timer_sessions_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/resume_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/start_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/stop_timer_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_detail_notifier.g.dart';

@riverpod
class GroupDetailNotifier extends _$GroupDetailNotifier {
  Timer? _timer;
  late final StartTimerUseCase _startTimerUseCase;
  late final StopTimerUseCase _stopTimerUseCase;
  late final ResumeTimerUseCase _resumeTimerUseCase;
  late final GetTimerSessionsUseCase _getTimerSessionsUseCase;
  late final GetMemberTimersUseCase _getMemberTimersUseCase;
  late final GetGroupDetailUseCase _getGroupDetailUseCase;

  @override
  GroupDetailState build() {
    print('🏗️ GroupDetailNotifier build() 호출');

    // 의존성 주입
    _startTimerUseCase = ref.watch(startTimerUseCaseProvider);
    _stopTimerUseCase = ref.watch(stopTimerUseCaseProvider);
    _resumeTimerUseCase = ref.watch(resumeTimerUseCaseProvider);
    _getTimerSessionsUseCase = ref.watch(getTimerSessionsUseCaseProvider);
    _getMemberTimersUseCase = ref.watch(getMemberTimersUseCaseProvider);
    _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider);

    // 화면 이탈 시 타이머 정리
    ref.onDispose(() {
      print('🗑️ GroupDetailNotifier dispose - 타이머 정리');
      _timer?.cancel();
    });

    // build()에서는 초기 상태만 반환
    return const GroupDetailState();
  }

  // 화면 재진입 시 데이터 갱신 (Root에서 호출)
  Future<void> onScreenReenter() async {
    if (state.groupId.isEmpty) {
      print('⚠️ 그룹 ID가 설정되지 않아 데이터 갱신을 건너뜁니다');
      return;
    }

    print('🔄 화면 재진입 감지 - 데이터 새로고침 시작');
    await refreshAllData();
  }

  // 액션 처리
  Future<void> onAction(GroupDetailAction action) async {
    switch (action) {
      case StartTimer():
        await _handleStartTimer();

      case PauseTimer():
        _handlePauseTimer();

      case ResumeTimer():
        _handleResumeTimer();

      case StopTimer():
        await _handleStopTimer();

      case ResetTimer():
        await _handleResetTimer();

      case SetGroupId(:final groupId):
        await _handleSetGroupId(groupId);

      case SetGroupInfo(:final groupName, :final hashTags):
        _handleSetGroupInfo(groupName, hashTags);

      case RefreshSessions():
        await _loadGroupSessions(state.groupId);

      case TimerTick():
        _handleTimerTick();

      case ToggleTimer():
        if (state.timerStatus == TimerStatus.running) {
          _handlePauseTimer();
        } else if (state.timerStatus == TimerStatus.paused ||
            state.timerStatus == TimerStatus.initial ||
            state.timerStatus == TimerStatus.completed) {
          if (state.timerStatus == TimerStatus.initial ||
              state.timerStatus == TimerStatus.completed) {
            await _handleStartTimer();
          } else {
            _handleResumeTimer();
          }
        }
        break;

      // 네비게이션 액션들 - 이 파일에서는 처리하지 않음(Root에서 처리)
      case NavigateToAttendance():
      case NavigateToMap():
      case NavigateToSettings():
      case NavigateToUserProfile():
      case NavigateToChat():
        break;
    }
  }

  // 타이머 시작 처리
  Future<void> _handleStartTimer() async {
    if (state.timerStatus == TimerStatus.running) return;

    // 타이머 상태 및 경과 시간 초기화
    state = state.copyWith(
      timerStatus: TimerStatus.running,
      errorMessage: null,
      elapsedSeconds: 0,
    );

    // 새 타이머 세션 시작
    final result = await _startTimerUseCase.execute(
      groupId: state.groupId,
      userId: 'current_user_id',
    );

    // 결과 처리
    state = state.copyWith(activeSession: result);

    // 타이머 시작
    _startTimerCountdown();

    // 멤버 타이머 데이터 업데이트
    await _updateMemberTimers();
  }

  // 타이머 일시정지 처리
  void _handlePauseTimer() {
    if (state.timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.paused);
  }

  // 타이머 재개 처리
  void _handleResumeTimer() {
    if (state.timerStatus != TimerStatus.paused) return;

    state = state.copyWith(timerStatus: TimerStatus.running);
    _startTimerCountdown();
  }

  // 타이머 종료 처리
  Future<void> _handleStopTimer() async {
    if (state.timerStatus == TimerStatus.initial ||
        state.timerStatus == TimerStatus.completed) {
      return;
    }

    _timer?.cancel();

    // 세션 정보 확인
    final activeSession = state.activeSession.valueOrNull;
    if (activeSession == null) {
      state = state.copyWith(
        timerStatus: TimerStatus.completed,
        errorMessage: '세션 정보를 찾을 수 없습니다.',
      );
      return;
    }

    // 세션 종료
    final result = await _stopTimerUseCase.execute(
      sessionId: activeSession.id,
      duration: state.elapsedSeconds,
    );

    // 상태 업데이트
    state = state.copyWith(
      timerStatus: TimerStatus.completed,
      activeSession: result,
    );

    // 세션 목록 새로고침
    await _loadGroupSessions(state.groupId);
  }

  // 타이머 초기화 처리
  Future<void> _handleResetTimer() async {
    _timer?.cancel();
    state = state.copyWith(
      timerStatus: TimerStatus.initial,
      elapsedSeconds: 0,
      activeSession: const AsyncValue.data(null),
    );

    // 데이터 새로고침
    if (state.groupId.isNotEmpty) {
      await refreshAllData();
    }
  }

  // 그룹 ID 설정 (초기화 시에만 호출)
  Future<void> _handleSetGroupId(String groupId) async {
    print('📊 Setting group ID in notifier: $groupId');

    state = state.copyWith(groupId: groupId);

    // 그룹 ID 설정 후 초기 데이터 로드 (한 번만)
    await _loadInitialData();
  }

  // 초기 데이터 로드 (새로고침과 활성 세션 확인을 한 번에)
  Future<void> _loadInitialData() async {
    if (state.groupId.isEmpty) return;

    print('🔄 초기 데이터 로드 시작 - groupId: ${state.groupId}');

    try {
      // 모든 초기 데이터를 병렬로 로드
      await Future.wait([
        _loadGroupDetail(state.groupId),
        _loadGroupSessions(state.groupId),
        _updateMemberTimers(),
        _checkActiveSession(),
      ], eagerError: false);
      print('✅ 초기 데이터 로드 완료');
    } catch (e, s) {
      print('❌ _loadInitialData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 그룹 정보 설정
  void _handleSetGroupInfo(String groupName, List<String> hashTags) {
    state = state.copyWith(groupName: groupName, hashTags: hashTags);
  }

  // 그룹 세션 목록 로드
  Future<void> _loadGroupSessions(String groupId) async {
    if (groupId.isEmpty) return;

    state = state.copyWith(sessions: const AsyncValue.loading());
    final result = await _getTimerSessionsUseCase.execute(groupId);
    state = state.copyWith(sessions: result);
  }

  // 진행 중인 세션 확인
  Future<void> _checkActiveSession() async {
    state = state.copyWith(activeSession: const AsyncValue.loading());

    final result = await _resumeTimerUseCase.execute('current_user_id');

    state = state.copyWith(activeSession: result);

    // 진행 중인 세션이 있으면 타이머 재개
    final session = result.valueOrNull;
    if (session != null && !session.isCompleted) {
      // 경과 시간 계산 (세션 시작 시간부터 현재까지)
      final elapsedTime =
          DateTime.now().difference(session.startTime).inSeconds;
      state = state.copyWith(
        elapsedSeconds: elapsedTime,
        timerStatus: TimerStatus.running,
      );
      _startTimerCountdown();
    }
  }

  // 타이머 시작
  void _startTimerCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onAction(const GroupDetailAction.timerTick()),
    );
  }

  // 타이머 틱 이벤트 처리
  void _handleTimerTick() {
    if (state.timerStatus != TimerStatus.running) return;

    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);

    // 5초마다 멤버 타이머 업데이트
    if (state.elapsedSeconds % 5 == 0) {
      _updateMemberTimers();
    }
  }

  // 멤버 타이머 데이터 업데이트
  Future<void> _updateMemberTimers() async {
    if (state.groupId.isEmpty) return;

    final result = await _getMemberTimersUseCase.execute(state.groupId);

    if (result case AsyncData(:final value)) {
      state = state.copyWith(memberTimers: value);
    }
  }

  // 데이터 새로고침 메서드 - 화면 재진입 시에만 사용
  Future<void> refreshAllData() async {
    if (state.groupId.isEmpty) return;

    print('🔄 데이터 새로고침 시작 - groupId: ${state.groupId}');

    // 활성 세션 확인은 제외하고 그룹 데이터만 새로고침
    try {
      await Future.wait([
        _loadGroupDetail(state.groupId),
        _loadGroupSessions(state.groupId),
        _updateMemberTimers(),
      ], eagerError: false);
      print('✅ 데이터 새로고침 완료');
    } catch (e, s) {
      print('❌ refreshAllData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 그룹 세부 정보 로드 헬퍼 메서드
  Future<void> _loadGroupDetail(String groupId) async {
    try {
      print('🔍 그룹 세부 정보 로드 시작: $groupId');
      final groupDetailResult = await _getGroupDetailUseCase.execute(groupId);

      switch (groupDetailResult) {
        case AsyncData(:final value):
          print('✅ 그룹 세부 정보 로드 성공: ${value.name}');
          state = state.copyWith(
            groupName: value.name,
            participantCount: value.memberCount,
            totalMemberCount: value.limitMemberCount,
            hashTags: value.hashTags.map((tag) => tag.content).toList(),
          );

        case AsyncError(:final error):
          print('❌ Failed to load group detail: $error');

        case AsyncLoading():
          print('⏳ Loading group detail...');
      }
    } catch (e) {
      print('❌ Error loading group detail: $e');
    }
  }
}
