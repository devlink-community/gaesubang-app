import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';
import 'package:devlink_mobile_app/notification/data/dto/notification_dto.dart';

class MockNotificationDataSourceImpl implements NotificationDataSource {
  // 메모리 내 알림 저장소
  final Map<String, List<NotificationDto>> _userNotifications = {};

  // 모의 알림 생성
  MockNotificationDataSourceImpl() {
    // 테스트용 목 데이터 초기화
    _initMockData();
  }

  // void _initMockData() {
  //   print('목 데이터 초기화 시작'); // 디버깅 로그
  //   final testUser =
  //       'testUser'; // 이 값이 NotificationNotifier의 _currentUserId와 일치해야 함

  //   final notifications = List.generate(
  //     10,
  //     (index) => NotificationDto(
  //       id: 'notification_$index',
  //       userId: testUser,
  //       type: index % 2 == 0 ? 'like' : 'comment',
  //       targetId: 'post_${index % 5}',
  //       senderName: '사용자${index + 1}',
  //       createdAt: DateTime.now().subtract(Duration(hours: index)),
  //       isRead: index > 5,
  //       description: '게시글에 ${index % 2 == 0 ? "좋아요를 눌렀습니다" : "댓글을 남겼습니다"}',
  //       imageUrl: 'https://example.com/avatar$index.jpg',
  //     ),
  //   );

  //   _userNotifications[testUser] = notifications;
  //   print('목 데이터 초기화 완료: ${notifications.length}개 알림'); // 디버깅 로그
  // }

  void _initMockData() {
    print('목 데이터 초기화 시작'); // 디버깅 로그
    try {
      final testUser =
          'testUser'; // 이 값이 NotificationNotifier의 _currentUserId와 일치해야 함

      // 매우 간단한 알림 목록 생성 (복잡한 로직 제거)
      final notifications = [
        NotificationDto(
          id: 'notification_1',
          userId: testUser,
          type: 'like',
          targetId: 'post_1',
          senderName: '테스트 사용자',
          createdAt: DateTime.now(),
          isRead: false,
          description: '게시글에 좋아요를 눌렀습니다',
        ),
      ];

      _userNotifications[testUser] = notifications;
      print('목 데이터 초기화 완료: ${notifications.length}개 알림'); // 디버깅 로그
    } catch (e) {
      print('목 데이터 초기화 중 오류: $e'); // 예외 로깅
    }
  }

  @override
  Future<List<NotificationDto>> fetchNotifications(String userId) async {
    print('fetchNotifications 호출됨: userId=$userId'); // 디버깅 로그
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 해당 사용자의 알림이 없으면 빈 목록 반환
    final notifications = _userNotifications[userId] ?? [];
    print('사용자($userId)의 알림 수: ${notifications.length}'); // 디버깅 로그
    return notifications;
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 모든 사용자의 알림을 순회하며 해당 ID의 알림 찾기
    for (var notifications in _userNotifications.values) {
      for (var i = 0; i < notifications.length; i++) {
        if (notifications[i].id == notificationId) {
          // 새 DTO 생성해서 교체 (isRead = true)
          notifications[i] = NotificationDto(
            id: notifications[i].id,
            userId: notifications[i].userId,
            type: notifications[i].type,
            targetId: notifications[i].targetId,
            senderName: notifications[i].senderName,
            createdAt: notifications[i].createdAt,
            isRead: true,
            description: notifications[i].description,
            imageUrl: notifications[i].imageUrl,
          );
          return true;
        }
      }
    }

    return false; // 알림을 찾지 못함
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    final notifications = _userNotifications[userId];
    if (notifications == null) return false;

    // 모든 알림을 읽음 처리
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = NotificationDto(
        id: notifications[i].id,
        userId: notifications[i].userId,
        type: notifications[i].type,
        targetId: notifications[i].targetId,
        senderName: notifications[i].senderName,
        createdAt: notifications[i].createdAt,
        isRead: true,
        description: notifications[i].description,
        imageUrl: notifications[i].imageUrl,
      );
    }

    return true;
  }

  @override
  Future<bool> deleteNotification(String notificationId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 모든 사용자의 알림을 순회하며 해당 ID의 알림 찾아 삭제
    for (var userId in _userNotifications.keys) {
      final notifications = _userNotifications[userId]!;
      final initialLength = notifications.length;

      _userNotifications[userId] =
          notifications
              .where((notification) => notification.id != notificationId)
              .toList();

      // 목록 길이가 줄었으면 삭제 성공
      return _userNotifications[userId]!.length < initialLength;
    }

    return false; // 알림을 찾지 못함
  }
}
