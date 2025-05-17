import 'dart:async';

import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_member_timers_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_timer_sessions_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/resume_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/start_timer_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/stop_timer_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_timer_notifier.g.dart';

@riverpod
class GroupTimerNotifier extends _$GroupTimerNotifier {
  Timer? _timer;
  late final StartTimerUseCase _startTimerUseCase;
  late final StopTimerUseCase _stopTimerUseCase;
  late final ResumeTimerUseCase _resumeTimerUseCase;
  late final GetTimerSessionsUseCase _getTimerSessionsUseCase;
  late final GetMemberTimersUseCase _getMemberTimersUseCase; // 새로 추가
  late final GetGroupDetailUseCase _getGroupDetailUseCase; // 새로 추가

  @override
  GroupTimerState build() {
    // 의존성 주입
    _startTimerUseCase = ref.watch(startTimerUseCaseProvider);
    _stopTimerUseCase = ref.watch(stopTimerUseCaseProvider);
    _resumeTimerUseCase = ref.watch(resumeTimerUseCaseProvider);
    _getTimerSessionsUseCase = ref.watch(getTimerSessionsUseCaseProvider);
    _getMemberTimersUseCase = ref.watch(
      getMemberTimersUseCaseProvider,
    ); // 새로 추가
    _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider); // 새로 추가

    // 화면 이탈 시 타이머 정리
    ref.onDispose(() {
      _timer?.cancel();
    });

    return const GroupTimerState();
  }

  // 액션 처리
  Future<void> onAction(GroupTimerAction action) async {
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
      case NavigateToSettings():
      case NavigateToUserProfile():
        // 이러한 네비게이션 액션들은 Root에서 처리하므로 여기서는 아무 것도 하지 않음
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
      elapsedSeconds: 0, // 경과 시간 초기화
    );

    // 새 타이머 세션 시작
    final result = await _startTimerUseCase.execute(
      groupId: state.groupId,
      userId: 'current_user_id', // 실제 구현에서는 인증된 사용자 ID 사용
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
      activeSession: const AsyncValue.data(null), // 명시적으로 세션 초기화
    );

    // 세션 정보를 다시 로드하여 타이머를 재시작할 준비
    if (state.groupId.isNotEmpty) {
      await refreshAllData(); // 중복 코드 제거를 위해 refreshAllData 사용
    }
  }

  // 그룹 ID 설정
  Future<void> _handleSetGroupId(String groupId) async {
    print('📊 Setting group ID in notifier: $groupId');

    state = state.copyWith(groupId: groupId);

    // 중복 코드 제거: refreshAllData 메서드로 모든 데이터 로드
    await refreshAllData();
    await _checkActiveSession();
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

    final result = await _resumeTimerUseCase.execute(
      'current_user_id', // 실제 구현에서는 인증된 사용자 ID 사용
    );

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
      (_) => onAction(const GroupTimerAction.timerTick()),
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

  // 멤버 타이머 데이터 업데이트 - UseCase 사용
  Future<void> _updateMemberTimers() async {
    if (state.groupId.isEmpty) return;

    final result = await _getMemberTimersUseCase.execute(state.groupId);

    // 결과 처리
    if (result case AsyncData(:final value)) {
      state = state.copyWith(memberTimers: value);
    }
  }

  // 데이터 새로고침 메서드 - 모든 그룹 데이터를 한 번에 새로고침
  Future<void> refreshAllData() async {
    if (state.groupId.isEmpty) return;

    // 병렬로 모든 데이터 로드하여 성능 개선
    await Future.wait([
      _loadGroupDetail(state.groupId),
      _loadGroupSessions(state.groupId),
      _updateMemberTimers(),
    ]);
  }

  // 그룹 세부 정보 로드 헬퍼 메서드
  Future<void> _loadGroupDetail(String groupId) async {
    try {
      final groupDetailResult = await _getGroupDetailUseCase.execute(groupId);

      // 그룹 세부 정보 로드 성공 여부 체크 및 안전하게 처리
      switch (groupDetailResult) {
        case AsyncData(:final value):
          // 상태 업데이트
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
