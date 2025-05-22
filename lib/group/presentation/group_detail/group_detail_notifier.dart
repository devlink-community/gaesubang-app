// lib/group/presentation/group_detail/group_detail_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
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

  // 🔧 late 필드를 nullable로 변경하여 중복 초기화 문제 해결
  StartTimerUseCase? _startTimerUseCase;
  StopTimerUseCase? _stopTimerUseCase;
  PauseTimerUseCase? _pauseTimerUseCase;
  GetGroupDetailUseCase? _getGroupDetailUseCase;
  GetGroupMembersUseCase? _getGroupMembersUseCase;
  StreamGroupMemberTimerStatusUseCase? _streamGroupMemberTimerStatusUseCase;

  String _groupId = '';
  String? _currentUserId;
  DateTime? _localTimerStartTime;

  @override
  GroupDetailState build() {
    print('🏗️ GroupDetailNotifier build() 호출');

    // 🔧 이미 초기화된 경우 skip (중복 초기화 방지)
    if (_startTimerUseCase == null) {
      // 의존성 주입
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

    // 현재 사용자 ID 가져오기 (매번 업데이트될 수 있으므로 항상 확인)
    final currentUser = ref.watch(currentUserProvider);
    _currentUserId = currentUser?.uid;

    // 화면 이탈 시 타이머 및 스트림 정리
    ref.onDispose(() {
      print('🗑️ GroupDetailNotifier dispose - 타이머 및 스트림 정리');
      _timer?.cancel();
      _timerStatusSubscription?.cancel();
    });

    return const GroupDetailState();
  }

  // 화면 재진입 시 데이터 갱신
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

  // 🔧 타이머 시작 처리 - 멤버 리스트 즉시 업데이트 추가
  Future<void> _handleStartTimer() async {
    if (state.timerStatus == TimerStatus.running) return;

    // 로컬 타이머 시작 시간 기록
    _localTimerStartTime = DateTime.now();

    // 타이머 상태 및 경과 시간 초기화
    state = state.copyWith(
      timerStatus: TimerStatus.running,
      errorMessage: null,
      elapsedSeconds: 0,
    );

    // 🔧 즉시 멤버 리스트의 현재 사용자 상태 업데이트
    _updateCurrentUserInMemberList(
      isActive: true,
      timerStartTime: _localTimerStartTime,
    );

    // 새 타이머 세션 시작
    await _startTimerUseCase?.execute(_groupId);

    // 타이머 시작
    _startTimerCountdown();
  }

  // 🔧 타이머 일시정지 처리 - 멤버 리스트 즉시 업데이트 추가
  Future<void> _handlePauseTimer() async {
    if (state.timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    state = state.copyWith(timerStatus: TimerStatus.paused);

    // 🔧 즉시 멤버 리스트의 현재 사용자 상태 업데이트
    _updateCurrentUserInMemberList(isActive: false);

    await _pauseTimerUseCase?.execute(_groupId);
  }

  // 🔧 타이머 재개 처리 - 멤버 리스트 즉시 업데이트 추가
  void _handleResumeTimer() {
    if (state.timerStatus != TimerStatus.paused) return;

    // 타이머 재개 시점 기록
    _localTimerStartTime = DateTime.now();

    state = state.copyWith(timerStatus: TimerStatus.running);

    // 🔧 즉시 멤버 리스트의 현재 사용자 상태 업데이트
    _updateCurrentUserInMemberList(
      isActive: true,
      timerStartTime: _localTimerStartTime,
    );

    _startTimerCountdown();
  }

  // 🔧 타이머 종료 처리 - 멤버 리스트 즉시 업데이트 추가
  Future<void> _handleStopTimer() async {
    if (state.timerStatus == TimerStatus.stop) {
      return;
    }

    _timer?.cancel();
    _localTimerStartTime = null;

    // 세션 종료
    await _stopTimerUseCase?.execute(_groupId);

    // 상태 업데이트
    state = state.copyWith(timerStatus: TimerStatus.stop);

    // 🔧 즉시 멤버 리스트의 현재 사용자 상태 업데이트
    _updateCurrentUserInMemberList(isActive: false);
  }

  // 🔧 타이머 초기화 처리 - 멤버 리스트 즉시 업데이트 추가
  Future<void> _handleResetTimer() async {
    _timer?.cancel();
    _localTimerStartTime = null;

    state = state.copyWith(timerStatus: TimerStatus.stop, elapsedSeconds: 0);

    // 🔧 즉시 멤버 리스트의 현재 사용자 상태 업데이트
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

      _startRealTimeTimerStatusStream();

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

  // 🔧 실시간 타이머 상태 스트림 시작 - 타입 안전성 수정
  void _startRealTimeTimerStatusStream() {
    print('🔴 실시간 타이머 상태 스트림 시작');

    _timerStatusSubscription?.cancel();

    _timerStatusSubscription = _streamGroupMemberTimerStatusUseCase
        ?.execute(_groupId)
        .listen(
          (asyncValue) {
            print('🔄 실시간 타이머 상태 업데이트 수신: ${asyncValue.runtimeType}');

            switch (asyncValue) {
              case AsyncData(:final value):
                // 🔧 타입 안전성 확보 및 로컬 상태와 병합
                final mergedMembers = _mergeLocalTimerStateWithRemoteData(
                  value,
                );
                state = state.copyWith(
                  groupMembersResult: AsyncData(mergedMembers),
                );
                print('✅ 실시간 멤버 상태 업데이트 완료 (${mergedMembers.length}명)');

              case AsyncError(:final error):
                print('⚠️ 실시간 스트림 에러 (기존 상태 유지): $error');

              case AsyncLoading():
                print('🔄 실시간 스트림 로딩 중 (상태 유지)');
            }
          },
          onError: (error) {
            print('❌ 실시간 스트림 구독 에러: $error');
          },
        );
  }

  // 🔧 현재 사용자의 멤버 리스트 상태 즉시 업데이트 - null 안전성 추가
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
      print('⚠️ 멤버 리스트가 null이어서 업데이트를 건너뜁니다');
      return;
    }

    // 🔧 경과 시간을 더 정확하게 계산 (초 단위)
    final int elapsedSeconds =
        isActive && timerStartTime != null
            ? DateTime.now().difference(timerStartTime).inSeconds
            : 0;

    final updatedMembers =
        currentMembers.map((member) {
          if (member.userId == _currentUserId) {
            // 현재 사용자의 상태만 업데이트
            return member.copyWith(
              isActive: isActive,
              timerStartTime: timerStartTime,
              // 🔧 elapsedMinutes 대신 실제 경과 시간을 분 단위로 정확히 계산
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

  // 🔧 로컬 타이머 상태와 원격 데이터 병합 - 타입 안전성 수정
  List<GroupMember> _mergeLocalTimerStateWithRemoteData(
    List<GroupMember> remoteMembers,
  ) {
    if (_currentUserId == null) return remoteMembers;

    // 현재 로컬 타이머 상태 확인
    final isLocalTimerActive = state.timerStatus == TimerStatus.running;
    final localStartTime = _localTimerStartTime;

    return remoteMembers.map((member) {
      if (member.userId == _currentUserId) {
        // 🔧 현재 사용자는 로컬 상태로 덮어쓰기 (더 정확한 시간 계산)
        final elapsedSeconds =
            isLocalTimerActive && localStartTime != null
                ? DateTime.now().difference(localStartTime).inSeconds
                : 0;

        return member.copyWith(
          isActive: isLocalTimerActive,
          timerStartTime: localStartTime,
          elapsedMinutes: (elapsedSeconds / 60).floor(),
        );
      }
      // 다른 사용자는 원격 데이터 그대로 사용
      return member;
    }).toList();
  }

  // 타이머 시작
  void _startTimerCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onAction(const GroupDetailAction.timerTick()),
    );
  }

  // 🔧 타이머 틱 이벤트 처리 - 멤버 리스트의 현재 사용자 시간도 업데이트
  void _handleTimerTick() {
    if (state.timerStatus != TimerStatus.running) return;

    // 로컬 타이머 경과 시간 업데이트
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);

    // 🔧 멤버 리스트의 현재 사용자 경과 시간도 업데이트 (매초마다)
    if (_localTimerStartTime != null) {
      _updateCurrentUserInMemberList(
        isActive: true,
        timerStartTime: _localTimerStartTime,
      );
    }
  }

  // 데이터 새로고침
  Future<void> refreshAllData() async {
    if (_groupId.isEmpty) return;

    print('🔄 데이터 새로고침 시작 - groupId: $_groupId');

    try {
      await _loadGroupDetail();
      _startRealTimeTimerStatusStream();

      print('✅ 데이터 새로고침 완료');
    } catch (e, s) {
      print('❌ refreshAllData 실패: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // 그룹 세부 정보 로드
  Future<void> _loadGroupDetail() async {
    state = state.copyWith(groupDetailResult: const AsyncValue.loading());
    final result = await _getGroupDetailUseCase?.execute(_groupId);
    if (result != null) {
      state = state.copyWith(groupDetailResult: result);
    }
  }
}
