import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Model', () {
    test('생성자가 올바르게 값을 설정해야 함', () {
      final now = DateTime.now();
      final notification = AppNotification(
        id: 'test_id',
        userId: 'user_1',
        type: NotificationType.like,
        targetId: 'post_1',
        senderName: '테스트유저',
        createdAt: now,
        description: '게시글에 좋아요를 남겼습니다',
      );

      expect(notification.id, 'test_id');
      expect(notification.userId, 'user_1');
      expect(notification.type, NotificationType.like);
      expect(notification.targetId, 'post_1');
      expect(notification.senderName, '테스트유저');
      expect(notification.createdAt, now);
      expect(notification.isRead, false); // 기본값 확인
      expect(notification.description, '게시글에 좋아요를 남겼습니다');
      expect(notification.imageUrl, null); // 선택적 매개변수 기본값 확인
    });

    test('선택적 매개변수가 올바르게 설정되어야 함', () {
      final notification = AppNotification(
        id: 'test_id',
        userId: 'user_1',
        type: NotificationType.comment,
        targetId: 'post_1',
        senderName: '테스트유저',
        createdAt: DateTime.now(),
        isRead: true,
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(notification.isRead, true);
      expect(notification.imageUrl, 'https://example.com/image.jpg');
    });
  });
}
