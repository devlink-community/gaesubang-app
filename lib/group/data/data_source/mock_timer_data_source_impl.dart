import 'dart:math';

import 'package:devlink_mobile_app/group/data/data_source/timer_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/timer_session_dto.dart';

class MockTimerDataSourceImpl implements TimerDataSource {
  // 메모리 내 스토리지 (이전 더미 세션 저장)
  final Map<String, TimerSessionDto> _sessions = {};
  final Map<String, TimerSessionDto> _activeSessionsByUser = {};
  final Random _random = Random();

  @override
  Future<TimerSessionDto> startTimer({
    required String groupId,
    required String userId,
  }) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 이미 진행 중인 세션이 있는지 확인
    final activeSession = _activeSessionsByUser[userId];
    if (activeSession != null) {
      return activeSession; // 이미 진행 중인 세션이 있으면 그대로 반환
    }

    // 새 세션 ID 생성
    final sessionId =
        'timer_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';

    // 새 세션 DTO 생성
    final newSession = TimerSessionDto(
      id: sessionId,
      groupId: groupId,
      userId: userId,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 2)), // 임시 종료 시간 (2시간 후)
      duration: 0, // 시작 시 0초
      isCompleted: false, // 시작 상태
    );

    // 메모리에 저장
    _sessions[sessionId] = newSession;
    _activeSessionsByUser[userId] = newSession;

    return newSession;
  }

  @override
  Future<TimerSessionDto> stopTimer({
    required String sessionId,
    required int duration,
  }) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 세션 찾기
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('타이머 세션을 찾을 수 없습니다.');
    }

    // 세션 업데이트
    final updatedSession = TimerSessionDto(
      id: session.id,
      groupId: session.groupId,
      userId: session.userId,
      startTime: session.startTime,
      endTime: DateTime.now(), // 현재 시간으로 종료
      duration: duration, // 전달받은 지속 시간
      isCompleted: true, // 완료 상태로 변경
    );

    // 메모리 업데이트
    _sessions[sessionId] = updatedSession;

    // 활성 세션에서 제거
    if (session.userId != null) {
      _activeSessionsByUser.remove(session.userId);
    }

    return updatedSession;
  }

  @override
  Future<List<TimerSessionDto>> fetchTimerSessions(String groupId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 700));

    // 그룹 ID에 해당하는 세션 필터링
    return _sessions.values
        .where((session) => session.groupId == groupId)
        .toList();
  }

  @override
  Future<TimerSessionDto> fetchTimerSession(String sessionId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 세션 ID로 세션 찾기
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('타이머 세션을 찾을 수 없습니다.');
    }

    return session;
  }

  @override
  Future<TimerSessionDto?> fetchActiveTimerSession(String userId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 유저 ID에 해당하는 활성 세션 반환
    return _activeSessionsByUser[userId];
  }
}
