// lib/group/data/data_source/firebase/group_timer_firebase.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// 그룹 멤버별 최신 타이머 활동 조회
  Future<List<String>> _getGroupMemberUserIds(String groupId) async {
    try {
      final membersSnapshot =
          await _groupsCollection.doc(groupId).collection('members').get();

      return membersSnapshot.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((userId) => userId != null)
          .cast<String>()
          .toList();
    } catch (e) {
      AppLogger.error(
        '그룹 멤버 조회 오류',
        tag: 'GroupTimerFirebase',
        error: e,
      );
      return [];
    }
  }

  /// 그룹의 모든 타이머 활동 조회 (최신순, 멤버별 필터링)
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

          // 개선: 멤버별 최신 활동만 효율적으로 조회
          final memberUserIds = await _getGroupMemberUserIds(groupId);

          if (memberUserIds.isEmpty) {
            return [];
          }

          // 멤버별로 최신 1개씩만 병렬 조회
          final futures = memberUserIds.map((userId) async {
            final activitySnapshot =
                await _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

            if (activitySnapshot.docs.isNotEmpty) {
              final doc = activitySnapshot.docs.first;
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }
            return null;
          });

          final results = await Future.wait(futures);

          // null 제거하고 반환
          return results
              .where((data) => data != null)
              .cast<Map<String, dynamic>>()
              .toList();
        } catch (e) {
          AppLogger.error(
            '그룹 타이머 활동 조회 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  /// 실시간 그룹 멤버 타이머 상태 스트림
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    final membersStream =
        _groupsCollection.doc(groupId).collection('members').snapshots();

    final activitiesStream =
        _groupsCollection
            .doc(groupId)
            .collection('timerActivities')
            .orderBy('timestamp', descending: true)
            .snapshots();

    // StreamController를 사용해서 두 스트림을 결합
    late StreamController<List<Map<String, dynamic>>> controller;
    late StreamSubscription membersSub;
    late StreamSubscription activitiesSub;

    void handleUpdate() async {
      try {
        AppLogger.debug(
          '멤버 또는 타이머 활동 변경 감지',
          tag: 'GroupTimerFirebase',
        );

        // 1. 멤버 정보 조회
        final membersSnapshot =
            await _groupsCollection.doc(groupId).collection('members').get();

        final members =
            membersSnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

        if (members.isEmpty) {
          AppLogger.warning(
            '멤버가 없어서 빈 리스트 반환',
            tag: 'GroupTimerFirebase',
          );
          controller.add(<Map<String, dynamic>>[]);
          return;
        }

        // 2. 최신 타이머 활동 조회
        final activitiesSnapshot =
            await _groupsCollection
                .doc(groupId)
                .collection('timerActivities')
                .orderBy('timestamp', descending: true)
                .get();

        // 3. 멤버별 최신 타이머 활동 추출
        final memberLastActivities = <String, Map<String, dynamic>>{};

        for (final doc in activitiesSnapshot.docs) {
          final activity = doc.data();
          final userId = activity['userId'] as String?;

          if (userId != null && !memberLastActivities.containsKey(userId)) {
            memberLastActivities[userId] = {
              ...activity,
              'id': doc.id,
            };
          }
        }

        AppLogger.debug(
          '멤버별 최신 활동 추출 완료: ${memberLastActivities.length}명',
          tag: 'GroupTimerFirebase',
        );

        // 4. DTO 형태로 결합하여 반환
        final result = _combineMemebersWithTimerStatusAsDto(
          members,
          memberLastActivities,
        );

        controller.add(result);
      } catch (e) {
        AppLogger.error(
          '복합 스트림 처리 오류',
          tag: 'GroupTimerFirebase',
          error: e,
        );
        controller.addError(e);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        membersSub = membersStream.listen((_) => handleUpdate());
        activitiesSub = activitiesStream.listen((_) => handleUpdate());
      },
      onCancel: () {
        membersSub.cancel();
        activitiesSub.cancel();
      },
    );

    return controller.stream;
  }

  /// 멤버 정보와 타이머 상태를 DTO 형태로 결합하는 헬퍼 메서드
  List<Map<String, dynamic>> _combineMemebersWithTimerStatusAsDto(
    List<Map<String, dynamic>> members,
    Map<String, Map<String, dynamic>> memberLastActivities,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final member in members) {
      final userId = member['userId'] as String?;
      if (userId == null) {
        // userId가 없는 멤버는 그대로 추가 (타이머 상태 없음)
        result.add({
          'memberDto': member,
          'timerActivityDto': null,
        });
        continue;
      }

      // 해당 멤버의 최신 타이머 활동 찾기
      final lastActivity = memberLastActivities[userId];

      // 멤버 DTO와 타이머 활동 DTO를 분리하여 저장
      result.add({
        'memberDto': member,
        'timerActivityDto': lastActivity, // null일 수 있음 (타이머 활동이 없는 경우)
      });
    }

    return result;
  }

  /// 멤버 타이머 시작
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.startMemberTimer',
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

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': 'start',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {},
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 시작 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  /// 멤버 타이머 일시정지
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.pauseMemberTimer',
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

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': 'pause',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {},
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 일시정지 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  /// 멤버 타이머 정지 (완료)
  Future<Map<String, dynamic>> stopMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupTimer.stopMemberTimer',
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

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': 'end',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {},
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 정지 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId},
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

          // 시작일 계산 (요청 월에서 preloadMonths만큼 이전으로)
          final startMonth = DateTime(year, month - preloadMonths, 1);
          final endDate = DateTime(year, month + 1, 1); // 종료일은 요청 월의 다음 달 1일

          // Timestamp로 변환
          final startTimestamp = Timestamp.fromDate(startMonth);
          final endTimestamp = Timestamp.fromDate(endDate);

          // 해당 기간의 타이머 활동 데이터 조회
          final activitiesSnapshot =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
                  .where('timestamp', isLessThan: endTimestamp)
                  .orderBy('timestamp')
                  .get();

          // 결과가 없는 경우 빈 배열 반환
          if (activitiesSnapshot.docs.isEmpty) {
            return [];
          }

          // 타이머 활동 데이터 변환
          final activities =
              activitiesSnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          return activities;
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
          final userName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': activityType,
            'timestamp': Timestamp.fromDate(timestamp), // 특정 시간으로 설정
            'groupId': groupId,
            'metadata': {
              'isManualTimestamp': true, // 수동으로 설정된 타임스탬프 표시
              'recordedAt': FieldValue.serverTimestamp(), // 실제 기록 시간
            },
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;

          AppLogger.info(
            '타이머 활동 기록 완료: $activityType at $timestamp',
            tag: 'GroupTimerFirebase',
          );

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 활동 기록 오류',
            tag: 'GroupTimerFirebase',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {
        'groupId': groupId,
        'activityType': activityType,
        'timestamp': timestamp.toIso8601String(),
      },
    );
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

  Future<Map<String, dynamic>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'end', timestamp);
  }
}
