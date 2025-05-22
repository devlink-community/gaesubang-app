import 'package:devlink_mobile_app/notification/data/data_source/notification_data_source.dart';
import 'package:devlink_mobile_app/notification/data/dto/notification_dto_old.dart';

class MockNotificationDataSourceImpl implements NotificationDataSource {
  // 메모리 내 알림 저장소
  final Map<String, List<NotificationDto>> _userNotifications = {};

  // 모의 알림 생성
  MockNotificationDataSourceImpl() {
    // 테스트용 목 데이터 초기화
    _initMockData();
  }

  void _initMockData() {
    print('목 데이터 초기화 시작');
    try {
      final testUser =
          'testUser'; // NotificationNotifier의 _currentUserId와 일치해야 함
      final now = DateTime.now();

      // 다양한 날짜의 알림 생성
      final notifications = [
        // 오늘 알림 (5개)
        ..._generateNotifications(0, 5, testUser, now),

        // 최근 7일 알림 (10개)
        ..._generateNotifications(
          1,
          3,
          testUser,
          now.subtract(const Duration(days: 2)),
        ),
        ..._generateNotifications(
          4,
          4,
          testUser,
          now.subtract(const Duration(days: 4)),
        ),
        ..._generateNotifications(
          8,
          3,
          testUser,
          now.subtract(const Duration(days: 6)),
        ),

        // 이전 활동 알림 (15개)
        ..._generateNotifications(
          11,
          5,
          testUser,
          now.subtract(const Duration(days: 10)),
        ),
        ..._generateNotifications(
          16,
          5,
          testUser,
          now.subtract(const Duration(days: 20)),
        ),
        ..._generateNotifications(
          21,
          5,
          testUser,
          now.subtract(const Duration(days: 30)),
        ),
      ];

      _userNotifications[testUser] = notifications;
      print('목 데이터 초기화 완료: ${notifications.length}개 알림');
    } catch (e) {
      print('목 데이터 초기화 중 오류: $e');
    }
  }

  // 알림 데이터 생성 헬퍼 메서드
  List<NotificationDto> _generateNotifications(
    int startIndex,
    int count,
    String userId,
    DateTime baseTime,
  ) {
    final types = ['like', 'comment', 'follow', 'mention'];

    return List.generate(count, (index) {
      final currentIndex = startIndex + index;
      final isRead = currentIndex > 7; // 8번째 알림부터는 읽음 처리
      final typeIndex = currentIndex % types.length;

      // 테스트 이미지 URL을 네트워크 요청이 발생하지 않도록 null로 설정
      final imageUrl = currentIndex % 3 == 0 ? null : null; // 모든 이미지를 null로 설정

      return NotificationDto(
        id: 'notification_$currentIndex',
        userId: userId,
        type: types[typeIndex],
        targetId: 'post_${currentIndex % 10}',
        senderName: '사용자${currentIndex + 1}',
        // 기준 시간에 각각 다른 시간 간격 추가
        createdAt: baseTime.subtract(Duration(hours: index * 2)),
        isRead: isRead,
        description: _getDescription(types[typeIndex], currentIndex),
        imageUrl: imageUrl,
      );
    });
  }

  // 알림 타입별 설명 생성
  String _getDescription(String type, int index) {
    switch (type) {
      case 'like':
        return '회원님의 ${index % 2 == 0 ? '게시글' : '댓글'}에 좋아요를 눌렀습니다.';
      case 'comment':
        return '회원님의 게시글에 댓글을 남겼습니다. "${index % 3 == 0 ? '정말 좋은 내용이네요!' : '함께 공부해요~'}"';
      case 'follow':
        return '회원님을 팔로우하기 시작했습니다.';
      case 'mention':
        return '게시글에서 회원님을 언급했습니다: "${index % 2 == 0 ? '@개발자님 도움 필요해요' : '@개발자님 감사합니다'}"';
      default:
        return '새로운 알림이 있습니다.';
    }
  }

  @override
  Future<List<NotificationDto>> fetchNotifications(String userId) async {
    print('fetchNotifications 호출됨: userId=$userId');
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 해당 사용자의 알림이 없으면 빈 목록 반환
    final notifications = _userNotifications[userId] ?? [];
    print('사용자($userId)의 알림 수: ${notifications.length}');
    return notifications;
  }

  @override
  Future<bool> markAsRead(String userId, String notificationId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 특정 사용자의 알림만 조회 (효율적)
    final notifications = _userNotifications[userId];
    if (notifications == null) return false;

    // 해당 ID의 알림 찾기
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

    return false; // 알림을 찾지 못함
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    final notifications = _userNotifications[userId];
    if (notifications == null) return false;

    // 해당 사용자의 모든 알림을 읽음 처리
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
  Future<bool> deleteNotification(String userId, String notificationId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 특정 사용자의 알림만 조회 (효율적)
    final notifications = _userNotifications[userId];
    if (notifications == null) return false;

    // 해당 ID를 가진 알림 삭제
    final originalLength = notifications.length;
    _userNotifications[userId] =
        notifications
            .where((notification) => notification.id != notificationId)
            .toList();

    // 목록 길이가 변경되었다면 삭제된 것
    return _userNotifications[userId]!.length < originalLength;
  }
}
