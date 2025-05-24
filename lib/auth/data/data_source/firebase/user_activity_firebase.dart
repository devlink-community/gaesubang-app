// lib/auth/data/data_source/firebase/user_activity_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';

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
}
