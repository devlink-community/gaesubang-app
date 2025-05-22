import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
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
        try {
          final snapshot =
              await _getUserNotificationsCollection(userId)
                  .orderBy('createdAt', descending: true)
                  .limit(100) // 최근 100개로 제한
                  .get();

          return snapshot.docs.map((doc) {
            final data = doc.data();
            return NotificationDto(
              id: doc.id,
              userId: userId,
              type: data['type'] as String?,
              targetId: data['targetId'] as String?,
              senderName: data['senderName'] as String?,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              isRead: data['isRead'] as bool? ?? false,
              description: data['body'] as String?, // body를 description으로 매핑
              imageUrl: data['senderProfileImage'] as String?,
            );
          }).toList();
        } catch (e) {
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
        try {
          // 특정 사용자의 특정 알림 문서에 직접 접근 (효율적)
          final notificationRef = _getUserNotificationsCollection(
            userId,
          ).doc(notificationId);

          // 문서 존재 여부 확인
          final docSnapshot = await notificationRef.get();
          if (!docSnapshot.exists) {
            return false; // 알림이 존재하지 않음
          }

          // 읽음 처리
          await notificationRef.update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });

          return true;
        } catch (e) {
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
        try {
          final batch = _firestore.batch();

          // 해당 사용자의 읽지 않은 알림들만 조회
          final unreadSnapshot =
              await _getUserNotificationsCollection(
                userId,
              ).where('isRead', isEqualTo: false).get();

          if (unreadSnapshot.docs.isEmpty) {
            return true; // 읽지 않은 알림이 없음
          }

          // 배치로 모든 알림을 읽음 처리
          for (final doc in unreadSnapshot.docs) {
            batch.update(doc.reference, {
              'isRead': true,
              'readAt': FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();
          return true;
        } catch (e) {
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
        try {
          // 특정 사용자의 특정 알림 문서에 직접 접근 (효율적)
          final notificationRef = _getUserNotificationsCollection(
            userId,
          ).doc(notificationId);

          // 문서 존재 여부 확인
          final docSnapshot = await notificationRef.get();
          if (!docSnapshot.exists) {
            return false; // 알림이 존재하지 않음
          }

          // 알림 삭제
          await notificationRef.delete();
          return true;
        } catch (e) {
          throw Exception('알림 삭제에 실패했습니다: $e');
        }
      },
      params: {'userId': userId, 'notificationId': notificationId},
    );
  }
}
