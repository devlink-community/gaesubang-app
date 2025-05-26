import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';
import 'package:devlink_mobile_app/notification/data/mapper/notification_mapper.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  NotificationRepositoryImpl({required NotificationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    final startTime = TimeFormatter.nowInSeoul();
    AppLogger.info(
      '알림 목록 조회 시작 (Repository): $userId',
      tag: 'NotificationRepository',
    );

    try {
      final dtoList = await _dataSource.fetchNotifications(userId);
      final notifications = dtoList.toModelList();

      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('알림 목록 조회 완료', duration);

      AppLogger.info(
        '알림 목록 변환 성공: ${notifications.length}개',
        tag: 'NotificationRepository',
      );

      return Result.success(notifications);
    } catch (e, stackTrace) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('알림 목록 조회 실패', duration);

      AppLogger.error(
        '알림 목록 조회 실패 (Repository)',
        tag: 'NotificationRepository',
        error: e,
        stackTrace: stackTrace,
      );

      return Result.error(AuthExceptionMapper.mapAuthException(e, stackTrace));
    }
  }

  @override
  Future<Result<bool>> markAsRead(String userId, String notificationId) async {
    final startTime = TimeFormatter.nowInSeoul();
    AppLogger.info(
      '알림 읽음 처리 시작 (Repository): $notificationId',
      tag: 'NotificationRepository',
    );

    try {
      final success = await _dataSource.markAsRead(userId, notificationId);

      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('알림 읽음 처리 완료', duration);

      AppLogger.info(
        '알림 읽음 처리 결과: ${success ? "성공" : "실패"}',
        tag: 'NotificationRepository',
      );

      return Result.success(success);
    } catch (e, stackTrace) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('알림 읽음 처리 실패', duration);

      AppLogger.error(
        '알림 읽음 처리 실패 (Repository)',
        tag: 'NotificationRepository',
        error: e,
        stackTrace: stackTrace,
      );

      return Result.error(AuthExceptionMapper.mapAuthException(e, stackTrace));
    }
  }

  @override
  Future<Result<bool>> markAllAsRead(String userId) async {
    final startTime = TimeFormatter.nowInSeoul();
    AppLogger.info(
      '모든 알림 읽음 처리 시작 (Repository): $userId',
      tag: 'NotificationRepository',
    );

    try {
      final success = await _dataSource.markAllAsRead(userId);

      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('모든 알림 읽음 처리 완료', duration);

      AppLogger.info(
        '모든 알림 읽음 처리 결과: ${success ? "성공" : "실패"}',
        tag: 'NotificationRepository',
      );

      return Result.success(success);
    } catch (e, stackTrace) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('모든 알림 읽음 처리 실패', duration);

      AppLogger.error(
        '모든 알림 읽음 처리 실패 (Repository)',
        tag: 'NotificationRepository',
        error: e,
        stackTrace: stackTrace,
      );

      return Result.error(AuthExceptionMapper.mapAuthException(e, stackTrace));
    }
  }

  @override
  Future<Result<bool>> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    final startTime = TimeFormatter.nowInSeoul();
    AppLogger.info(
      '알림 삭제 시작 (Repository): $notificationId',
      tag: 'NotificationRepository',
    );

    try {
      final success = await _dataSource.deleteNotification(
        userId,
        notificationId,
      );

      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('알림 삭제 완료', duration);

      AppLogger.info(
        '알림 삭제 결과: ${success ? "성공" : "실패"}',
        tag: 'NotificationRepository',
      );

      return Result.success(success);
    } catch (e, stackTrace) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('알림 삭제 실패', duration);

      AppLogger.error(
        '알림 삭제 실패 (Repository)',
        tag: 'NotificationRepository',
        error: e,
        stackTrace: stackTrace,
      );

      return Result.error(AuthExceptionMapper.mapAuthException(e, stackTrace));
    }
  }
}
