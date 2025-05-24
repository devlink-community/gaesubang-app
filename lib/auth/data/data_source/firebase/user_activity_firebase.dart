// lib/auth/data/data_source/firebase/user_activity_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';

import '../../dto/activity_dto.dart';
import '../../dto/summary_dto.dart';

/// Firebase 사용자 활동 (Activity, Summary) 관련 기능
class UserActivityFirebase {
  final FirebaseFirestore _firestore;

  UserActivityFirebase({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 사용자 Summary 조회
  Future<Map<String, dynamic>?> fetchUserSummary(String userId) async {
    return ApiCallDecorator.wrap(
      'UserActivityFirebase.fetchUserSummary',
      () async {
        AppLogger.debug('Firebase 사용자 Summary 조회: $userId');

        try {
          final summaryDoc =
              await _usersCollection
                  .doc(userId)
                  .collection('summary')
                  .doc('current')
                  .get();

          if (!summaryDoc.exists) {
            AppLogger.debug('Summary 문서 없음 - 기본값 반환');
            return _getDefaultSummary();
          }

          final summaryData = summaryDoc.data()!;

          AppLogger.authInfo('Firebase Summary 조회 성공');
          AppLogger.logState('Summary 정보', {
            'user_id': userId,
            'all_time_total_seconds': summaryData['allTimeTotalSeconds'] ?? 0,
            'current_streak_days': summaryData['currentStreakDays'] ?? 0,
            'last_activity_date': summaryData['lastActivityDate'],
          });

          return summaryData;
        } catch (e, st) {
          AppLogger.error('Firebase Summary 조회 오류', error: e, stackTrace: st);
          return _getDefaultSummary();
        }
      },
      params: {'userId': PrivacyMaskUtil.maskUserId(userId)},
    );
  }

  /// 사용자 Summary 업데이트
  Future<void> updateUserSummary({
    required String userId,
    required SummaryDto summary,
  }) async {
    return ApiCallDecorator.wrap(
      'UserActivityFirebase.updateUserSummary',
      () async {
        AppLogger.debug('Firebase 사용자 Summary 업데이트: $userId');

        try {
          final summaryRef = _usersCollection
              .doc(userId)
              .collection('summary')
              .doc('current');

          final summaryData = summary.toJson();
          summaryData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          await summaryRef.set(summaryData, SetOptions(merge: true));

          AppLogger.authInfo('Firebase Summary 업데이트 성공');
          AppLogger.logState('업데이트된 Summary', {
            'user_id': userId,
            'all_time_total_seconds': summary.allTimeTotalSeconds ?? 0,
            'current_streak_days': summary.currentStreakDays ?? 0,
          });
        } catch (e, st) {
          AppLogger.error('Firebase Summary 업데이트 오류', error: e, stackTrace: st);
          rethrow;
        }
      },
      params: {'userId': PrivacyMaskUtil.maskUserId(userId)},
    );
  }

  /// 그룹 Activity 조회
  Future<Map<String, dynamic>?> fetchGroupActivity({
    required String groupId,
    required String userId,
  }) async {
    return ApiCallDecorator.wrap(
      'UserActivityFirebase.fetchGroupActivity',
      () async {
        AppLogger.debug('Firebase 그룹 Activity 조회: $groupId/$userId');

        try {
          final activityDoc =
              await _firestore
                  .collection('groups')
                  .doc(groupId)
                  .collection('members')
                  .doc(userId)
                  .collection('activity')
                  .doc('current')
                  .get();

          if (!activityDoc.exists) {
            AppLogger.debug('Activity 문서 없음 - 기본값 반환');
            return _getDefaultActivity();
          }

          final activityData = activityDoc.data()!;

          AppLogger.authInfo('Firebase Activity 조회 성공');
          AppLogger.logState('Activity 정보', {
            'group_id': groupId,
            'user_id': userId,
            'timer_status': activityData['timerStatus'] ?? 'end',
            'today_total_seconds': activityData['todayTotalSeconds'] ?? 0,
            'all_time_total_seconds': activityData['allTimeTotalSeconds'] ?? 0,
          });

          return activityData;
        } catch (e, st) {
          AppLogger.error('Firebase Activity 조회 오류', error: e, stackTrace: st);
          return _getDefaultActivity();
        }
      },
      params: {
        'groupId': groupId,
        'userId': PrivacyMaskUtil.maskUserId(userId),
      },
    );
  }

  /// 그룹 Activity 업데이트
  Future<void> updateGroupActivity({
    required String groupId,
    required String userId,
    required ActivityDto activity,
  }) async {
    return ApiCallDecorator.wrap(
      'UserActivityFirebase.updateGroupActivity',
      () async {
        AppLogger.debug('Firebase 그룹 Activity 업데이트: $groupId/$userId');
        AppLogger.logState('Activity 업데이트 요청', {
          'timer_status': activity.timerStatus,
          'current_session_elapsed': activity.currentSessionElapsedSeconds,
          'today_total': activity.todayTotalSeconds,
        });

        try {
          final activityRef = _firestore
              .collection('groups')
              .doc(groupId)
              .collection('members')
              .doc(userId)
              .collection('activity')
              .doc('current');

          final activityData = activity.toJson();
          activityData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          await activityRef.set(activityData, SetOptions(merge: true));

          AppLogger.authInfo('Firebase Activity 업데이트 성공');
        } catch (e, st) {
          AppLogger.error(
            'Firebase Activity 업데이트 오류',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      },
      params: {
        'groupId': groupId,
        'userId': PrivacyMaskUtil.maskUserId(userId),
        'timerStatus': activity.timerStatus,
      },
    );
  }

  /// 그룹 Activity 실시간 스트림
  Stream<Map<String, dynamic>> streamGroupActivity({
    required String groupId,
    required String userId,
  }) {
    AppLogger.debug('Firebase 그룹 Activity 스트림 시작: $groupId/$userId');

    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .collection('activity')
        .doc('current')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            AppLogger.debug('Activity 스트림: 문서 없음 - 기본값 반환');
            return _getDefaultActivity();
          }

          final data = snapshot.data()!;
          AppLogger.debug('Activity 스트림: 새 데이터 수신');
          return data;
        })
        .handleError((error, stackTrace) {
          AppLogger.error(
            'Activity 스트림 에러',
            error: error,
            stackTrace: stackTrace,
          );
          return _getDefaultActivity();
        });
  }

  /// 그룹의 모든 멤버 Activity 스트림
  Stream<List<Map<String, dynamic>>> streamGroupMembersActivities(
    String groupId,
  ) {
    AppLogger.debug('Firebase 그룹 멤버들 Activity 스트림 시작: $groupId');

    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .asyncMap((membersSnapshot) async {
          final memberIds = membersSnapshot.docs.map((doc) => doc.id).toList();

          if (memberIds.isEmpty) {
            AppLogger.debug('그룹에 멤버 없음');
            return <Map<String, dynamic>>[];
          }

          // 각 멤버의 현재 activity 조회
          final activities = await Future.wait(
            memberIds.map((memberId) async {
              final activityData = await fetchGroupActivity(
                groupId: groupId,
                userId: memberId,
              );

              // 멤버 정보 추가
              if (activityData != null) {
                activityData['userId'] = memberId;
                // 멤버 기본 정보는 members 컬렉션에서 가져오기
                final memberDoc = membersSnapshot.docs.firstWhere(
                  (doc) => doc.id == memberId,
                );
                final memberData = memberDoc.data();
                activityData['userName'] = memberData['userName'] ?? '';
                activityData['profileUrl'] = memberData['profileUrl'] ?? '';
              }

              return activityData;
            }),
          );

          // null이 아닌 활동만 필터링
          final validActivities =
              activities.whereType<Map<String, dynamic>>().toList();

          AppLogger.debug(
            '그룹 멤버 Activity 스트림: ${validActivities.length}명의 활동 데이터',
          );
          return validActivities;
        });
  }

  /// 월별 통계 조회
  Future<Map<String, dynamic>?> fetchMonthlyStats({
    required String groupId,
    required String yearMonth, // "YYYY-MM" 형식
  }) async {
    return ApiCallDecorator.wrap(
      'UserActivityFirebase.fetchMonthlyStats',
      () async {
        AppLogger.debug('Firebase 월별 통계 조회: $groupId/$yearMonth');

        try {
          final statsDoc =
              await _firestore
                  .collection('groups')
                  .doc(groupId)
                  .collection('monthlyStats')
                  .doc(yearMonth)
                  .get();

          if (!statsDoc.exists) {
            AppLogger.debug('월별 통계 문서 없음');
            return null;
          }

          final statsData = statsDoc.data()!;

          AppLogger.authInfo('Firebase 월별 통계 조회 성공');
          AppLogger.logState('월별 통계 정보', {
            'group_id': groupId,
            'year_month': yearMonth,
            'days_count': statsData.keys.length,
          });

          return statsData;
        } catch (e, st) {
          AppLogger.error('Firebase 월별 통계 조회 오류', error: e, stackTrace: st);
          return null;
        }
      },
      params: {'groupId': groupId, 'yearMonth': yearMonth},
    );
  }

  /// 기본 Summary 데이터
  Map<String, dynamic> _getDefaultSummary() {
    return {
      'allTimeTotalSeconds': 0,
      'groupTotalSecondsMap': <String, int>{},
      'last7DaysActivityMap': <String, int>{},
      'currentStreakDays': 0,
      'lastActivityDate': null,
      'longestStreakDays': 0,
    };
  }

  /// 기본 Activity 데이터
  Map<String, dynamic> _getDefaultActivity() {
    return {
      'timerStatus': 'end',
      'sessionStartedAt': null,
      'lastUpdatedAt': null,
      'currentSessionElapsedSeconds': 0,
      'todayTotalSeconds': 0,
      'dailyDurationsMap': <String, int>{},
      'allTimeTotalSeconds': 0,
    };
  }

  /// 타이머 활동 기록 마이그레이션 헬퍼 (임시)
  /// 기존 timerActivities 서브컬렉션 데이터를 새 구조로 변환
  Future<void> migrateTimerActivities({
    required String userId,
    required String groupId,
  }) async {
    AppLogger.logBanner('타이머 활동 마이그레이션 시작');

    try {
      // 1. 기존 timerActivities 조회
      final oldActivities =
          await _usersCollection
              .doc(userId)
              .collection('timerActivities')
              .orderBy('timestamp', descending: true)
              .get();

      if (oldActivities.docs.isEmpty) {
        AppLogger.info('마이그레이션할 활동 없음');
        return;
      }

      AppLogger.info('${oldActivities.docs.length}개의 활동 발견');

      // 2. 활동을 날짜별로 그룹화하고 시간 계산
      final Map<String, int> dailyDurations = {};
      int totalSeconds = 0;

      // 여기에 start/end 매칭 로직 구현
      // (기존 FocusStatsCalculator 로직 참고)

      // 3. 새 Activity 문서 생성
      final newActivity = ActivityDto(
        timerStatus: 'end',
        sessionStartedAt: null,
        lastUpdatedAt: DateTime.now(),
        currentSessionElapsedSeconds: 0,
        todayTotalSeconds: 0,
        dailyDurationsMap: dailyDurations,
        allTimeTotalSeconds: totalSeconds,
      );

      // 4. 그룹 Activity 업데이트
      await updateGroupActivity(
        groupId: groupId,
        userId: userId,
        activity: newActivity,
      );

      // 5. Summary 업데이트
      final newSummary = SummaryDto(
        allTimeTotalSeconds: totalSeconds,
        groupTotalSecondsMap: {groupId: totalSeconds},
        last7DaysActivityMap: {}, // 계산 필요
        currentStreakDays: 0, // 계산 필요
        lastActivityDate: null, // 계산 필요
        longestStreakDays: 0, // 계산 필요
      );

      await updateUserSummary(userId: userId, summary: newSummary);

      AppLogger.logBox('마이그레이션 완료', '총 ${totalSeconds ~/ 60}분의 활동 기록 이전됨');
    } catch (e, st) {
      AppLogger.error('마이그레이션 실패', error: e, stackTrace: st);
      rethrow;
    }
  }
}
