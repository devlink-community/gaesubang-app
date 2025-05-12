import 'dart:math';

import 'package:devlink_mobile_app/group/data/data_source/timer_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/timer_session_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/member_timer.dart';
import 'package:devlink_mobile_app/group/domain/model/member_timer_status.dart';

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

  @override
  Future<List<MemberTimer>> fetchMemberTimers(String groupId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 기존 이미지들 - 실제 환경에서는 서버에서 URL을 가져와야 함
    final imageUrls = [
      "https://example.com/avatar1.jpg", // 여우 이미지
      "https://example.com/avatar2.jpg", // 곰돌이 이미지
      "https://example.com/avatar3.jpg", // 웨딩 이미지
      "https://example.com/avatar4.jpg", // 고양이 이미지
      "https://example.com/avatar5.jpg", // 안경 쓴 남자 이미지
      "https://example.com/avatar6.jpg", // 모자 쓴 이미지
    ];

    // 모의 데이터
    final mockMembers = [
      MemberTimer(
        memberId: "user1",
        memberName: "이용자1",
        imageUrl: imageUrls[0],
        elapsedSeconds: 3 * 3600, // 3시간
        status: MemberTimerStatus.active,
      ),
      MemberTimer(
        memberId: "user2",
        memberName: "이용자2",
        imageUrl: imageUrls[1],
        elapsedSeconds: 0,
        status: MemberTimerStatus.sleeping,
      ),
      MemberTimer(
        memberId: "user3",
        memberName: "이용자3",
        imageUrl: imageUrls[2],
        elapsedSeconds: 3 * 3600, // 3시간
        status: MemberTimerStatus.active,
      ),
      MemberTimer(
        memberId: "user4",
        memberName: "이용자4",
        imageUrl: imageUrls[3],
        elapsedSeconds: 13 * 3600, // 13시간
        status: MemberTimerStatus.active,
      ),
      MemberTimer(
        memberId: "user5",
        memberName: "이용자5",
        imageUrl: imageUrls[4],
        elapsedSeconds: 32 * 3600, // 32시간
        status: MemberTimerStatus.active,
      ),
      MemberTimer(
        memberId: "user6",
        memberName: "이용자6",
        imageUrl: imageUrls[5],
        elapsedSeconds: 0,
        status: MemberTimerStatus.sleeping,
      ),
    ];

    return mockMembers;
  }
}
