// lib/group/presentation/group_detail/group_detail_notifier.dart
import 'dart:async';

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
  StreamSubscription? _timerStatusSubscription; // 🔧 실시간 스트림 구독

  late final StartTimerUseCase _startTimerUseCase;
  late final StopTimerUseCase _stopTimerUseCase;
  late final PauseTimerUseCase _pauseTimerUseCase;
  late final GetGroupDetailUseCase _getGroupDetailUseCase;
  late final GetGroupMembersUseCase _getGroupMembersUseCase;
  late final StreamGroupMemberTimerStatusUseCase
  _streamGroupMemberTimerStatusUseCase; // 🔧 새로운 UseCase

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
    _streamGroupMemberTimerStatusUseCase = ref.watch(
      streamGroupMemberTimerStatusUseCaseProvider,
    ); // 🔧 새로운 UseCase 주입

    // 화면 이탈 시 타이머 및 스트림 정리
    ref.onDispose(() {
      print('🗑️ GroupDetailNotifier dispose - 타이머 및 스트림 정리');
      _timer?.cancel();
      _timerStatusSubscription?.cancel(); // 🔧 스트림 구독 해제
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

    // 🔧 실시간 스트림이 자동으로 업데이트되므로 별도 새로고침 불필요
  }

  // 타이머 초기화 처리
  Future<void> _handleResetTimer() async {
    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.stop, elapsedSeconds: 0);

    // 🔧 실시간 스트림이 자동으로 업데이트되므로 별도 새로고침 불필요
  }

  // 그룹 ID 설정 (초기화 시에만 호출)
  Future<void> _handleSetGroupId(String groupId) async {
    print('📊 Setting group ID in notifier: $groupId');
    _groupId = groupId;

    // 그룹 ID 설정 후 초기 데이터 로드 (한 번만)
    await _loadInitialData();
  }

  // 🔧 초기 데이터 로드 (최초 한번은 기존 방식, 이후 실시간 스트림)
  Future<void> _loadInitialData() async {
    if (_groupId.isEmpty) return;

    print('🔄 초기 데이터 로드 시작 - groupId: $_groupId');

    try {
      // 1. 기본 그룹 정보와 최초 멤버 정보 로드
      await Future.wait([
        _loadGroupDetail(),
        _loadInitialGroupMembers(), // 🔧 최초 한번만 기존 방식으로 로드
      ], eagerError: false);

      // 2. 실시간 스트림 시작
      _startRealTimeTimerStatusStream();

      print('✅ 초기 데이터 로드 완료');
    } catch (e, s) {
      print('❌ _loadInitialData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 🔧 최초 멤버 정보 로드 (기존 방식)
  Future<void> _loadInitialGroupMembers() async {
    print('📥 최초 멤버 정보 로드 시작');

    // 로딩 상태 설정
    state = state.copyWith(groupMembersResult: const AsyncValue.loading());

    try {
      final result = await _getGroupMembersUseCase.execute(_groupId);
      state = state.copyWith(groupMembersResult: result);
      print('✅ 최초 멤버 정보 로드 완료');
    } catch (e) {
      print('❌ 최초 멤버 정보 로드 실패: $e');
      state = state.copyWith(
        groupMembersResult: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  // 🔧 실시간 타이머 상태 스트림 시작
  void _startRealTimeTimerStatusStream() {
    print('🔴 실시간 타이머 상태 스트림 시작');

    // 기존 구독이 있다면 해제
    _timerStatusSubscription?.cancel();

    // 새로운 실시간 스트림 구독
    _timerStatusSubscription = _streamGroupMemberTimerStatusUseCase
        .execute(_groupId)
        .listen(
          (asyncValue) {
            print('🔄 실시간 타이머 상태 업데이트 수신: ${asyncValue.runtimeType}');

            // 🔧 백그라운드에서 조용히 상태 업데이트 (로딩 상태 없음)
            switch (asyncValue) {
              case AsyncData(:final value):
                // 성공한 경우에만 상태 업데이트
                state = state.copyWith(groupMembersResult: asyncValue);
                print('✅ 실시간 멤버 상태 업데이트 완료 (${value.length}명)');

              case AsyncError(:final error):
                // 에러 발생 시 로그만 출력하고 기존 상태 유지
                print('⚠️ 실시간 스트림 에러 (기존 상태 유지): $error');

              case AsyncLoading():
                // 로딩 상태는 무시 (깜빡임 방지)
                print('🔄 실시간 스트림 로딩 중 (상태 유지)');
            }
          },
          onError: (error) {
            print('❌ 실시간 스트림 구독 에러: $error');
            // 에러가 발생해도 기존 상태 유지
          },
        );
  }

  // 타이머 시작
  void _startTimerCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onAction(const GroupDetailAction.timerTick()),
    );
  }

  // 🔧 타이머 틱 이벤트 처리 (실시간 스트림이 있어서 백그라운드 업데이트 제거)
  void _handleTimerTick() {
    if (state.timerStatus != TimerStatus.running) return;

    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);

    // 🔧 5초마다 백그라운드 업데이트 제거 - 실시간 스트림이 처리함
    // 이제 타이머는 단순히 elapsedSeconds만 업데이트
  }

  // 🔧 백그라운드 멤버 타이머 데이터 업데이트 메소드 제거됨
  // 실시간 스트림이 이 역할을 대신함

  // 데이터 새로고침 메서드 - 화면 재진입 시에만 사용
  Future<void> refreshAllData() async {
    if (_groupId.isEmpty) return;

    print('🔄 데이터 새로고침 시작 - groupId: $_groupId');

    try {
      // 🔧 그룹 정보만 새로고침 (멤버 정보는 실시간 스트림이 처리)
      await _loadGroupDetail();

      // 🔧 실시간 스트림 재시작 (연결이 끊어졌을 수도 있으므로)
      _startRealTimeTimerStatusStream();

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
