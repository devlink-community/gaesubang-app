import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM 초기화 및 이벤트 처리를 담당하는 서비스
class FCMService {
  // 싱글톤 인스턴스
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 알림 클릭 이벤트 스트림
  final StreamController<NotificationPayload> _onNotificationTapStream =
      StreamController<NotificationPayload>.broadcast();
  Stream<NotificationPayload> get onNotificationTap =>
      _onNotificationTapStream.stream;

  bool _isInitialized = false;

  /// FCM 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('FCM Service 이미 초기화됨');
      return;
    }

    try {
      debugPrint('=== FCM Service 초기화 시작 ===');

      // 1. 권한 요청 먼저 수행
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        debugPrint('FCM 권한이 거부되어 초기화를 중단합니다.');
        return;
      }

      // 2. 앱이 실행중이지 않을 때 받은 알림 처리
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('앱 시작 시 초기 메시지 감지: ${initialMessage.messageId}');
        _handleRemoteMessage(initialMessage);
      }

      // 3. 포그라운드 알림 설정
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. 로컬 알림 설정 (Android)
      if (Platform.isAndroid) {
        await _setupLocalNotifications();
      }

      // 5. FCM 토큰 얻기 및 로그
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token 획득 성공: ${token.substring(0, 20)}...');
      } else {
        debugPrint('FCM Token 획득 실패');
      }

      // 6. 각 상태별 메시지 핸들러 등록
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 7. 토큰 갱신 리스너 설정
      _firebaseMessaging.onTokenRefresh.listen((token) {
        debugPrint('FCM Token 갱신됨: ${token.substring(0, 20)}...');
      });

      _isInitialized = true;
      debugPrint('=== FCM Service 초기화 완료 ===');
    } catch (e, stackTrace) {
      debugPrint('FCM Service 초기화 실패: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// 로컬 알림 채널 설정 (Android 전용)
  Future<void> _setupLocalNotifications() async {
    debugPrint('Android 로컬 알림 채널 설정 시작');

    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('로컬 알림 클릭됨: ${response.payload}');
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload) as Map<String, dynamic>;
            _onNotificationTapStream.add(NotificationPayload.fromJson(data));
          } catch (e) {
            debugPrint('알림 페이로드 파싱 오류: $e');
          }
        }
      },
    );

    // Android 고중요도 채널 생성
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint('Android 알림 채널 생성 완료');
  }

  /// 포그라운드 메시지 처리 (앱이 열려있을 때)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('=== 포그라운드 메시지 수신 ===');
    debugPrint('메시지 ID: ${message.messageId}');
    debugPrint('제목: ${message.notification?.title}');
    debugPrint('내용: ${message.notification?.body}');
    debugPrint('데이터: ${message.data}');

    final notification = message.notification;
    if (notification != null) {
      // Android에서는 포그라운드일 때 알림이 자동으로 표시되지 않으므로 수동으로 표시
      if (Platform.isAndroid) {
        await _showLocalNotification(message);
      }
    }
  }

  /// 로컬 알림 표시 (Android 포그라운드용)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final payload = NotificationPayload(
        title: notification.title ?? '',
        body: notification.body ?? '',
        type: _getNotificationType(message.data['type']),
        targetId: message.data['targetId'] ?? '',
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(payload.toJson()),
      );

      debugPrint('로컬 알림 표시 완료');
    } catch (e) {
      debugPrint('로컬 알림 표시 실패: $e');
    }
  }

  /// 원격 메시지 열기 처리 (백그라운드에서 알림 탭)
  void _handleRemoteMessage(RemoteMessage message) {
    debugPrint('=== 원격 메시지 열기 ===');
    debugPrint('메시지 ID: ${message.messageId}');
    debugPrint('데이터: ${message.data}');

    final notification = message.notification;
    if (notification != null) {
      final payload = NotificationPayload(
        title: notification.title ?? '',
        body: notification.body ?? '',
        type: _getNotificationType(message.data['type']),
        targetId: message.data['targetId'] ?? '',
      );

      _onNotificationTapStream.add(payload);
      debugPrint('알림 탭 이벤트 스트림에 추가됨');
    }
  }

  /// 문자열 타입을 NotificationType으로 변환
  NotificationType _getNotificationType(String? type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      default:
        debugPrint('알 수 없는 알림 타입: $type');
        return NotificationType.comment;
    }
  }

  /// FCM 알림 권한 요청
  Future<bool> requestPermission() async {
    try {
      debugPrint('FCM 권한 요청 시작');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('FCM 권한 요청 결과: ${settings.authorizationStatus}');
      debugPrint('권한 승인됨: $isAuthorized');

      // iOS에서 추가 권한 확인
      if (Platform.isIOS) {
        debugPrint('iOS 추가 권한 - Alert: ${settings.alert}');
        debugPrint('iOS 추가 권한 - Badge: ${settings.badge}');
        debugPrint('iOS 추가 권한 - Sound: ${settings.sound}');
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('FCM 권한 요청 실패: $e');
      return false;
    }
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM 토큰 조회 성공: ${token.substring(0, 20)}...');
      } else {
        debugPrint('FCM 토큰 조회 실패: null 반환');
      }
      return token;
    } catch (e) {
      debugPrint('FCM 토큰 조회 오류: $e');
      return null;
    }
  }

  /// 권한 상태 확인
  Future<bool> hasPermission() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FCM 권한 상태 확인 실패: $e');
      return false;
    }
  }

  /// 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('토픽 구독 성공: $topic');
    } catch (e) {
      debugPrint('토픽 구독 실패: $e');
    }
  }

  /// 특정 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('토픽 구독 해제 성공: $topic');
    } catch (e) {
      debugPrint('토픽 구독 해제 실패: $e');
    }
  }

  /// FCM 연결 테스트 (디버그용)
  Future<void> testFCMConnection() async {
    debugPrint('=== FCM 연결 테스트 시작 ===');

    // 1. 권한 확인
    final hasPermission = await this.hasPermission();
    debugPrint('권한 상태: $hasPermission');

    // 2. 토큰 확인
    final token = await getToken();
    debugPrint('토큰 상태: ${token != null ? "있음" : "없음"}');

    // 3. 초기화 상태 확인
    debugPrint('초기화 상태: $_isInitialized');

    debugPrint('=== FCM 연결 테스트 완료 ===');
  }

  /// 서비스 정리 (메모리 누수 방지)
  void dispose() {
    _onNotificationTapStream.close();
  }
}

/// 백그라운드 메시지 처리 핸들러 (반드시 최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('=== 백그라운드 메시지 수신 ===');
  debugPrint('메시지 ID: ${message.messageId}');
  debugPrint('제목: ${message.notification?.title}');
  debugPrint('내용: ${message.notification?.body}');
  debugPrint('데이터: ${message.data}');
}

/// 알림 페이로드 모델
class NotificationPayload {
  final String title;
  final String body;
  final NotificationType type;
  final String targetId;

  NotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type.name,
    'targetId': targetId,
  };

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _typeFromString(json['type']),
      targetId: json['targetId'] ?? '',
    );
  }

  static NotificationType _typeFromString(String? type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.comment;
    }
  }
}
