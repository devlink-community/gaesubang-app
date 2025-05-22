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
  Future<bool> markAsRead(String notificationId) async {
    return ApiCallDecorator.wrap('NotificationFirebase.markAsRead', () async {
      try {
        // 모든 사용자의 알림에서 해당 ID 찾기 (비효율적이지만 현재 구조상 필요)
        final notificationsSnapshot =
            await _firestore
                .collectionGroup('items')
                .where(FieldPath.documentId, isEqualTo: notificationId)
                .get();

        if (notificationsSnapshot.docs.isEmpty) {
          return false;
        }

        final doc = notificationsSnapshot.docs.first;
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });

        return true;
      } catch (e) {
        throw Exception('알림 읽음 처리에 실패했습니다: $e');
      }
    }, params: {'notificationId': notificationId});
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    return ApiCallDecorator.wrap(
      'NotificationFirebase.markAllAsRead',
      () async {
        try {
          final batch = _firestore.batch();

          // 읽지 않은 알림들만 조회
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
  Future<bool> deleteNotification(String notificationId) async {
    return ApiCallDecorator.wrap(
      'NotificationFirebase.deleteNotification',
      () async {
        try {
          // 모든 사용자의 알림에서 해당 ID 찾기
          final notificationsSnapshot =
              await _firestore
                  .collectionGroup('items')
                  .where(FieldPath.documentId, isEqualTo: notificationId)
                  .get();

          if (notificationsSnapshot.docs.isEmpty) {
            return false;
          }

          final doc = notificationsSnapshot.docs.first;
          await doc.reference.delete();

          return true;
        } catch (e) {
          throw Exception('알림 삭제에 실패했습니다: $e');
        }
      },
      params: {'notificationId': notificationId},
    );
  }
}
