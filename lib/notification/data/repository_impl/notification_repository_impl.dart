import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';
import 'package:devlink_mobile_app/notification/data/mapper/notification_mapper.dart';
import 'package:devlink_mobile_app/notification/domain/model/notification.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  NotificationRepositoryImpl({required NotificationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    try {
      final dtoList = await _dataSource.fetchNotifications(userId);
      return Result.success(dtoList.toModelList());
    } catch (e, stackTrace) {
      return Result.error(mapExceptionToFailure(e, stackTrace));
    }
  }

  @override
  Future<Result<bool>> markAsRead(String notificationId) async {
    try {
      final success = await _dataSource.markAsRead(notificationId);
      return Result.success(success);
    } catch (e, stackTrace) {
      return Result.error(mapExceptionToFailure(e, stackTrace));
    }
  }

  @override
  Future<Result<bool>> markAllAsRead(String userId) async {
    try {
      final success = await _dataSource.markAllAsRead(userId);
      return Result.success(success);
    } catch (e, stackTrace) {
      return Result.error(mapExceptionToFailure(e, stackTrace));
    }
  }

  @override
  Future<Result<bool>> deleteNotification(String notificationId) async {
    try {
      final success = await _dataSource.deleteNotification(notificationId);
      return Result.success(success);
    } catch (e, stackTrace) {
      return Result.error(mapExceptionToFailure(e, stackTrace));
    }
  }
}
