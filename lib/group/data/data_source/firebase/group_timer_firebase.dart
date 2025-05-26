// lib/group/data/data_source/firebase/group_timer_firebase.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// 그룹 타이머 기능 (타이머 제어, 실시간 상태, 출석 데이터)
///
/// 새로운 구조:
/// - 멤버 문서에 타이머 상태 직접 통합
/// - 멤버 문서의 타이머 필드: timerState, timerStartAt, timerElapsed 등
/// - 월별 통계 자동 업데이트
class GroupTimerFirebase {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // 캐싱을 위한 변수들
  String? _currentUserId;
  Map<String, DocumentReference<Map<String, dynamic>>> _memberDocRefs = {};
  Map<String, Map<String, dynamic>?> _cachedGroupDocs = {};

  GroupTimerFirebase({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth {
    // 인증 상태 변경 감지하여 캐시 클리어
    _auth.authStateChanges().listen((user) {
      if (_currentUserId != user?.uid) {
        _clearCaches();
        _currentUserId = user?.uid;
      }
    });
  }

  // 캐시 초기화 메서드
  void _clearCaches() {
    _memberDocRefs.clear();
    _cachedGroupDocs.clear();
    AppLogger.debug(
      '타이머 관련 캐시가 초기화되었습니다',
      tag: 'GroupTimerFirebase',
    );
  }

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  /// 현재 사용자 정보 가져오기 헬퍼 메서드 (캐싱 적용)
  Future<Map<String, String>> _getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }

    final userId = user.uid;
    _currentUserId = userId; // 캐시 업데이트
    final userName = user.displayName ?? '';
    final profileUrl = user.photoURL ?? '';

    return {
      'userId': userId,
      'userName': userName,
      'profileUrl': profileUrl,
    };
  }

  /// 멤버 문서 참조 가져오기 헬퍼 메서드 (캐싱 적용)
  Future<DocumentReference<Map<String, dynamic>>> _getMemberDocRef(
    String groupId,
    String userId,
  ) async {
    final cacheKey = '$groupId:$userId';

    if (!_memberDocRefs.containsKey(cacheKey)) {
      // 캐시에 없으면 새 참조 생성 및 캐싱
      final memberDocRef = _groupsCollection
          .doc(groupId)
          .collection('members')
          .doc(userId);

      _memberDocRefs[cacheKey] = memberDocRef;
    }

    return _memberDocRefs[cacheKey]!;
  }

  /// 그룹 문서 가져오기 헬퍼 메서드 (캐싱 적용)
  Future<Map<String, dynamic>?> _getGroupDoc(String groupId) async {
    // 캐시 확인
    if (_cachedGroupDocs.containsKey(groupId)) {
      return _cachedGroupDocs[groupId];
    }

    // 그룹 문서 조회
    final groupDoc = await _groupsCollection.doc(groupId).get();

    if (!groupDoc.exists) {
      _cachedGroupDocs[groupId] = null;
      return null;
    }

    final data = groupDoc.data();
    _cachedGroupDocs[groupId] = data;

    return data;
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
    final targetDate = date ?? TimeFormatter.nowInSeoul();
    return DateFormat('yyyy-MM-dd').format(targetDate);
  }

  /// 실시간 그룹 멤버 타이머 상태 스트림
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    // 멤버 컬렉션 변경 감지 스트림
    return _groupsCollection.doc(groupId).collection('members').snapshots().map(
      (snapshot) {
        // 멤버 문서들을 바로 반환 (필드에 타이머 상태가 포함됨)
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          // 멤버 문서가 바로 DTO로 사용됨 (timerState 등의 필드 포함)
          return {'memberDto': data};
        }).toList();
      },
    );
  }

  /// 그룹의 모든 타이머 활동 조회 - 멤버 문서 기반
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(
    String groupId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.fetchGroupTimerActivities',
      () async {
        try {
          // 그룹 존재 확인
          final groupData = await _getGroupDoc(groupId);
          if (groupData == null) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 그룹 멤버 목록 조회
          final membersSnapshot =
              await _groupsCollection.doc(groupId).collection('members').get();

          // 각 멤버의 타이머 상태 정보 추출
          final activities = <Map<String, dynamic>>[];

          for (final memberDoc in membersSnapshot.docs) {
            final memberData = memberDoc.data();
            final userId = memberData['userId'] as String?;
            if (userId == null) continue;

            // 타이머 관련 필드가 있는 경우만 활동 정보로 추가
            if (memberData.containsKey('timerState')) {
              activities.add(memberData);
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
          final groupData = await _getGroupDoc(groupId);
          if (groupData == null) {
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

  /// 타이머 활동 기록 - 멤버 문서 직접 업데이트
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

          // 그룹 존재 확인
          final groupData = await _getGroupDoc(groupId);
          if (groupData == null) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 날짜 키 - 타임스탬프 기준
          final dateKey = _getDateKey(timestamp);

          // 멤버 문서 참조 가져오기
          final memberDocRef = await _getMemberDocRef(groupId, userId);

          // 활동 타입에 따른 처리
          switch (activityType) {
            case TimerActivityType.start:
              return _handleTimerStart(memberDocRef, timestamp, dateKey);
            case TimerActivityType.pause:
              return _handleTimerPause(
                memberDocRef,
                timestamp,
                dateKey,
                groupData,
              );
            case TimerActivityType.resume:
              return _handleTimerResume(memberDocRef, timestamp, dateKey);
            case TimerActivityType.end:
              return _handleTimerEnd(
                groupId,
                userId,
                memberDocRef,
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

  /// 타이머 시작 처리 - 멤버 문서 직접 업데이트
  Future<Map<String, dynamic>> _handleTimerStart(
    DocumentReference<Map<String, dynamic>> memberDocRef,
    DateTime timestamp,
    String dateKey,
  ) async {
    // 현재 멤버 상태 확인
    final memberDoc = await memberDocRef.get();

    // 멤버 문서가 존재하는지 확인
    if (!memberDoc.exists) {
      throw Exception(GroupErrorMessages.notMember);
    }

    final memberData = memberDoc.data() ?? {};
    final timerState =
        memberData['timerState'] as String? ??
        TimerActivityType.end.toTimerStateString();

    // 이미 활성화된 타이머가 있는지 확인
    if (timerState == TimerActivityType.start.toTimerStateString() ||
        timerState == TimerActivityType.resume.toTimerStateString()) {
      throw Exception(GroupErrorMessages.timerAlreadyRunning);
    }

    // 타이머 필드 업데이트
    await memberDocRef.update({
      'timerState': TimerActivityType.start.toTimerStateString(),
      'timerStartAt': Timestamp.fromDate(timestamp),
      'timerLastUpdatedAt': Timestamp.fromDate(timestamp),
      'timerElapsed': 0, // 새 세션 시작 시 경과 시간 초기화
      'timerTodayDuration': memberData['timerTodayDuration'] ?? 0,
      'timerMonthlyDurations':
          memberData['timerMonthlyDurations'] ?? {dateKey: 0},
      'timerTotalDuration': memberData['timerTotalDuration'] ?? 0,
    });

    // 업데이트된 문서 반환
    final updatedDoc = await memberDocRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타이머 일시정지 처리 - 멤버 문서 직접 업데이트
  Future<Map<String, dynamic>> _handleTimerPause(
    DocumentReference<Map<String, dynamic>> memberDocRef,
    DateTime timestamp,
    String dateKey,
    Map<String, dynamic> groupData,
  ) async {
    // 현재 멤버 상태 확인
    final memberDoc = await memberDocRef.get();
    if (!memberDoc.exists) {
      throw Exception(GroupErrorMessages.notMember);
    }

    final memberData = memberDoc.data() ?? {};
    final timerState =
        memberData['timerState'] as String? ??
        TimerActivityType.end.toTimerStateString();

    // 타이머가 실행 중인지 확인
    if (timerState != TimerActivityType.start.toTimerStateString() &&
        timerState != TimerActivityType.resume.toTimerStateString()) {
      throw Exception(GroupErrorMessages.timerNotRunning);
    }

    // 시작 시간
    final timerStartAt = (memberData['timerStartAt'] as Timestamp?)?.toDate();
    if (timerStartAt == null) {
      throw Exception(GroupErrorMessages.invalidTimerState);
    }

    // 경과 시간 계산
    final elapsedSeconds = timestamp.difference(timerStartAt).inSeconds;
    final previousElapsed = memberData['timerElapsed'] as int? ?? 0;
    final totalElapsed = previousElapsed + elapsedSeconds;

    // 오늘 누적 시간 업데이트
    final todayDuration = memberData['timerTodayDuration'] as int? ?? 0;
    final newTodayDuration = todayDuration + elapsedSeconds;

    // 월별 누적 시간 업데이트
    final Map<String, dynamic> monthlyDurations = Map<String, dynamic>.from(
      memberData['timerMonthlyDurations'] as Map<dynamic, dynamic>? ?? {},
    );
    final dateSeconds = monthlyDurations[dateKey] as int? ?? 0;
    monthlyDurations[dateKey] = dateSeconds + elapsedSeconds;

    // 전체 누적 시간 업데이트
    final totalDuration = memberData['timerTotalDuration'] as int? ?? 0;
    final newTotalDuration = totalDuration + elapsedSeconds;

    // 일시정지 제한 시간 설정
    final raw = groupData['pauseTimeLimit'] as int? ?? 120;

    // 1~720분 사이로 보정 (1분~12시간)
    final pauseTimeLimit = raw.clamp(1, 720);

    if (raw != pauseTimeLimit) {
      AppLogger.warning(
        'pauseTimeLimit 값($raw)이 허용 범위를 벗어나 $pauseTimeLimit으로 보정되었습니다.',
        tag: 'GroupTimerFirebase',
      );
    }

    // 일시정지 만료 시간 계산
    final pauseExpiryTime = timestamp.add(Duration(minutes: pauseTimeLimit));

    AppLogger.debug(
      '일시정지 제한 시간 설정: $pauseTimeLimit분, 만료 시간: $pauseExpiryTime',
      tag: 'GroupTimerFirebase',
    );

    // 타이머 필드 업데이트
    await memberDocRef.update({
      'timerState': TimerActivityType.pause.toTimerStateString(),
      'timerStartAt': null, // 타이머 정지 시 시작 시간 제거
      'timerLastUpdatedAt': Timestamp.fromDate(timestamp),
      'timerElapsed': totalElapsed,
      'timerTodayDuration': newTodayDuration,
      'timerMonthlyDurations': monthlyDurations,
      'timerTotalDuration': newTotalDuration,
      'timerPauseExpiryTime': Timestamp.fromDate(
        pauseExpiryTime,
      ), // 일시정지 만료 시간 추가
    });

    // 업데이트된 문서 반환
    final updatedDoc = await memberDocRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타이머 재개 처리 - 멤버 문서 직접 업데이트
  Future<Map<String, dynamic>> _handleTimerResume(
    DocumentReference<Map<String, dynamic>> memberDocRef,
    DateTime timestamp,
    String dateKey,
  ) async {
    // 현재 멤버 상태 확인
    final memberDoc = await memberDocRef.get();
    if (!memberDoc.exists) {
      throw Exception(GroupErrorMessages.notMember);
    }

    final memberData = memberDoc.data() ?? {};
    final timerState =
        memberData['timerState'] as String? ??
        TimerActivityType.end.toTimerStateString();

    // 타이머가 일시정지 상태인지 확인
    if (timerState != TimerActivityType.pause.toTimerStateString()) {
      throw Exception(GroupErrorMessages.timerNotPaused);
    }

    // 일시정지 만료 시간 확인
    final pauseExpiryTime =
        (memberData['timerPauseExpiryTime'] as Timestamp?)?.toDate();
    if (pauseExpiryTime != null && timestamp.isAfter(pauseExpiryTime)) {
      // 만료 시간이 지났으면 단순히 상태만 'end'로 변경
      AppLogger.info(
        '일시정지 제한 시간 초과 감지: 재개 대신 종료 처리함',
        tag: 'GroupTimerFirebase',
      );

      await memberDocRef.update({
        'timerState': TimerActivityType.end.toTimerStateString(),
        'timerPauseExpiryTime': FieldValue.delete(),
      });

      // 업데이트된 문서 반환
      final updatedDoc = await memberDocRef.get();
      return updatedDoc.data() ?? {};
    }

    // 일시정지 만료되지 않았으면 정상적으로 재개
    await memberDocRef.update({
      'timerState': TimerActivityType.resume.toTimerStateString(),
      'timerStartAt': Timestamp.fromDate(timestamp), // 새로운 시작 시간
      'timerLastUpdatedAt': Timestamp.fromDate(timestamp),
      'timerPauseExpiryTime': FieldValue.delete(), // 만료 시간 필드 제거
    });

    // 업데이트된 문서 반환
    final updatedDoc = await memberDocRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 타이머 종료 처리 - 멤버 문서 직접 업데이트
  Future<Map<String, dynamic>> _handleTimerEnd(
    String groupId,
    String userId,
    DocumentReference<Map<String, dynamic>> memberDocRef,
    DateTime timestamp,
    String dateKey,
  ) async {
    // 현재 멤버 상태 확인
    final memberDoc = await memberDocRef.get();
    if (!memberDoc.exists) {
      throw Exception(GroupErrorMessages.notMember);
    }

    final memberData = memberDoc.data() ?? {};
    final timerState =
        memberData['timerState'] as String? ??
        TimerActivityType.end.toTimerStateString();

    int elapsedSeconds = 0;

    // 활성 상태인 경우 경과 시간 계산
    if (timerState == TimerActivityType.start.toTimerStateString() ||
        timerState == TimerActivityType.resume.toTimerStateString()) {
      final timerStartAt = (memberData['timerStartAt'] as Timestamp?)?.toDate();
      if (timerStartAt != null) {
        elapsedSeconds = timestamp.difference(timerStartAt).inSeconds;
      }
    }

    // 오늘 누적 시간 업데이트
    final todayDuration = memberData['timerTodayDuration'] as int? ?? 0;
    final newTodayDuration = todayDuration + elapsedSeconds;

    // 월별 누적 시간 업데이트
    final Map<String, dynamic> monthlyDurations = Map<String, dynamic>.from(
      memberData['timerMonthlyDurations'] as Map<dynamic, dynamic>? ?? {},
    );
    final dateSeconds = monthlyDurations[dateKey] as int? ?? 0;
    monthlyDurations[dateKey] = dateSeconds + elapsedSeconds;

    // 전체 누적 시간 업데이트
    final totalDuration = memberData['timerTotalDuration'] as int? ?? 0;
    final newTotalDuration = totalDuration + elapsedSeconds;

    // 타이머 필드 업데이트
    await memberDocRef.update({
      'timerState': TimerActivityType.end.toTimerStateString(),
      'timerStartAt': null,
      'timerLastUpdatedAt': Timestamp.fromDate(timestamp),
      'timerElapsed': 0, // 종료 시 경과 시간 초기화
      'timerTodayDuration': newTodayDuration,
      'timerMonthlyDurations': monthlyDurations,
      'timerTotalDuration': newTotalDuration,
      'timerPauseExpiryTime': FieldValue.delete(), // 일시정지 만료 시간 필드 제거
    });

    // 월별 통계 업데이트
    if (elapsedSeconds > 0) {
      await _updateMonthlyStats(
        groupId,
        userId,
        timestamp.year,
        timestamp.month,
        dateKey,
        elapsedSeconds,
      );
    }

    // 업데이트된 문서 반환
    final updatedDoc = await memberDocRef.get();
    return updatedDoc.data() ?? {};
  }

  /// 월별 통계 업데이트 헬퍼 메서드
  Future<void> _updateMonthlyStats(
    String groupId,
    String userId,
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

  // === 간편 인터페이스 메서드: 현재 시간 기준 ===

  /// 타이머 시작 - 현재 시간(호출 시점)으로 기록
  ///
  /// 일반적인 사용자 UI 액션에 적합합니다.
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.start,
      TimeFormatter.nowInSeoul(),
    );
  }

  /// 타이머 일시정지 - 현재 시간(호출 시점)으로 기록
  ///
  /// 일반적인 사용자 UI 액션에 적합합니다.
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.pause,
      TimeFormatter.nowInSeoul(),
    );
  }

  /// 타이머 재개 - 현재 시간(호출 시점)으로 기록
  ///
  /// 일반적인 사용자 UI 액션에 적합합니다.
  Future<Map<String, dynamic>> resumeMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.resume,
      TimeFormatter.nowInSeoul(),
    );
  }

  /// 타이머 종료 - 현재 시간(호출 시점)으로 기록
  ///
  /// 일반적인 사용자 UI 액션에 적합합니다.
  Future<Map<String, dynamic>> stopMemberTimer(String groupId) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.end,
      TimeFormatter.nowInSeoul(),
    );
  }

  // === 고급 인터페이스 메서드: 지정 시간 기준 ===

  /// 타이머 시작 - 지정된 시간으로 기록
  ///
  /// 자동화된 프로세스나 배치 작업 등에 적합합니다.
  /// 예: 특정 시점의 상태 복원, 자정 시간 처리 등
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

  /// 타이머 일시정지 - 지정된 시간으로 기록
  ///
  /// 자동화된 프로세스나 배치 작업 등에 적합합니다.
  /// 예: 특정 시점의 상태 복원, 자정 시간 처리 등
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

  /// 타이머 재개 - 지정된 시간으로 기록
  ///
  /// 자동화된 프로세스나 배치 작업 등에 적합합니다.
  /// 예: 특정 시점의 상태 복원, 자정 시간 처리 등
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

  /// 타이머 종료 - 지정된 시간으로 기록
  ///
  /// 자동화된 프로세스나 배치 작업 등에 적합합니다.
  /// 예: 특정 시점의 상태 복원, 자정 시간 처리 등
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
