// lib/group/data/data_source/group_data_source.dart
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';

abstract interface class GroupDataSource {
  /// 전체 그룹 목록 조회 - 내부에서 현재 사용자의 가입 그룹 정보 처리
  Future<List<Map<String, dynamic>>> fetchGroupList();

  /// 특정 그룹 상세 정보 조회 - 내부에서 현재 사용자의 가입 여부 처리
  Future<Map<String, dynamic>> fetchGroupDetail(String groupId);

  /// 그룹 가입 처리 - 내부에서 현재 사용자 정보 처리
  Future<void> fetchJoinGroup(String groupId);

  /// 새 그룹 생성 - 내부에서 현재 사용자를 소유자로 설정
  Future<Map<String, dynamic>> fetchCreateGroup(
    Map<String, dynamic> groupData,
  );

  /// 그룹 정보 업데이트
  Future<void> fetchUpdateGroup(
    String groupId,
    Map<String, dynamic> updateData,
  );

  /// 그룹 탈퇴 처리 - 내부에서 현재 사용자 정보 처리
  Future<void> fetchLeaveGroup(String groupId);

  /// 그룹의 모든 멤버 조회
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId);

  // 그룹의 모든 타이머 활동 조회 (최신순, 멤버별 필터링)
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(String groupId);

  /// 실시간 타이머 상태 스트림 조회 - 타이머 화면 표시용
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  );

  /// 그룹 이미지 업데이트
  Future<String> updateGroupImage(String groupId, String localImagePath);

  /// 통합 그룹 검색 (키워드, 태그 통합) - 내부에서 현재 사용자의 가입 그룹 정보 처리
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    bool searchKeywords = true,
    bool searchTags = true,
    int? limit,
    String? sortBy,
  });

  /// 월별 출석 데이터 조회 (이전 월 데이터도 선택적으로 함께 조회)
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month, {
    int preloadMonths = 0, // 이전 몇 개월의 데이터를 함께 가져올지
  });

  // ===== 타이머 액션 관련 메서드 =====

  /// 특정 시간으로 타이머 활동 기록 - 내부에서 현재 사용자 정보 처리
  /// 모든 타이머 관련 액션의 기본 메서드 (일반화된 인터페이스)
  Future<Map<String, dynamic>> recordTimerActivityWithTimestamp(
    String groupId,
    TimerActivityType activityType,
    DateTime timestamp,
  );

  /// 멤버 타이머 시작 - 내부에서 현재 사용자 정보 처리
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> startMemberTimer(String groupId);

  /// 멤버 타이머 일시정지 - 내부에서 현재 사용자 정보 처리
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId);

  /// 멤버 타이머 재개 - 내부에서 현재 사용자 정보 처리
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> resumeMemberTimer(String groupId);

  /// 멤버 타이머 종료 (완료) - 내부에서 현재 사용자 정보 처리
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> stopMemberTimer(String groupId);

  /// 특정 시간으로 타이머 시작 기록
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 일시정지 기록
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 재개 기록
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> resumeMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 종료 기록
  /// 내부적으로 recordTimerActivityWithTimestamp를 호출하여 구현
  Future<Map<String, dynamic>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );
}
