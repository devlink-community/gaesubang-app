// lib/group/presentation/group_detail/group_detail_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/group/domain/usecase/get_group_detail_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_members_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/pause_timer_use_case.dart';
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
  late final PauseTimerUseCase _pauseTimerUseCase;
  late final GetGroupDetailUseCase _getGroupDetailUseCase;
  late final GetGroupMembersUseCase _getGroupMembersUseCase;
  String _groupId = '';

  @override
  GroupDetailState build() {
    print('🏗️ GroupDetailNotifier build() 호출');

    // 의존성 주입
    _startTimerUseCase = ref.watch(startTimerUseCaseProvider);
    _stopTimerUseCase = ref.watch(stopTimerUseCaseProvider);
    _pauseTimerUseCase = ref.watch(pauseTimerUseCaseProvider);
    _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider);
    _getGroupMembersUseCase = ref.watch(getGroupMembersUseCaseProvider);

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
    if (_groupId.isEmpty) {
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

      // 네비게이션 액션들 - 이 파일에서는 처리하지 않음(Root에서 처리)
      case NavigateToAttendance():
      case NavigateToMap():
      case NavigateToSettings():
      case NavigateToUserProfile():
      case NavigateToChat():
        break;

      case SetGroupInfo():
        // 더 이상 필요 없음 - 그룹 상세 정보에서 직접 사용
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
    await _startTimerUseCase.execute(_groupId);

    // 타이머 시작
    _startTimerCountdown();

    // 멤버 타이머 데이터 업데이트
    await _updateGroupMembers();
  }

  // 타이머 일시정지 처리
  Future<void> _handlePauseTimer() async {
    if (state.timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.paused);

    await _pauseTimerUseCase.execute(_groupId);
  }

  // 타이머 재개 처리
  void _handleResumeTimer() {
    if (state.timerStatus != TimerStatus.paused) return;

    state = state.copyWith(timerStatus: TimerStatus.running);
    _startTimerCountdown();
  }

  // 타이머 종료 처리
  Future<void> _handleStopTimer() async {
    if (state.timerStatus == TimerStatus.stop) {
      return;
    }

    _timer?.cancel();

    // 세션 종료
    await _stopTimerUseCase.execute(_groupId);

    // 상태 업데이트
    state = state.copyWith(timerStatus: TimerStatus.stop);

    // 데이터 새로고침
    await refreshAllData();
  }

  // 타이머 초기화 처리
  Future<void> _handleResetTimer() async {
    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.stop, elapsedSeconds: 0);

    // 데이터 새로고침
    if (_groupId.isNotEmpty) {
      await refreshAllData();
    }
  }

  // 그룹 ID 설정 (초기화 시에만 호출)
  Future<void> _handleSetGroupId(String groupId) async {
    print('📊 Setting group ID in notifier: $groupId');
    _groupId = groupId;

    // 그룹 ID 설정 후 초기 데이터 로드 (한 번만)
    await _loadInitialData();
  }

  // 초기 데이터 로드 (새로고침과 활성 세션 확인을 한 번에)
  Future<void> _loadInitialData() async {
    if (_groupId.isEmpty) return;

    print('🔄 초기 데이터 로드 시작 - groupId: $_groupId');

    try {
      // 모든 초기 데이터를 병렬로 로드
      await Future.wait([
        _loadGroupDetail(),
        _updateGroupMembers(),
      ], eagerError: false);
      print('✅ 초기 데이터 로드 완료');
    } catch (e, s) {
      print('❌ _loadInitialData 실패: $e');
      debugPrintStack(stackTrace: s);
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
      _updateGroupMembers();
    }
  }

  // 멤버 타이머 데이터 업데이트
  Future<void> _updateGroupMembers() async {
    if (_groupId.isEmpty) return;

    state = state.copyWith(groupMembersResult: const AsyncValue.loading());
    final result = await _getGroupMembersUseCase.execute(_groupId);
    state = state.copyWith(groupMembersResult: result);
  }

  // 데이터 새로고침 메서드 - 화면 재진입 시에만 사용
  Future<void> refreshAllData() async {
    if (_groupId.isEmpty) return;

    print('🔄 데이터 새로고침 시작 - groupId: $_groupId');

    try {
      await Future.wait([
        _loadGroupDetail(),
        _updateGroupMembers(),
      ], eagerError: false);
      print('✅ 데이터 새로고침 완료');
    } catch (e, s) {
      print('❌ refreshAllData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 그룹 세부 정보 로드 헬퍼 메서드
  Future<void> _loadGroupDetail() async {
    state = state.copyWith(groupDetailResult: const AsyncValue.loading());
    final result = await _getGroupDetailUseCase.execute(_groupId);
    state = state.copyWith(groupDetailResult: result);
  }
}
