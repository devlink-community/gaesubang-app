import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/notification/data/dto/notification_dto_old.dart';
import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';

class NotificationFirebaseDataSource implements NotificationDataSource {
  final FirebaseFirestore _firestore;

  NotificationFirebaseDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 사용자 알림 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _getUserNotificationsCollection(
    String userId,
  ) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items');
  }

  @override
  Future<List<NotificationDto>> fetchNotifications(String userId) async {
    return ApiCallDecorator.wrap(
      'NotificationFirebase.fetchNotifications',
      () async {
        AppLogger.info('알림 목록 조회 시작: $userId', tag: 'NotificationDataSource');

        try {
          final snapshot =
              await _getUserNotificationsCollection(userId)
                  .orderBy('createdAt', descending: true)
                  .limit(100) // 최근 100개로 제한
                  .get();

          final notifications =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return NotificationDto(
                  id: doc.id,
                  userId: userId,
                  type: data['type'] as String?,
                  targetId: data['targetId'] as String?,
                  senderName: data['senderName'] as String?,
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                  isRead: data['isRead'] as bool? ?? false,
                  description:
                      data['body'] as String?, // body를 description으로 매핑
                  imageUrl: data['senderProfileImage'] as String?,
                );
              }).toList();

          AppLogger.info(
            '알림 목록 조회 성공: ${notifications.length}개',
            tag: 'NotificationDataSource',
          );

          AppLogger.logState('알림 조회 결과', {
            'userId': userId,
            'totalCount': notifications.length,
            'unreadCount':
                notifications.where((n) => !(n.isRead ?? false)).length,
          });

          return notifications;
        } catch (e, stackTrace) {
          AppLogger.error(
            '알림 목록을 불러오는데 실패했습니다',
            tag: 'NotificationDataSource',
            error: e,
            stackTrace: stackTrace,
          );
          throw Exception('알림 목록을 불러오는데 실패했습니다: $e');
        }
      },
      params: {'userId': userId},
    );
  }

  @override
  Future<bool> markAsRead(String userId, String notificationId) async {
    return ApiCallDecorator.wrap(
      'NotificationFirebase.markAsRead',
      () async {
        AppLogger.info(
          '알림 읽음 처리 시작: $notificationId',
          tag: 'NotificationDataSource',
        );

        try {
          // 특정 사용자의 특정 알림 문서에 직접 접근 (효율적)
          final notificationRef = _getUserNotificationsCollection(
            userId,
          ).doc(notificationId);

          // 문서 존재 여부 확인
          final docSnapshot = await notificationRef.get();
          if (!docSnapshot.exists) {
            AppLogger.warning(
              '알림이 존재하지 않음: $notificationId',
              tag: 'NotificationDataSource',
            );
            return false; // 알림이 존재하지 않음
          }

          // 읽음 처리
          await notificationRef.update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });

          AppLogger.info(
            '알림 읽음 처리 성공: $notificationId',
            tag: 'NotificationDataSource',
          );
          return true;
        } catch (e, stackTrace) {
          AppLogger.error(
            '알림 읽음 처리에 실패했습니다',
            tag: 'NotificationDataSource',
            error: e,
            stackTrace: stackTrace,
          );
          throw Exception('알림 읽음 처리에 실패했습니다: $e');
        }
      },
      params: {'userId': userId, 'notificationId': notificationId},
    );
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    return ApiCallDecorator.wrap(
      'NotificationFirebase.markAllAsRead',
      () async {
        AppLogger.info(
          '모든 알림 읽음 처리 시작: $userId',
          tag: 'NotificationDataSource',
        );

        try {
          final batch = _firestore.batch();

          // 해당 사용자의 읽지 않은 알림들만 조회
          final unreadSnapshot =
              await _getUserNotificationsCollection(
                userId,
              ).where('isRead', isEqualTo: false).get();

          if (unreadSnapshot.docs.isEmpty) {
            AppLogger.info(
              '읽지 않은 알림이 없음: $userId',
              tag: 'NotificationDataSource',
            );
            return true; // 읽지 않은 알림이 없음
          }

          AppLogger.info(
            '읽지 않은 알림 ${unreadSnapshot.docs.length}개 처리 중',
            tag: 'NotificationDataSource',
          );

          // 배치로 모든 알림을 읽음 처리
          for (final doc in unreadSnapshot.docs) {
            batch.update(doc.reference, {
              'isRead': true,
              'readAt': FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();

          AppLogger.info(
            '모든 알림 읽음 처리 완료: ${unreadSnapshot.docs.length}개',
            tag: 'NotificationDataSource',
          );

          return true;
        } catch (e, stackTrace) {
          AppLogger.error(
            '모든 알림 읽음 처리에 실패했습니다',
            tag: 'NotificationDataSource',
            error: e,
            stackTrace: stackTrace,
          );
          throw Exception('모든 알림 읽음 처리에 실패했습니다: $e');
        }
      },
      params: {'userId': userId},
    );
  }

  @override
  Future<bool> deleteNotification(String userId, String notificationId) async {
    return ApiCallDecorator.wrap(
      'NotificationFirebase.deleteNotification',
      () async {
        AppLogger.info(
          '알림 삭제 시작: $notificationId',
          tag: 'NotificationDataSource',
        );

        try {
          // 특정 사용자의 특정 알림 문서에 직접 접근 (효율적)
          final notificationRef = _getUserNotificationsCollection(
            userId,
          ).doc(notificationId);

          // 문서 존재 여부 확인
          final docSnapshot = await notificationRef.get();
          if (!docSnapshot.exists) {
            AppLogger.warning(
              '삭제할 알림이 존재하지 않음: $notificationId',
              tag: 'NotificationDataSource',
            );
            return false; // 알림이 존재하지 않음
          }

          // 알림 삭제
          await notificationRef.delete();

          AppLogger.info(
            '알림 삭제 성공: $notificationId',
            tag: 'NotificationDataSource',
          );
          return true;
        } catch (e, stackTrace) {
          AppLogger.error(
            '알림 삭제에 실패했습니다',
            tag: 'NotificationDataSource',
            error: e,
            stackTrace: stackTrace,
          );
          throw Exception('알림 삭제에 실패했습니다: $e');
        }
      },
      params: {'userId': userId, 'notificationId': notificationId},
    );
  }
}
