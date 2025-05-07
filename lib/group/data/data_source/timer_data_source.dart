import 'package:devlink_mobile_app/group/data/dto/timer_session_dto.dart';

abstract interface class TimerDataSource {
  /// 새 타이머 세션 시작
  Future<TimerSessionDto> startTimer({
    required String groupId,
    required String userId,
  });

  /// 진행 중인 타이머 세션 종료
  Future<TimerSessionDto> stopTimer({
    required String sessionId,
    required int duration,
  });

  /// 타이머 세션 목록 조회 (그룹별)
  Future<List<TimerSessionDto>> fetchTimerSessions(String groupId);

  /// 타이머 세션 상세 조회
  Future<TimerSessionDto> fetchTimerSession(String sessionId);

  /// 유저의 진행 중인 타이머 조회
  Future<TimerSessionDto?> fetchActiveTimerSession(String userId);
}
