// lib/group/data/data_source/firebase/group_timer_firebase.dart
// 기존 코드에서 다음 메서드들을 수정/추가합니다

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:devlink_mobile_app/group/data/dto/group_member_activity_dto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// 그룹 타이머 기능 (타이머 제어, 실시간 상태, 출석 데이터)
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

    return {
      'userId': userId,
      'userName': userName,
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

  /// 오늘 날짜 키 가져오기 헬퍼 메서드
  String _getTodayDateKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// 멤버 활동 정보 가져오기
  Future<GroupMemberActivityDto?> _getMemberActivity(
    String groupId,
    String userId,
  ) async {
    try {
      final activityRef = _getMemberActivityRef(groupId, userId);
      final activityDoc = await activityRef.get();

      if (!activityDoc.exists) {
        return null;
      }

      return GroupMemberActivityDto.fromJson(activityDoc.data() ?? {});
    } catch (e) {
      AppLogger.error(
        '멤버 활동 정보 조회 오류',
        tag: 'GroupTimerFirebase',
        error: e,
      );
      return null;
    }
  }

  /// 실시간 그룹 멤버 타이머 상태 스트림
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    // 멤버 컬렉션 스트림
    final membersStream =
        _groupsCollection.doc(groupId).collection('members').snapshots();

    // StreamController를 사용하여 멤버 정보와 활동 정보를 결합
    late StreamController<List<Map<String, dynamic>>> controller;
    late StreamSubscription membersSub;

    void handleMembersUpdate(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) async {
      try {
        // 멤버 목록 추출
        final members =
            snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

        if (members.isEmpty) {
          controller.add([]);
          return;
        }

        // 각 멤버의 활동 정보 조회
        final result = <Map<String, dynamic>>[];

        for (final member in members) {
          final userId = member['userId'] as String?;
          if (userId == null) continue;

          // 멤버 활동 정보 조회
          final activityRef = _getMemberActivityRef(groupId, userId);
          final activityDoc = await activityRef.get();
          final activityData = activityDoc.exists ? activityDoc.data() : null;

          // 결과 결합
          result.add({
            'memberDto': member,
            'activityDto': activityData,
          });
        }

        controller.add(result);
      } catch (e) {
        AppLogger.error(
          '그룹 멤버 타이머 상태 스트림 오류',
          tag: 'GroupTimerFirebase',
          error: e,
        );
        controller.addError(e);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        // 멤버 목록이 변경될 때마다 활동 정보 업데이트
        membersSub = membersStream.listen(handleMembersUpdate);
      },
      onCancel: () {
        membersSub.cancel();
      },
    );

    return controller.stream;
  }

  /// 멤버 타이머 시작
  /// 멤버 타이머 시작
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      'start',
      DateTime.now(),
    );
  }

  /// 멤버 타이머 일시정지
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      'pause',
      DateTime.now(),
    );
  }

  /// 멤버 타이머 재개
  Future<Map<String, dynamic>> resumeMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      'resume',
      DateTime.now(),
    );
  }

  /// 멤버 타이머 종료
  Future<Map<String, dynamic>> stopMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      'end',
      DateTime.now(),
    );
  }

  /// 월별 통계 문서 업데이트 헬퍼 메서드
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

          // 모든 조회 대상 월 범위 계산
          final months = <DateTime>[];
          for (int i = 0; i <= preloadMonths; i++) {
            months.add(DateTime(year, month - i, 1));
          }

          // 모든 월별 통계 문서 병렬 조회
          final futures = months.map((date) async {
            final statsRef = _getMonthlyStatsRef(
              groupId,
              date.year,
              date.month,
            );
            final statsDoc = await statsRef.get();

            if (!statsDoc.exists) {
              return <Map<String, dynamic>>[];
            }

            final statsData = statsDoc.data() ?? {};
            final attendances = <Map<String, dynamic>>[];

            // 각 날짜별 데이터 추출
            statsData.forEach((dateKey, dateData) {
              if (dateData is! Map<String, dynamic>) return;

              final membersData =
                  dateData['members'] as Map<dynamic, dynamic>? ?? {};

              // 각 멤버별 출석 데이터 생성
              membersData.forEach((memberId, duration) {
                if (duration is! int) return;

                attendances.add({
                  'groupId': groupId,
                  'userId': memberId,
                  'date': dateKey,
                  'timeInSeconds': duration,
                });
              });
            });

            return attendances;
          });

          // 모든 월 데이터 통합
          final results = await Future.wait(futures);
          final allAttendances = results.expand((list) => list).toList();

          // 추가 멤버 정보 조회 (필요한 경우)
          // ...

          return allAttendances;
        } catch (e) {
          AppLogger.error(
            '월별 타이머 활동 데이터 조회 오류',
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

  /// 특정 시간으로 타이머 활동 기록 (수동 타임스탬프)
  Future<Map<String, dynamic>> recordTimerActivityWithTimestamp(
    String groupId,
    String activityType,
    DateTime timestamp,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.recordTimerActivityWithTimestamp',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final userId = userInfo['userId']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 멤버 활동 문서 참조
          final activityRef = _getMemberActivityRef(groupId, userId);

          // 날짜 키
          final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);

          Map<String, dynamic> result = {};

          // 활동 타입에 따라 처리
          switch (activityType) {
            case 'start':
              result = await _handleManualStart(
                activityRef,
                timestamp,
                dateKey,
              );
              break;

            case 'pause':
              result = await _handleManualPause(
                activityRef,
                timestamp,
                dateKey,
              );
              break;

            case 'resume':
              result = await _handleManualResume(activityRef, timestamp);
              break;

            case 'end':
              result = await _handleManualEnd(
                groupId,
                userId,
                userInfo['userName']!,
                activityRef,
                timestamp,
                dateKey,
              );
              break;

            default:
              throw Exception('지원하지 않는 활동 타입입니다: $activityType');
          }

          return result;
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
        'activityType': activityType,
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  /// 수동 타이머 시작 처리 헬퍼 메서드
  Future<Map<String, dynamic>> _handleManualStart(
    DocumentReference<Map<String, dynamic>> activityRef,
    DateTime timestamp,
    String dateKey,
  ) async {
    // 기존 활동 정보 확인
    final activityDoc = await activityRef.get();
    Map<String, dynamic> existingData = {};

    if (activityDoc.exists) {
      existingData = activityDoc.data() ?? {};

      // 이미 실행 중인 타이머 확인
      if (existingData['state'] == 'running' ||
          existingData['state'] == 'resume') {
        throw Exception(GroupErrorMessages.timerAlreadyRunning);
      }
    }

    // 새 타이머 활동 데이터 준비
    final activityData = {
      'state': 'running',
      'startAt': Timestamp.fromDate(timestamp),
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
      'elapsed': 0, // 새 세션이므로 경과시간 초기화
    };

    // 기존 문서가 있다면 기존 데이터 유지하면서 업데이트
    if (activityDoc.exists) {
      await activityRef.update(activityData);
    } else {
      // 없으면 기본값과 함께 새로 생성
      await activityRef.set({
        ...activityData,
        'todayDuration': 0,
        'monthlyDurations': {
          dateKey: 0,
        },
        'totalDuration': 0,
      });
    }

    // 현재 문서 다시 읽기
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 수동 타이머 일시정지 처리 헬퍼 메서드
  Future<Map<String, dynamic>> _handleManualPause(
    DocumentReference<Map<String, dynamic>> activityRef,
    DateTime timestamp,
    String dateKey,
  ) async {
    // 기존 활동 정보 확인
    final activityDoc = await activityRef.get();
    if (!activityDoc.exists) {
      throw Exception(GroupErrorMessages.timerNotActive);
    }

    final existingData = activityDoc.data() ?? {};

    // 타이머 실행 중인지 확인
    if (existingData['state'] != 'running' &&
        existingData['state'] != 'resume') {
      throw Exception(GroupErrorMessages.timerNotRunning);
    }

    // 시작 시간
    final startAt = (existingData['startAt'] as Timestamp?)?.toDate();
    if (startAt == null) {
      throw Exception(GroupErrorMessages.invalidTimerState);
    }

    // 기존 경과 시간
    final previousElapsed = existingData['elapsed'] as int? ?? 0;

    // 현재 세션 경과 시간 계산
    final sessionDuration = timestamp.difference(startAt).inSeconds;
    final totalElapsed = previousElapsed + sessionDuration;

    // 오늘 누적 시간 업데이트
    final todayDuration = existingData['todayDuration'] as int? ?? 0;
    final newTodayDuration = todayDuration + sessionDuration;

    // 월별 누적 시간 업데이트
    final monthlyDurations = Map<String, dynamic>.from(
      existingData['monthlyDurations'] as Map<dynamic, dynamic>? ?? {},
    );
    final todayMinutes = monthlyDurations[dateKey] as int? ?? 0;
    monthlyDurations[dateKey] = todayMinutes + sessionDuration;

    // 전체 누적 시간 업데이트
    final totalDuration = existingData['totalDuration'] as int? ?? 0;
    final newTotalDuration = totalDuration + sessionDuration;

    // 타이머 일시정지 데이터
    final updateData = {
      'state': 'paused',
      'startAt': null, // 타이머 정지 시 시작 시간 제거
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
      'elapsed': totalElapsed,
      'todayDuration': newTodayDuration,
      'monthlyDurations': monthlyDurations,
      'totalDuration': newTotalDuration,
    };

    // 문서 업데이트
    await activityRef.update(updateData);

    // 현재 문서 다시 읽기
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 수동 타이머 재개 처리 헬퍼 메서드
  Future<Map<String, dynamic>> _handleManualResume(
    DocumentReference<Map<String, dynamic>> activityRef,
    DateTime timestamp,
  ) async {
    // 기존 활동 정보 확인
    final activityDoc = await activityRef.get();
    if (!activityDoc.exists) {
      throw Exception(GroupErrorMessages.timerNotActive);
    }

    final existingData = activityDoc.data() ?? {};

    // 타이머가 일시정지 상태인지 확인
    if (existingData['state'] != 'paused') {
      throw Exception(GroupErrorMessages.timerNotPaused);
    }

    // 타이머 재개 데이터
    final updateData = {
      'state': 'resume',
      'startAt': Timestamp.fromDate(timestamp), // 새로운 시작 시간
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
      // elapsed, todayDuration, monthlyDurations는 유지
    };

    // 문서 업데이트
    await activityRef.update(updateData);

    // 현재 문서 다시 읽기
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 수동 타이머 종료 처리 헬퍼 메서드
  Future<Map<String, dynamic>> _handleManualEnd(
    String groupId,
    String userId,
    String userName,
    DocumentReference<Map<String, dynamic>> activityRef,
    DateTime timestamp,
    String dateKey,
  ) async {
    // 기존 활동 정보 확인
    final activityDoc = await activityRef.get();
    if (!activityDoc.exists) {
      throw Exception(GroupErrorMessages.timerNotActive);
    }

    final existingData = activityDoc.data() ?? {};

    // 타이머 상태 확인
    final state = existingData['state'] as String? ?? '';

    int sessionDuration = 0;

    // 실행 중인 타이머는 경과 시간 계산이 필요
    if (state == 'running' || state == 'resume') {
      // 시작 시간
      final startAt = (existingData['startAt'] as Timestamp?)?.toDate();
      if (startAt == null) {
        throw Exception(GroupErrorMessages.invalidTimerState);
      }

      // 기존 경과 시간
      final previousElapsed = existingData['elapsed'] as int? ?? 0;

      // 현재 세션 경과 시간 계산
      sessionDuration = timestamp.difference(startAt).inSeconds;

      // 기존 경과 시간에 추가
      final totalElapsed = previousElapsed + sessionDuration;
      existingData['elapsed'] = totalElapsed;
    }

    // 오늘 누적 시간 업데이트
    final todayDuration = existingData['todayDuration'] as int? ?? 0;
    final newTodayDuration = todayDuration + sessionDuration;

    // 월별 누적 시간 업데이트
    final monthlyDurations = Map<String, dynamic>.from(
      existingData['monthlyDurations'] as Map<dynamic, dynamic>? ?? {},
    );
    final todayMinutes = monthlyDurations[dateKey] as int? ?? 0;
    monthlyDurations[dateKey] = todayMinutes + sessionDuration;

    // 전체 누적 시간 업데이트
    final totalDuration = existingData['totalDuration'] as int? ?? 0;
    final newTotalDuration = totalDuration + sessionDuration;

    // 타이머 종료 데이터
    final updateData = {
      'state': 'idle',
      'startAt': null,
      'lastUpdatedAt': Timestamp.fromDate(timestamp),
      'elapsed': 0, // 종료 시 경과 시간 초기화
      'todayDuration': newTodayDuration,
      'monthlyDurations': monthlyDurations,
      'totalDuration': newTotalDuration,
    };

    // 문서 업데이트
    await activityRef.update(updateData);

    // 월별 통계 문서 업데이트
    await _updateMonthlyStats(
      groupId,
      userId,
      userName,
      timestamp.year,
      timestamp.month,
      dateKey,
      sessionDuration,
    );

    // 현재 문서 다시 읽기
    final updatedDoc = await activityRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타임스탬프 지정 가능한 타이머 제어 메서드들
  Future<Map<String, dynamic>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'start', timestamp);
  }

  Future<Map<String, dynamic>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'pause', timestamp);
  }

  Future<Map<String, dynamic>> resumeMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'resume', timestamp);
  }

  Future<Map<String, dynamic>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'end', timestamp);
  }
}
