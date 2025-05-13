import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/notification/domain/model/notification.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/get_notifications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_notifications_use_case_test.mocks.dart';

@GenerateMocks([NotificationRepository])
void main() {
  late MockNotificationRepository mockRepository;
  late GetNotificationsUseCase useCase;

  // Mockito에게 Result<List<Notification>> 타입의 더미 값 제공
  provideDummy<Result<List<Notification>>>(
    const Result.success(<Notification>[]),
  );

  setUp(() {
    mockRepository = MockNotificationRepository();
    useCase = GetNotificationsUseCase(repository: mockRepository);
  });

  group('GetNotificationsUseCase', () {
    test('성공 시 AsyncData를 반환해야 함', () async {
      // 준비
      final notifications = [
        Notification(
          id: 'notification_1',
          userId: 'user_1',
          type: NotificationType.like,
          targetId: 'post_1',
          senderName: '테스트유저',
          createdAt: DateTime.now(),
        ),
      ];

      when(
        mockRepository.getNotifications('user_1'),
      ).thenAnswer((_) async => Result.success(notifications));

      // 실행
      final result = await useCase.execute('user_1');

      // 검증
      expect(result, isA<AsyncData<List<Notification>>>());
      expect(result.value, notifications);

      verify(mockRepository.getNotifications('user_1')).called(1);
    });

    test('실패 시 AsyncError를 반환해야 함', () async {
      // 준비
      final failure = Failure(FailureType.network, '네트워크 오류가 발생했습니다');

      when(
        mockRepository.getNotifications('user_1'),
      ).thenAnswer((_) async => Result<List<Notification>>.error(failure));

      // 실행
      final result = await useCase.execute('user_1');

      // 검증
      expect(result, isA<AsyncError>());
      expect(result.error, failure);

      verify(mockRepository.getNotifications('user_1')).called(1);
    });
  });
}
