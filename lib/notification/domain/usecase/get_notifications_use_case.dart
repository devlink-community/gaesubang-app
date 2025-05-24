import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<AppNotification>>> execute(String userId) async {
    final result = await _repository.getNotifications(userId);

    switch (result) {
      case Success(:final data):
        AppLogger.info(
          '알림 목록 조회 성공: ${data.length}개 알림',
          tag: 'GetNotifications',
        );
        return AsyncData(data);
      case Error(failure: final failure):
        AppLogger.error(
          '알림 목록 조회 실패',
          tag: 'GetNotifications',
          error: failure.message,
        );
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}