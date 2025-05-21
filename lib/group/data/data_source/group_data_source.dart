// lib/group/data/data_source/group_data_source.dart

abstract interface class GroupDataSource {
  /// 전체 그룹 목록 조회
  Future<List<Map<String, dynamic>>> fetchGroupList({
    Set<String>? joinedGroupIds,
  });

  /// 특정 그룹 상세 정보 조회
  Future<Map<String, dynamic>> fetchGroupDetail(
    String groupId, {
    bool? isJoined,
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
    required String ownerNickname,
    required String ownerProfileUrl,
  });

  /// 그룹 정보 업데이트
  Future<void> fetchUpdateGroup(
    String groupId,
    Map<String, dynamic> updateData,
  );

  /// 그룹 탈퇴 처리
  Future<void> fetchLeaveGroup(String groupId, String userId);

  // /// 특정 사용자가 가입한 그룹 목록 조회
  // Future<List<Map<String, dynamic>>> fetchUserJoinedGroups(String userId);

  /// 그룹의 모든 멤버 조회
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId);

  /// 그룹의 모든 타이머 활동 조회 (최신순, 멤버별 필터링)
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(String groupId);

  /// 그룹 이미지 업데이트
  Future<String> updateGroupImage(String groupId, String localImagePath);

  /// 통합 그룹 검색 (키워드, 태그 통합)
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    bool searchKeywords = true,
    bool searchTags = true,
    Set<String>? joinedGroupIds, // currentUserId 대신 joinedGroupIds 사용
    int? limit,
    String? sortBy,
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

  /// 월별 출석 데이터 조회 (이전 월 데이터도 선택적으로 함께 조회)
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month, {
    int preloadMonths = 0, // 이전 몇 개월의 데이터를 함께 가져올지
  });
}
