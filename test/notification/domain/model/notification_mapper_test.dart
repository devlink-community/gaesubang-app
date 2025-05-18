import 'package:devlink_mobile_app/notification/data/dto/notification_dto_old.dart';
import 'package:devlink_mobile_app/notification/data/mapper/notification_mapper.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationMapper', () {
    test('DTO를 Model로 변환해야 함', () {
      final dto = NotificationDto(
        id: 'test_id',
        userId: 'user_1',
        type: 'like',
        targetId: 'post_1',
        senderName: '테스트유저',
        createdAt: DateTime(2023, 5, 10),
        isRead: false,
        description: '게시글에 좋아요를 남겼습니다',
        imageUrl: 'https://example.com/image.jpg',
      );

      final model = dto.toModel();

      expect(model.id, 'test_id');
      expect(model.userId, 'user_1');
      expect(model.type, NotificationType.like);
      expect(model.targetId, 'post_1');
      expect(model.senderName, '테스트유저');
      expect(model.createdAt, DateTime(2023, 5, 10));
      expect(model.isRead, false);
      expect(model.description, '게시글에 좋아요를 남겼습니다');
      expect(model.imageUrl, 'https://example.com/image.jpg');
    });

    test('알 수 없는 타입은 comment로 기본 설정해야 함', () {
      final dto = NotificationDto(
        id: 'test_id',
        userId: 'user_1',
        type: 'unknown_type',
        targetId: 'post_1',
        senderName: '테스트유저',
        createdAt: DateTime.now(),
      );

      final model = dto.toModel();
      expect(model.type, NotificationType.comment);
    });

    test('Model을 DTO로 변환해야 함', () {
      final model = AppNotification(
        id: 'test_id',
        userId: 'user_1',
        type: NotificationType.follow,
        targetId: 'user_2',
        senderName: '테스트유저',
        createdAt: DateTime(2023, 5, 10),
        isRead: true,
      );

      final dto = model.toDto();

      expect(dto.id, 'test_id');
      expect(dto.userId, 'user_1');
      expect(dto.type, 'follow');
      expect(dto.targetId, 'user_2');
      expect(dto.senderName, '테스트유저');
      expect(dto.createdAt, DateTime(2023, 5, 10));
      expect(dto.isRead, true);
    });

    test('DTO 리스트를 Model 리스트로 변환해야 함', () {
      final dtoList = [
        NotificationDto(
          id: 'test_id_1',
          type: 'like',
          userId: 'user_1',
          targetId: 'post_1',
          senderName: '테스트유저1',
          createdAt: DateTime.now(),
        ),
        NotificationDto(
          id: 'test_id_2',
          type: 'comment',
          userId: 'user_1',
          targetId: 'post_2',
          senderName: '테스트유저2',
          createdAt: DateTime.now(),
        ),
      ];

      final modelList = dtoList.toModelList();

      expect(modelList.length, 2);
      expect(modelList[0].id, 'test_id_1');
      expect(modelList[0].type, NotificationType.like);
      expect(modelList[1].id, 'test_id_2');
      expect(modelList[1].type, NotificationType.comment);
    });

    test('null 리스트는 빈 리스트로 변환해야 함', () {
      List<NotificationDto>? nullList;
      final result = nullList.toModelList();
      expect(result, isEmpty);
    });
  });
}
