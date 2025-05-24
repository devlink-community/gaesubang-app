// lib/group/data/data_source/group_firebase_data_source.dart
// 타이머 관련 메서드들을 일관된 방식으로 수정합니다

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/data/data_source/firebase/group_core_firebase.dart';
import 'package:devlink_mobile_app/group/data/data_source/firebase/group_query_firebase.dart';
import 'package:devlink_mobile_app/group/data/data_source/firebase/group_stats_firebase.dart';
import 'package:devlink_mobile_app/group/data/data_source/firebase/group_timer_firebase.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Facade 패턴으로 구현된 메인 그룹 Firebase DataSource
/// 내부적으로 여러 Firebase DataSource들을 조합하여 사용
class GroupFirebaseDataSource implements GroupDataSource {
  final GroupCoreFirebase _core;
  final GroupQueryFirebase _query;
  final GroupTimerFirebase _timer;
  final GroupStatsFirebase _stats;

  GroupFirebaseDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  }) : _core = GroupCoreFirebase(firestore: firestore, auth: auth),
       _query = GroupQueryFirebase(firestore: firestore, auth: auth),
       _timer = GroupTimerFirebase(firestore: firestore, auth: auth),
       _stats = GroupStatsFirebase(
         firestore: firestore,
         storage: storage,
         auth: auth,
       );

  // ===== Core 기능 위임 =====
  @override
  Future<Map<String, dynamic>> fetchCreateGroup(
    Map<String, dynamic> groupData,
  ) async {
    return _core.createGroup(groupData);
  }

  @override
  Future<void> fetchUpdateGroup(
    String groupId,
    Map<String, dynamic> updateData,
  ) async {
    return _core.updateGroup(groupId, updateData);
  }

  @override
  Future<void> fetchJoinGroup(String groupId) async {
    await _core.joinGroup(groupId);
    // 캐시 무효화
    _query.invalidateJoinedGroupsCache();
    _query.invalidateGroupMembersCache(groupId);
  }

  @override
  Future<void> fetchLeaveGroup(String groupId) async {
    await _core.leaveGroup(groupId);
    // 캐시 무효화
    _query.invalidateJoinedGroupsCache();
    _query.invalidateGroupMembersCache(groupId);
  }

  // ===== Query 기능 위임 =====
  @override
  Future<List<Map<String, dynamic>>> fetchGroupList() async {
    return _query.fetchGroupList();
  }

  @override
  Future<Map<String, dynamic>> fetchGroupDetail(String groupId) async {
    return _query.fetchGroupDetail(groupId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    return _query.fetchGroupMembers(groupId);
  }

  @override
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    bool searchKeywords = true,
    bool searchTags = true,
    int? limit,
    String? sortBy,
  }) async {
    return _query.searchGroups(
      query,
      searchKeywords: searchKeywords,
      searchTags: searchTags,
      limit: limit,
      sortBy: sortBy,
    );
  }

  // ===== Timer 기능 위임 =====

  @override
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(
    String groupId,
  ) async {
    return _timer.fetchGroupTimerActivities(groupId);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    return _timer.streamGroupMemberTimerStatus(groupId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month, {
    int preloadMonths = 0,
  }) async {
    return _timer.fetchMonthlyAttendances(
      groupId,
      year,
      month,
      preloadMonths: preloadMonths,
    );
  }

  // ===== 타이머 액션 메서드 - 일관된 방식으로 구현 =====

  @override
  Future<Map<String, dynamic>> recordTimerActivityWithTimestamp(
    String groupId,
    String activityType,
    DateTime timestamp,
  ) async {
    return _timer.recordTimerActivityWithTimestamp(
      groupId,
      activityType,
      timestamp,
    );
  }

  @override
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    // 현재 시간으로 'start' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'start', DateTime.now());
  }

  @override
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId) async {
    // 현재 시간으로 'pause' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'pause', DateTime.now());
  }

  @override
  Future<Map<String, dynamic>> resumeMemberTimer(String groupId) async {
    // 현재 시간으로 'resume' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'resume', DateTime.now());
  }

  @override
  Future<Map<String, dynamic>> stopMemberTimer(String groupId) async {
    // 현재 시간으로 'end' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'end', DateTime.now());
  }

  @override
  Future<Map<String, dynamic>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    // 지정된 시간으로 'start' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'start', timestamp);
  }

  @override
  Future<Map<String, dynamic>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    // 지정된 시간으로 'pause' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'pause', timestamp);
  }

  @override
  Future<Map<String, dynamic>> resumeMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    // 지정된 시간으로 'resume' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'resume', timestamp);
  }

  @override
  Future<Map<String, dynamic>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    // 지정된 시간으로 'end' 활동 기록
    return recordTimerActivityWithTimestamp(groupId, 'end', timestamp);
  }

  // ===== Stats 기능 위임 =====
  @override
  Future<Map<String, dynamic>> fetchUserMaxStreakDays() async {
    return _stats.fetchUserMaxStreakDays();
  }

  @override
  Future<int> fetchWeeklyStudyTimeMinutes() async {
    return _stats.fetchWeeklyStudyTimeMinutes();
  }

  @override
  Future<String> updateGroupImage(String groupId, String localImagePath) async {
    return _stats.updateGroupImage(groupId, localImagePath);
  }

  /// 리소스 정리 메서드
  void dispose() {
    AppLogger.info(
      'Disposing GroupFirebaseDataSource',
      tag: 'GroupFirebaseDataSource',
    );
    // 필요한 경우 각 Firebase DataSource의 dispose 호출
  }
}
