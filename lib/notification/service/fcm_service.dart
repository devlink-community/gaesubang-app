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
    if (_isInitialized) return;

    // 앱이 실행중이지 않을 때 받은 알림 처리
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessage(initialMessage);
    }

    // 포그라운드 알림 설정
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 채널 설정
    if (Platform.isAndroid) {
      await _setupLocalNotifications();
    }

    // FCM 토큰 얻기
    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // 각 상태별 메시지 핸들러 등록
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
    debugPrint('FCM Service initialized');
  }

  /// 로컬 알림 채널 설정 (Android 전용)
  Future<void> _setupLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload) as Map<String, dynamic>;
            _onNotificationTapStream.add(NotificationPayload.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Android 채널 생성
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// 포그라운드 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    // Android에서는 로컬 알림으로 표시
    if (Platform.isAndroid) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        final payload = NotificationPayload(
          title: notification.title ?? '',
          body: notification.body ?? '',
          type: _getNotificationType(message.data['type']),
          targetId: message.data['targetId'] ?? '',
        );

        _localNotifications.show(
          message.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              icon: android.smallIcon,
            ),
          ),
          payload: json.encode(payload.toJson()),
        );
      }
    }
  }

  /// 원격 메시지 열기 처리
  void _handleRemoteMessage(RemoteMessage message) {
    debugPrint('Remote message opened: ${message.messageId}');
    final notification = message.notification;

    if (notification != null) {
      final payload = NotificationPayload(
        title: notification.title ?? '',
        body: notification.body ?? '',
        type: _getNotificationType(message.data['type']),
        targetId: message.data['targetId'] ?? '',
      );

      _onNotificationTapStream.add(payload);
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
        return NotificationType.comment;
    }
  }

  /// FCM 토큰 갱신 리스너 등록
  void setupTokenRefreshListener(Function(String) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen((token) {
      debugPrint('FCM Token refreshed: $token');
      onTokenRefresh(token);
    });
  }

  /// FCM 알림 권한 요청
  Future<bool> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// 특정 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
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
  debugPrint('Background message received: ${message.messageId}');
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
