// lib/group/data/data_source/firebase/group_timer_firebase.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// 그룹 타이머 기능 (타이머 제어, 실시간 상태, 출석 데이터)
///
/// 상태 기반 구조:
/// - 개별 이벤트 대신 멤버별 단일 상태 문서 사용 (`activity/current`)
/// - 타이머 상태: running, paused, idle
/// - 월별 통계 자동 업데이트
class GroupTimerFirebase {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupTimerFirebase({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  //TODO: 언젠간 사용할 것 같은데....
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 현재 사용자 정보 가져오기 헬퍼 메서드
  Future<Map<String, String>> _getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }

    final userId = user.uid;
    final userName = user.displayName ?? '';
    final profileUrl = user.photoURL ?? '';

    return {
      'userId': userId,
      'userName': userName,
      'profileUrl': profileUrl,
    };
  }

  /// 멤버 활동 문서 참조 가져오기 헬퍼 메서드
  DocumentReference<Map<String, dynamic>> _getMemberActivityRef(
    String groupId,
    String userId,
  ) {
    return _groupsCollection
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .collection('activity')
        .doc('current');
  }

  /// 월별 통계 문서 참조 가져오기 헬퍼 메서드
  DocumentReference<Map<String, dynamic>> _getMonthlyStatsRef(
    String groupId,
    int year,
    int month,
  ) {
    final monthKey = DateFormat('yyyy-MM').format(DateTime(year, month));
    return _groupsCollection
        .doc(groupId)
        .collection('monthlyStats')
        .doc(monthKey);
  }

  /// 날짜 키 가져오기 헬퍼 메서드
  String _getDateKey([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(targetDate);
  }

  /// 실시간 그룹 멤버 타이머 상태 스트림
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    // 멤버 컬렉션 변경 감지 스트림
    final membersStream =
        _groupsCollection.doc(groupId).collection('members').snapshots();

    // 각 멤버의 activity 문서 변경 감지를 위한 StreamTransformer
    return membersStream.asyncMap((snapshot) async {
      try {
        // 멤버 목록 추출
        final members =
            snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

        if (members.isEmpty) {
          return [];
        }

        // 각 멤버의 활동 정보 조회
        final results = <Map<String, dynamic>>[];

        for (final member in members) {
          final userId = member['userId'] as String?;
          if (userId == null) continue;

          // 멤버 활동 정보 조회
          final activityRef = _getMemberActivityRef(groupId, userId);
          final activityDoc = await activityRef.get();

          // 활동 문서가 없으면 기본 정보만 포함
          final memberDto = {
            'memberDto': member,
          };

          // 활동 문서가 있으면 타이머 정보 추가
          if (activityDoc.exists) {
            final activityData = activityDoc.data() ?? {};
            memberDto['timerActivityDto'] = activityData;
          }

          results.add(memberDto);
        }

        return results;
      } catch (e) {
        AppLogger.error(
          '실시간 멤버 타이머 상태 조회 오류',
          tag: 'GroupTimerFirebase',
          error: e,
        );
        return [];
      }
    });
  }

  /// 그룹의 모든 타이머 활동 조회 - 멤버별 activity 문서 기반
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(
    String groupId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.fetchGroupTimerActivities',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 그룹 멤버 목록 조회
          final membersSnapshot =
              await _groupsCollection.doc(groupId).collection('members').get();

          // 각 멤버의 활동 정보 조회
          final activities = <Map<String, dynamic>>[];

          for (final memberDoc in membersSnapshot.docs) {
            final memberData = memberDoc.data();
            final userId = memberData['userId'] as String?;
            if (userId == null) continue;

            // 멤버 활동 정보 조회
            final activityRef = _getMemberActivityRef(groupId, userId);
            final activityDoc = await activityRef.get();

            if (activityDoc.exists) {
              final activityData = activityDoc.data() ?? {};

              // 필요한 정보 조합
              final result = {
                'userId': userId,
                'userName': memberData['userName'] ?? '',
                'profileUrl': memberData['profileUrl'],
                'groupId': groupId,
                ...activityData,
              };

              activities.add(result);
            }
          }

          return activities;
        } catch (e) {
          AppLogger.error(
            '그룹 타이머 활동 조회 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
    );
  }

  /// 월별 출석 데이터 조회
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month, {
    int preloadMonths = 0,
  }) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.fetchMonthlyAttendances',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 요청한 월의 통계 문서 참조
          final statsRef = _getMonthlyStatsRef(groupId, year, month);
          final statsDoc = await statsRef.get();

          // 월간 통계 결과 생성
          final attendances = <Map<String, dynamic>>[];

          if (statsDoc.exists) {
            final statsData = statsDoc.data() ?? {};

            // 날짜별 데이터 처리
            statsData.forEach((dateKey, dateData) {
              if (dateData is! Map<String, dynamic>) return;

              final membersData =
                  dateData['members'] as Map<dynamic, dynamic>? ?? {};

              // 각 멤버별 출석 데이터 생성
              membersData.forEach((userId, durationInSeconds) {
                if (durationInSeconds is! int) return;

                // 날짜 문자열을 DateTime으로 변환
                // TODO: 왜 넣은거지? 검토 필요함
                DateTime? date;
                try {
                  date = DateFormat('yyyy-MM-dd').parse(dateKey);
                } catch (e) {
                  return; // 날짜 형식이 올바르지 않으면 건너뜀
                }

                // 출석 데이터 추가
                attendances.add({
                  'groupId': groupId,
                  'userId': userId,
                  'date': dateKey,
                  'timeInSeconds': durationInSeconds,
                });
              });
            });
          }

          return attendances;
        } catch (e) {
          AppLogger.error(
            '월별 출석 데이터 조회 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          if (e.toString().contains(GroupErrorMessages.notFound)) {
            throw Exception(GroupErrorMessages.notFound);
          }
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {
        'groupId': groupId,
        'year': year,
        'month': month,
        'preloadMonths': preloadMonths,
      },
    );
  }

  /// 타이머 활동 기록 (상태 기반) - TimerActivityType enum 사용
  Future<Map<String, dynamic>> recordTimerActivityWithTimestamp(
    String groupId,
    TimerActivityType activityType,
    DateTime timestamp,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.recordTimerActivityWithTimestamp',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final userId = userInfo['userId']!;
          final userName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 날짜 키 - 타임스탬프 기준
          final dateKey = _getDateKey(timestamp);

          // 활동 타입에 따른 처리
          switch (activityType) {
            case TimerActivityType.start:
              return _handleTimerStart(groupId, userId, timestamp, dateKey);
            case TimerActivityType.pause:
              return _handleTimerPause(
                groupId,
                userId,
                userName,
                timestamp,
                dateKey,
              );
            case TimerActivityType.resume:
              return _handleTimerResume(groupId, userId, timestamp, dateKey);
            case TimerActivityType.end:
              return _handleTimerEnd(
                groupId,
                userId,
                userName,
                timestamp,
                dateKey,
              );
          }
        } catch (e) {
          AppLogger.error(
            '타이머 활동 기록 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(e.toString());
        }
      },
      params: {
        'groupId': groupId,
        'activityType': activityType.toStringValue(),
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  /// 타이머 시작 처리
  Future<Map<String, dynamic>> _handleTimerStart(
    String groupId,
    String userId,
    DateTime timestamp,
    String dateKey,
  ) async {
    final activityRef = _getMemberActivityRef(groupId, userId);

    // 현재 활동 상태 확인
    final activityDoc = await activityRef.get();

    // 이미 활성화된 타이머가 있는지 확인
    if (activityDoc.exists) {
      final activityData = activityDoc.data() ?? {};
      final state = activityData['state'] as String? ?? '';

      if (state == 'running' || state == 'resume') {
        throw Exception(GroupErrorMessages.timerAlreadyRunning);
      }

      // 기존 데이터가 있으면 상태만 업데이트
      await activityRef.update({
        'state': 'running',
        'startAt': Timestamp.fromDate(timestamp),
        'lastUpdatedAt': Timestamp.fromDate(timestamp),
        'elapsed': 0, // 새 세션 시작시 경과 시간 초기화
      });
    } else {
      // 활동 문서가 없으면 새로 생성
      await activityRef.set({
        'state': 'running',
        'startAt': Timestamp.fromDate(timestamp),
        'lastUpdatedAt': Timestamp.fromDate(timestamp),
        'elapsed': 0,
        'todayDuration': 0,
        'monthlyDurations': {
          dateKey: 0,
        },
        'totalDuration': 0,
      });
    }

    // 업데이트된 문서 반환
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타이머 일시정지 처리
  Future<Map<String, dynamic>> _handleTimerPause(
    String groupId,
    String userId,
    String userName,
    DateTime timestamp,
    String dateKey,
  ) async {
    final activityRef = _getMemberActivityRef(groupId, userId);

    // 현재 활동 상태 확인
    final activityDoc = await activityRef.get();
    if (!activityDoc.exists) {
      throw Exception(GroupErrorMessages.timerNotActive);
    }

    final activityData = activityDoc.data() ?? {};
    final state = activityData['state'] as String? ?? '';

    // 타이머가 실행 중인지 확인
    if (state != 'running' && state != 'resume') {
      throw Exception(GroupErrorMessages.timerNotRunning);
    }

    // 시작 시간
    final startAt = (activityData['startAt'] as Timestamp?)?.toDate();
    if (startAt == null) {
      throw Exception(GroupErrorMessages.invalidTimerState);
    }

    // 경과 시간 계산
    final elapsedSeconds = timestamp.difference(startAt).inSeconds;
    final previousElapsed = activityData['elapsed'] as int? ?? 0;
    final totalElapsed = previousElapsed + elapsedSeconds;

    // 오늘 누적 시간 업데이트
    final todayDuration = activityData['todayDuration'] as int? ?? 0;
    final newTodayDuration = todayDuration + elapsedSeconds;

    // 월별 누적 시간 업데이트
    final monthlyDurations = Map<String, dynamic>.from(
      activityData['monthlyDurations'] as Map<dynamic, dynamic>? ?? {},
    );
    final dateSeconds = monthlyDurations[dateKey] as int? ?? 0;
    monthlyDurations[dateKey] = dateSeconds + elapsedSeconds;

    // 전체 누적 시간 업데이트
    final totalDuration = activityData['totalDuration'] as int? ?? 0;
    final newTotalDuration = totalDuration + elapsedSeconds;

    // 업데이트 데이터
    await activityRef.update({
      'state': 'paused',
      'startAt': null, // 타이머 정지 시 시작 시간 제거
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
      'elapsed': totalElapsed,
      'todayDuration': newTodayDuration,
      'monthlyDurations': monthlyDurations,
      'totalDuration': newTotalDuration,
    });

    // 업데이트된 문서 반환
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타이머 재개 처리
  Future<Map<String, dynamic>> _handleTimerResume(
    String groupId,
    String userId,
    DateTime timestamp,
    String dateKey,
  ) async {
    final activityRef = _getMemberActivityRef(groupId, userId);

    // 현재 활동 상태 확인
    final activityDoc = await activityRef.get();
    if (!activityDoc.exists) {
      throw Exception(GroupErrorMessages.timerNotActive);
    }

    final activityData = activityDoc.data() ?? {};
    final state = activityData['state'] as String? ?? '';

    // 타이머가 일시정지 상태인지 확인
    if (state != 'paused') {
      throw Exception(GroupErrorMessages.timerNotPaused);
    }

    // 타이머 재개
    await activityRef.update({
      'state': 'resume',
      'startAt': Timestamp.fromDate(timestamp), // 새로운 시작 시간
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
    });

    // 업데이트된 문서 반환
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타이머 종료 처리
  Future<Map<String, dynamic>> _handleTimerEnd(
    String groupId,
    String userId,
    String userName,
    DateTime timestamp,
    String dateKey,
  ) async {
    final activityRef = _getMemberActivityRef(groupId, userId);

    // 현재 활동 상태 확인
    final activityDoc = await activityRef.get();
    if (!activityDoc.exists) {
      throw Exception(GroupErrorMessages.timerNotActive);
    }

    final activityData = activityDoc.data() ?? {};
    final state = activityData['state'] as String? ?? '';

    int elapsedSeconds = 0;

    // 활성 상태인 경우 경과 시간 계산
    if (state == 'running' || state == 'resume') {
      final startAt = (activityData['startAt'] as Timestamp?)?.toDate();
      if (startAt != null) {
        elapsedSeconds = timestamp.difference(startAt).inSeconds;
      }
    }

    // 오늘 누적 시간 업데이트
    final todayDuration = activityData['todayDuration'] as int? ?? 0;
    final newTodayDuration = todayDuration + elapsedSeconds;

    // 월별 누적 시간 업데이트
    final monthlyDurations = Map<String, dynamic>.from(
      activityData['monthlyDurations'] as Map<dynamic, dynamic>? ?? {},
    );
    final dateSeconds = monthlyDurations[dateKey] as int? ?? 0;
    monthlyDurations[dateKey] = dateSeconds + elapsedSeconds;

    // 전체 누적 시간 업데이트
    final totalDuration = activityData['totalDuration'] as int? ?? 0;
    final newTotalDuration = totalDuration + elapsedSeconds;

    // 업데이트 데이터
    await activityRef.update({
      'state': 'idle',
      'startAt': null,
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
      'elapsed': 0, // 종료 시 경과 시간 초기화
      'todayDuration': newTodayDuration,
      'monthlyDurations': monthlyDurations,
      'totalDuration': newTotalDuration,
    });

    // 월별 통계 업데이트
    if (elapsedSeconds > 0) {
      await _updateMonthlyStats(
        groupId,
        userId,
        userName,
        timestamp.year,
        timestamp.month,
        dateKey,
        elapsedSeconds,
      );
    }

    // 업데이트된 문서 반환
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 월별 통계 업데이트 헬퍼 메서드
  Future<void> _updateMonthlyStats(
    String groupId,
    String userId,
    String userName,
    int year,
    int month,
    String dateKey,
    int durationInSeconds,
  ) async {
    try {
      // 월별 통계 문서 참조
      final statsRef = _getMonthlyStatsRef(groupId, year, month);

      // 트랜잭션으로 안전하게 업데이트
      await _firestore.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);

        Map<String, dynamic> statsData = {};
        if (statsDoc.exists) {
          statsData = statsDoc.data() ?? {};
        }

        // 해당 날짜 데이터
        Map<String, dynamic> dateData = Map<String, dynamic>.from(
          statsData[dateKey] as Map<dynamic, dynamic>? ?? {},
        );

        // 멤버 데이터
        Map<String, dynamic> membersData = Map<String, dynamic>.from(
          dateData['members'] as Map<dynamic, dynamic>? ?? {},
        );

        // 기존 누적 시간
        final existingDuration = membersData[userId] as int? ?? 0;

        // 누적 시간 업데이트
        membersData[userId] = existingDuration + durationInSeconds;

        // 데이터 통합
        dateData['members'] = membersData;
        statsData[dateKey] = dateData;

        // 문서 생성 또는 업데이트
        if (statsDoc.exists) {
          transaction.update(statsRef, statsData);
        } else {
          transaction.set(statsRef, statsData);
        }
      });

      AppLogger.debug(
        '월별 통계 업데이트 성공: $year-$month, $dateKey, $userId',
        tag: 'GroupTimerFirebase',
      );
    } catch (e) {
      AppLogger.error(
        '월별 통계 업데이트 오류',
        tag: 'GroupTimerFirebase',
        error: e,
      );
      // 통계 업데이트 실패는 예외를 발생시키지 않고 로그만 남김
    }
  }

  // === 단순화된 인터페이스 메서드들 - TimerActivityType enum 사용 ===

  /// 타이머 시작 - 현재 시간 기준
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.start,
      DateTime.now(),
    );
  }

  /// 타이머 일시정지 - 현재 시간 기준
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.pause,
      DateTime.now(),
    );
  }

  /// 타이머 재개 - 현재 시간 기준
  Future<Map<String, dynamic>> resumeMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.resume,
      DateTime.now(),
    );
  }

  /// 타이머 종료 - 현재 시간 기준
  Future<Map<String, dynamic>> stopMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.end,
      DateTime.now(),
    );
  }

  /// 타이머 시작 - 지정 시간 기준
  Future<Map<String, dynamic>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.start,
      timestamp,
    );
  }

  /// 타이머 일시정지 - 지정 시간 기준
  Future<Map<String, dynamic>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.pause,
      timestamp,
    );
  }

  /// 타이머 재개 - 지정 시간 기준
  Future<Map<String, dynamic>> resumeMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.resume,
      timestamp,
    );
  }

  /// 타이머 종료 - 지정 시간 기준
  Future<Map<String, dynamic>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.end,
      timestamp,
    );
  }
}
