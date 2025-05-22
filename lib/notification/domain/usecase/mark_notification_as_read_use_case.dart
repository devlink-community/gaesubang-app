import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MarkNotificationAsReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationAsReadUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<AsyncValue<bool>> execute(String userId, String notificationId) async {
    final result = await _repository.markAsRead(userId, notificationId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
