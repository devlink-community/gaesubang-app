import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';
import 'package:devlink_mobile_app/notification/data/dto/notification_dto_old.dart';
import 'package:devlink_mobile_app/notification/data/repository_impl/notification_repository_impl.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'notification_repository_impl_test.mocks.dart';

@GenerateMocks([NotificationDataSource])
void main() {
  late MockNotificationDataSource mockDataSource;
  late NotificationRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockNotificationDataSource();
    repository = NotificationRepositoryImpl(dataSource: mockDataSource);
  });

  group('NotificationRepository', () {
    test('getNotifications 성공 시 Result.success를 반환해야 함', () async {
      // 준비
      when(mockDataSource.fetchNotifications('user_1')).thenAnswer(
        (_) async => [
          NotificationDto(
            id: 'notification_1',
            userId: 'user_1',
            type: 'like',
            targetId: 'post_1',
            senderName: '테스트유저',
            createdAt: DateTime.now(),
          ),
        ],
      );

      // 실행
      final result = await repository.getNotifications('user_1');

      // 검증
      expect(result, isA<Success>());
      final notifications = (result as Success).data;
      expect(notifications.length, 1);
      expect(notifications[0].id, 'notification_1');
      expect(notifications[0].type, NotificationType.like);

      verify(mockDataSource.fetchNotifications('user_1')).called(1);
    });

    test('getNotifications 실패 시 Result.error를 반환해야 함', () async {
      // 준비
      when(
        mockDataSource.fetchNotifications('user_1'),
      ).thenThrow(Exception('Network error'));

      // 실행
      final result = await repository.getNotifications('user_1');

      // 검증
      expect(result, isA<Error>());
      final failure = (result as Error).failure;
      expect(failure.message, contains('알 수 없는 오류가 발생했습니다'));

      verify(mockDataSource.fetchNotifications('user_1')).called(1);
    });

    test('markAsRead 성공 시 Result.success를 반환해야 함', () async {
      // 준비
      when(
        mockDataSource.markAsRead('notification_1'),
      ).thenAnswer((_) async => true);

      // 실행
      final result = await repository.markAsRead('notification_1');

      // 검증
      expect(result, isA<Success>());
      expect((result as Success).data, true);

      verify(mockDataSource.markAsRead('notification_1')).called(1);
    });
  });
}
