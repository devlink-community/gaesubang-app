// lib/group/data/data_source/group_data_source.dart

abstract interface class GroupDataSource {
  /// 전체 그룹 목록 조회
  Future<List<Map<String, dynamic>>> fetchGroupList({String? currentUserId});

  /// 특정 그룹 상세 정보 조회
  Future<Map<String, dynamic>> fetchGroupDetail(
    String groupId, {
    String? currentUserId,
  });

  /// 그룹 가입 처리
  Future<void> fetchJoinGroup(
    String groupId, {
    required String userId,
    required String userName,
    required String profileUrl,
  });

  /// 새 그룹 생성
  Future<Map<String, dynamic>> fetchCreateGroup(
    Map<String, dynamic> groupData, {
    required String ownerId,
    required String ownerName,
    required String ownerProfileUrl,
  });

  /// 그룹 정보 업데이트
  Future<void> fetchUpdateGroup(
    String groupId,
    Map<String, dynamic> updateData,
  );

  /// 그룹 탈퇴 처리
  Future<void> fetchLeaveGroup(String groupId, String userId);

  /// 특정 사용자가 가입한 그룹 목록 조회
  Future<List<Map<String, dynamic>>> fetchUserJoinedGroups(String userId);

  /// 그룹의 모든 멤버 조회
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId);

  /// 그룹의 모든 타이머 활동 조회 (최신순, 멤버별 필터링)
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(String groupId);

  /// 그룹 이미지 업데이트
  Future<String> updateGroupImage(String groupId, String localImagePath);

  /// 해시태그로 그룹 검색
  Future<List<Map<String, dynamic>>> searchGroupsByTags(
    List<String> tags, {
    String? currentUserId,
  });

  /// 키워드로 그룹 검색 (이름, 설명)
  Future<List<Map<String, dynamic>>> searchGroupsByKeyword(
    String keyword, {
    String? currentUserId,
  });

  /// 멤버 타이머 시작
  Future<Map<String, dynamic>> startMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  );

  /// 멤버 타이머 정지 (완료)
  Future<Map<String, dynamic>> stopMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  );

  /// 멤버 타이머 일시정지
  Future<Map<String, dynamic>> pauseMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  );

  /// 월별 출석 데이터 조회
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month,
  );
}
