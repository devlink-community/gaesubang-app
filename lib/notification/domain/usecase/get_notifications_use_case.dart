import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/notification/domain/model/notification.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Notification>>> execute(String userId) async {
    final result = await _repository.getNotifications(userId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
