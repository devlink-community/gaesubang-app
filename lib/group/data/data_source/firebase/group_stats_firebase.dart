import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

/// 그룹 통계 기능 (연속 출석일, 주간 공부시간, 이미지 관리)
class GroupStatsFirebase {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  GroupStatsFirebase({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _auth = auth,
       _storage = storage;

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 현재 사용자 확인 헬퍼 메서드
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }
    return user.uid;
  }

  /// 현재 사용자의 가입 그룹 ID 목록 가져오기 (내부용)
  Future<Set<String>> _getCurrentUserJoinedGroupIds() async {
    try {
      final userId = _getCurrentUserId();

      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists || !userDoc.data()!.containsKey('joingroup')) {
        return {};
      }

      final joinGroups = userDoc.data()!['joingroup'] as List<dynamic>;
      return joinGroups
          .map((group) => group['group_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
    } catch (e) {
      AppLogger.error(
        'Error getting joined groups',
        tag: 'GroupStatsFirebase',
        error: e,
      );
      return {};
    }
  }

  /// 사용자 최대 연속 출석일 조회
  Future<Map<String, dynamic>> fetchUserMaxStreakDays() async {
    return ApiCallDecorator.wrap(
      'GroupStats.fetchUserMaxStreakDays',
      () async {
        try {
          final userId = _getCurrentUserId();

          // 1. 현재 사용자가 가입한 모든 그룹 ID 조회
          final joinedGroupIds = await _getCurrentUserJoinedGroupIds();

          if (joinedGroupIds.isEmpty) {
            return {
              'maxStreakDays': 0,
              'bestGroupId': null,
              'bestGroupName': null,
              'lastActiveDate': Timestamp.now(),
            };
          }

          int maxStreakDays = 0;
          String? bestGroupId;
          String? bestGroupName;
          DateTime? lastActiveDate;

          // 2. 각 그룹별로 연속 출석일 계산
          for (final groupId in joinedGroupIds) {
            final streakInfo = await _calculateUserStreakInfoInGroup(
              groupId,
              userId,
            );

            if (streakInfo['streakDays'] > maxStreakDays) {
              maxStreakDays = streakInfo['streakDays'];
              bestGroupId = groupId;
              bestGroupName = streakInfo['groupName'];
              lastActiveDate = streakInfo['lastActiveDate'];
            }
          }

          return {
            'maxStreakDays': maxStreakDays,
            'bestGroupId': bestGroupId,
            'bestGroupName': bestGroupName,
            'lastActiveDate':
                lastActiveDate != null
                    ? Timestamp.fromDate(lastActiveDate)
                    : Timestamp.now(),
          };
        } catch (e) {
          AppLogger.error(
            '사용자 최대 연속 출석일 조회 오류',
            tag: 'GroupStatsFirebase',
            error: e,
          );
          throw Exception('연속 출석일을 불러오는데 실패했습니다');
        }
      },
    );
  }

  /// 특정 그룹에서 특정 사용자의 연속 출석일 및 상세 정보 계산
  Future<Map<String, dynamic>> _calculateUserStreakInfoInGroup(
    String groupId,
    String userId,
  ) async {
    try {
      // 그룹 정보 조회 (그룹 이름 가져오기)
      final groupDoc = await _groupsCollection.doc(groupId).get();
      final groupName =
          groupDoc.exists
              ? (groupDoc.data()?['name'] as String? ?? '알 수 없는 그룹')
              : '알 수 없는 그룹';

      // 최근 30일간의 타이머 활동 조회 (연속 출석일 계산용)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final startTimestamp = Timestamp.fromDate(thirtyDaysAgo);

      final activitiesSnapshot =
          await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .where('userId', isEqualTo: userId)
              .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
              .orderBy('timestamp', descending: true)
              .get();

      if (activitiesSnapshot.docs.isEmpty) {
        return {
          'streakDays': 0,
          'groupName': groupName,
          'lastActiveDate': DateTime.now(),
        };
      }

      // 날짜별로 활동 그룹화
      final Map<String, List<Map<String, dynamic>>> activitiesByDate = {};
      DateTime? latestActiveDate;

      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = DateFormat('yyyy-MM-dd').format(date);

          // 가장 최근 활동 날짜 업데이트
          if (latestActiveDate == null || date.isAfter(latestActiveDate)) {
            latestActiveDate = date;
          }

          activitiesByDate[dateKey] ??= [];
          activitiesByDate[dateKey]!.add({
            ...data,
            'id': doc.id,
          });
        }
      }

      // 실제 활동한 날짜들 추출 (start/end 페어가 있는 날만)
      final Set<String> activeDates = {};

      for (final entry in activitiesByDate.entries) {
        final dateKey = entry.key;
        final dayActivities = entry.value;

        // 해당 날짜에 start와 end 활동이 모두 있는지 확인
        final hasStart = dayActivities.any((a) => a['type'] == 'start');
        final hasEnd = dayActivities.any((a) => a['type'] == 'end');

        if (hasStart && hasEnd) {
          activeDates.add(dateKey);
        }
      }

      if (activeDates.isEmpty) {
        return {
          'streakDays': 0,
          'groupName': groupName,
          'lastActiveDate': latestActiveDate ?? DateTime.now(),
        };
      }

      // 연속 출석일 계산
      final streakDays = _calculateStreakDaysFromActiveDates(activeDates);

      return {
        'streakDays': streakDays,
        'groupName': groupName,
        'lastActiveDate': latestActiveDate ?? DateTime.now(),
      };
    } catch (e) {
      AppLogger.error(
        '그룹 $groupId에서 사용자 $userId 연속 출석일 계산 오류',
        tag: 'GroupStatsFirebase',
        error: e,
      );
      return {
        'streakDays': 0,
        'groupName': '알 수 없는 그룹',
        'lastActiveDate': DateTime.now(),
      };
    }
  }

  /// 활동한 날짜들로부터 연속 출석일 계산
  int _calculateStreakDaysFromActiveDates(Set<String> activeDates) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // 오늘 또는 어제까지 활동이 있었는지 확인 (연속성 유지 조건)
    bool hasRecentActivity =
        activeDates.contains(today) || activeDates.contains(yesterday);

    if (!hasRecentActivity) {
      return 0; // 최근 활동이 없으면 연속 출석일 0
    }

    int streakDays = 0;

    // 오늘부터 역순으로 연속일 계산
    for (int i = 0; i < 30; i++) {
      // 최대 30일까지만 확인
      final checkDate = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(Duration(days: i)),
      );

      if (activeDates.contains(checkDate)) {
        streakDays++;
      } else {
        break; // 연속성이 끊어지면 중단
      }
    }

    return streakDays;
  }

  /// 현재 사용자의 이번 주 공부 시간 조회 (분 단위)
  Future<int> fetchWeeklyStudyTimeMinutes() async {
    return ApiCallDecorator.wrap(
      'GroupStats.fetchWeeklyStudyTimeMinutes',
      () async {
        try {
          final userId = _getCurrentUserId();

          // 1. 현재 사용자가 가입한 그룹 ID 목록 조회
          final joinedGroupIds = await _getCurrentUserJoinedGroupIds();

          if (joinedGroupIds.isEmpty) {
            return 0; // 가입한 그룹이 없으면 0분 반환
          }

          // 2. 이번 주 시작일과 종료일 계산
          final now = DateTime.now();
          final weekStart = now.subtract(
            Duration(days: now.weekday - 1),
          ); // 월요일
          final weekStartDate = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day,
          );
          final weekEndDate = weekStartDate.add(const Duration(days: 7));

          final startTimestamp = Timestamp.fromDate(weekStartDate);
          final endTimestamp = Timestamp.fromDate(weekEndDate);

          int totalWeeklyMinutes = 0;

          // 3. 각 그룹별로 이번 주 타이머 활동 조회 및 집계
          for (final groupId in joinedGroupIds) {
            // 해당 그룹에서 현재 사용자의 이번 주 활동 조회
            final activitiesSnapshot =
                await _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('userId', isEqualTo: userId)
                    .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
                    .where('timestamp', isLessThan: endTimestamp)
                    .orderBy('timestamp')
                    .get();

            if (activitiesSnapshot.docs.isEmpty) continue;

            // 4. 활동 데이터를 시간순으로 정렬하여 start/end 페어 매칭
            final activities =
                activitiesSnapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }).toList();

            // start/end 페어 매칭하여 시간 계산
            DateTime? startTime;
            for (final activity in activities) {
              final type = activity['type'] as String?;
              final timestamp = activity['timestamp'] as Timestamp?;

              if (timestamp == null) continue;

              final activityTime = timestamp.toDate();

              if (type == 'start') {
                startTime = activityTime;
              } else if (type == 'end' && startTime != null) {
                final duration = activityTime.difference(startTime).inMinutes;
                if (duration > 0) {
                  totalWeeklyMinutes += duration;
                }
                startTime = null; // 페어 처리 완료
              }
            }
          }

          return totalWeeklyMinutes;
        } catch (e) {
          AppLogger.error(
            '이번 주 공부 시간 조회 오류',
            tag: 'GroupStatsFirebase',
            error: e,
          );
          throw Exception('이번 주 공부 시간을 불러오는데 실패했습니다');
        }
      },
    );
  }

  /// 그룹 이미지 업데이트
  Future<String> updateGroupImage(String groupId, String localImagePath) async {
    return ApiCallDecorator.wrap('GroupStats.updateGroupImage', () async {
      try {
        // 그룹 존재 확인
        final groupDoc = await _groupsCollection.doc(groupId).get();

        if (!groupDoc.exists) {
          throw Exception('그룹을 찾을 수 없습니다');
        }

        String imageUrl;

        // URL인 경우 (이미 업로드된 이미지 사용)
        if (localImagePath.startsWith('http')) {
          imageUrl = localImagePath;
        } else {
          // 로컬 파일 업로드
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${localImagePath.split('/').last}';
          final storageRef = _storage.ref().child('groups/$groupId/$fileName');

          // 파일 업로드
          final uploadTask = await storageRef.putFile(File(localImagePath));

          // 다운로드 URL 가져오기
          imageUrl = await uploadTask.ref.getDownloadURL();
        }

        // 그룹 이미지 업데이트
        await _groupsCollection.doc(groupId).update({
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return imageUrl;
      } catch (e) {
        AppLogger.error(
          '그룹 이미지 업데이트 오류',
          tag: 'GroupStatsFirebase',
          error: e,
        );
        throw Exception('그룹 이미지 업데이트에 실패했습니다');
      }
    }, params: {'groupId': groupId});
  }
}
