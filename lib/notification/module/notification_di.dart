import 'package:devlink_mobile_app/notification/data/data_source/mock_notification_data_source_impl.dart';
import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';
import 'package:devlink_mobile_app/notification/data/repository_impl/notification_repository_impl.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/delete_notification_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/get_notifications_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/mark_all_notifications_as_read_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/mark_notification_as_read_use_case.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_di.g.dart';

// 데이터 소스 제공
@riverpod
NotificationDataSource notificationDataSource(Ref ref) {
  return MockNotificationDataSourceImpl();
}

// 리포지토리 제공
@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(
    dataSource: ref.watch(notificationDataSourceProvider),
  );
}

// 유즈케이스 제공
@riverpod
GetNotificationsUseCase getNotificationsUseCase(Ref ref) {
  return GetNotificationsUseCase(
    repository: ref.watch(notificationRepositoryProvider),
  );
}

@riverpod
MarkNotificationAsReadUseCase markNotificationAsReadUseCase(Ref ref) {
  return MarkNotificationAsReadUseCase(
    repository: ref.watch(notificationRepositoryProvider),
  );
}

@riverpod
MarkAllNotificationsAsReadUseCase markAllNotificationsAsReadUseCase(Ref ref) {
  return MarkAllNotificationsAsReadUseCase(
    repository: ref.watch(notificationRepositoryProvider),
  );
}

@riverpod
DeleteNotificationUseCase deleteNotificationUseCase(Ref ref) {
  return DeleteNotificationUseCase(
    repository: ref.watch(notificationRepositoryProvider),
  );
}
