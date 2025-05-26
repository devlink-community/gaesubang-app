import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/service/global_navigation_service.dart';
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
  final GlobalNavigationService _navigationService = GlobalNavigationService();

  // 알림 클릭 이벤트 스트림
  final StreamController<NotificationPayload> _onNotificationTapStream =
      StreamController<NotificationPayload>.broadcast();
  Stream<NotificationPayload> get onNotificationTap =>
      _onNotificationTapStream.stream;

  bool _isInitialized = false;

  /// FCM 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('FCM Service 이미 초기화됨', tag: 'FCMService');
      return;
    }

    try {
      AppLogger.logBanner('FCM Service 초기화 시작');

      // 1. 권한 요청 먼저 수행 (iOS 개선)
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        AppLogger.warning('FCM 권한이 거부되어 초기화를 중단합니다', tag: 'FCMService');
        return;
      }

      // 2. iOS 전용: APNs 토큰 대기 및 확인
      if (Platform.isIOS) {
        final apnsReady = await _waitForAPNsToken();
        if (!apnsReady) {
          AppLogger.error('APNs 토큰 준비 실패 - FCM 초기화 중단', tag: 'FCMService');
          return;
        }
      }

      // 3. 앱이 실행중이지 않을 때 받은 알림 처리
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info(
          '앱 시작 시 초기 메시지 감지: ${initialMessage.messageId}',
          tag: 'FCMService',
        );
        // 앱 시작 시에는 약간의 지연 후 처리
        Future.delayed(const Duration(seconds: 2), () {
          _handleRemoteMessageWithNavigation(initialMessage, isAppLaunch: true);
        });
      }

      // 4. 포그라운드 알림 설정
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. 로컬 알림 설정 (Android)
      if (Platform.isAndroid) {
        await _setupLocalNotifications();
      }

      // 6. FCM 토큰 얻기 및 로그 (이제 안전함)
      final token = await getToken(); // 개선된 getToken() 사용
      if (token != null) {
        AppLogger.info(
          'FCM Token 획득 성공: ${token.substring(0, 20)}...',
          tag: 'FCMService',
        );
      } else {
        AppLogger.warning('FCM Token 획득 실패', tag: 'FCMService');
      }

      // 7. 각 상태별 메시지 핸들러 등록
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleRemoteMessageWithNavigation(message, isAppLaunch: false);
      });
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 8. 토큰 갱신 리스너 설정
      _firebaseMessaging.onTokenRefresh.listen((token) {
        AppLogger.info(
          'FCM Token 갱신됨: ${token.substring(0, 20)}...',
          tag: 'FCMService',
        );
      });

      _isInitialized = true;
      AppLogger.logBanner('FCM Service 초기화 완료');
    } catch (e, stackTrace) {
      AppLogger.severe(
        'FCM Service 초기화 실패',
        tag: 'FCMService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _waitForAPNsToken() async {
    AppLogger.info('iOS APNs 토큰 대기 시작', tag: 'FCMService');

    const maxWaitTime = 10; // 최대 10초 대기
    const checkInterval = Duration(milliseconds: 500); // 0.5초마다 확인

    for (int i = 0; i < (maxWaitTime * 2); i++) {
      final apnsToken = await _firebaseMessaging.getAPNSToken();

      if (apnsToken != null) {
        AppLogger.info(
          'APNs 토큰 획득 성공 (${(i * 0.5).toStringAsFixed(1)}초 후)',
          tag: 'FCMService',
        );
        return true;
      }

      if (i % 4 == 0) {
        // 2초마다 로그
        AppLogger.debug(
          'APNs 토큰 대기 중... (${(i * 0.5).toStringAsFixed(1)}초)',
          tag: 'FCMService',
        );
      }

      await Future.delayed(checkInterval);
    }

    AppLogger.error('APNs 토큰 대기 시간 초과 ($maxWaitTime초)', tag: 'FCMService');
    return false;
  }

  /// 로컬 알림 채널 설정 (Android 전용)
  Future<void> _setupLocalNotifications() async {
    AppLogger.info('Android 로컬 알림 채널 설정 시작', tag: 'FCMLocalNotification');

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
        AppLogger.info(
          '로컬 알림 클릭됨: ${response.payload}',
          tag: 'FCMLocalNotification',
        );
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload) as Map<String, dynamic>;
            final notificationPayload = NotificationPayload.fromJson(data);

            // 로컬 알림 클릭 시에도 네비게이션 처리
            _handleNotificationNavigation(notificationPayload);

            _onNotificationTapStream.add(notificationPayload);
          } catch (e) {
            AppLogger.error(
              '알림 페이로드 파싱 오류',
              tag: 'FCMLocalNotification',
              error: e,
            );
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

    AppLogger.info('Android 알림 채널 생성 완료', tag: 'FCMLocalNotification');
  }

  /// 포그라운드 메시지 처리 (앱이 열려있을 때)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.logBox('포그라운드 메시지 수신', '''
메시지 ID: ${message.messageId}
제목: ${message.notification?.title}
내용: ${message.notification?.body}
데이터: ${message.data}''');

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
        senderId: message.data['senderId'],
        additionalData: Map<String, dynamic>.from(message.data),
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

      AppLogger.info('로컬 알림 표시 완료', tag: 'FCMLocalNotification');
    } catch (e) {
      AppLogger.error('로컬 알림 표시 실패', tag: 'FCMLocalNotification', error: e);
    }
  }

  /// 원격 메시지 열기 처리 (백그라운드에서 알림 탭) - 네비게이션 포함
  void _handleRemoteMessageWithNavigation(
    RemoteMessage message, {
    required bool isAppLaunch,
  }) {
    AppLogger.logBox('원격 메시지 열기 (네비게이션 포함)', '''
메시지 ID: ${message.messageId}
데이터: ${message.data}
앱 런치: $isAppLaunch''');

    final notification = message.notification;
    if (notification != null) {
      final payload = NotificationPayload(
        title: notification.title ?? '',
        body: notification.body ?? '',
        type: _getNotificationType(message.data['type']),
        targetId: message.data['targetId'] ?? '',
        senderId: message.data['senderId'],
        additionalData: Map<String, dynamic>.from(message.data),
      );

      // 스트림에 이벤트 추가 (기존 로직 유지)
      _onNotificationTapStream.add(payload);

      // 네비게이션 처리 (새로운 기능)
      _handleNotificationNavigation(payload, isAppLaunch: isAppLaunch);

      AppLogger.info('알림 탭 이벤트 스트림에 추가됨', tag: 'FCMRemoteMessage');
    }
  }

  /// 기존 원격 메시지 처리 (호환성 유지)
  void _handleRemoteMessage(RemoteMessage message) {
    _handleRemoteMessageWithNavigation(message, isAppLaunch: false);
  }

  /// 알림 클릭 시 네비게이션 처리
  Future<void> _handleNotificationNavigation(
    NotificationPayload payload, {
    bool isAppLaunch = false,
  }) async {
    try {
      AppLogger.logBox('알림 네비게이션 처리 시작', '''
타입: ${payload.type.name}
타겟 ID: ${payload.targetId}
발송자 ID: ${payload.senderId}
앱 런치: $isAppLaunch''');

      if (isAppLaunch) {
        // 앱 시작 시에는 앱 상태 기반 네비게이션 사용
        await _navigationService.handleAppStateNavigation(
          type: payload.type.name,
          targetId: payload.targetId,
          senderId: payload.senderId,
          additionalData: payload.additionalData,
        );
      } else {
        // 일반적인 경우에는 바로 네비게이션
        await _navigationService.handleNotificationNavigation(
          type: payload.type.name,
          targetId: payload.targetId,
          senderId: payload.senderId,
          additionalData: payload.additionalData,
        );
      }

      AppLogger.info('알림 네비게이션 처리 완료', tag: 'FCMNavigation');
    } catch (e) {
      AppLogger.error('알림 네비게이션 처리 실패', tag: 'FCMNavigation', error: e);
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
        AppLogger.debug('알 수 없는 알림 타입: $type', tag: 'FCMTypeConverter');
        return NotificationType.comment;
    }
  }

  /// FCM 알림 권한 요청
  Future<bool> requestPermission() async {
    try {
      AppLogger.info('FCM 권한 요청 시작', tag: 'FCMPermission');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true, // iOS 중요: provisional 권한으로 시작
        criticalAlert: false,
        announcement: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      AppLogger.logState('FCM 권한 요청 결과', {
        'authorizationStatus': settings.authorizationStatus.toString(),
        'isAuthorized': isAuthorized,
      });

      // iOS에서 추가 권한 상세 정보
      if (Platform.isIOS) {
        AppLogger.logState('iOS 세부 권한', {
          'alert': settings.alert.toString(),
          'badge': settings.badge.toString(),
          'sound': settings.sound.toString(),
          'criticalAlert': settings.criticalAlert.toString(),
          'announcement': settings.announcement.toString(),
        });
      }

      return isAuthorized;
    } catch (e) {
      AppLogger.error('FCM 권한 요청 실패', tag: 'FCMPermission', error: e);
      return false;
    }
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() async {
    try {
      AppLogger.info('FCM 토큰 요청 시작', tag: 'FCMToken');

      // iOS에서는 이미 APNs 토큰이 준비되어 있어야 함 (initialize에서 확인됨)
      if (Platform.isIOS) {
        // 한 번 더 확인 (안전장치)
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          AppLogger.warning('APNs 토큰이 여전히 없습니다', tag: 'FCMToken');
          return null;
        }
        AppLogger.debug('APNs 토큰 확인됨', tag: 'FCMToken');
      }

      final token = await _firebaseMessaging.getToken();

      if (token != null) {
        AppLogger.info(
          'FCM 토큰 조회 성공: ${token.substring(0, 20)}...',
          tag: 'FCMToken',
        );
      } else {
        AppLogger.warning('FCM 토큰 조회 실패: null 반환', tag: 'FCMToken');
      }

      return token;
    } catch (e) {
      AppLogger.error('FCM 토큰 조회 오류', tag: 'FCMToken', error: e);
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
      AppLogger.error('FCM 권한 상태 확인 실패', tag: 'FCMPermission', error: e);
      return false;
    }
  }

  /// 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.info('토픽 구독 성공: $topic', tag: 'FCMTopic');
    } catch (e) {
      AppLogger.error('토픽 구독 실패', tag: 'FCMTopic', error: e);
    }
  }

  /// 특정 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.info('토픽 구독 해제 성공: $topic', tag: 'FCMTopic');
    } catch (e) {
      AppLogger.error('토픽 구독 해제 실패', tag: 'FCMTopic', error: e);
    }
  }

  /// FCM 연결 테스트 (디버그용)
  Future<void> testFCMConnection() async {
    AppLogger.logBanner('FCM 연결 테스트 시작');

    // 1. 권한 확인
    final hasPermission = await this.hasPermission();
    AppLogger.info('권한 상태: $hasPermission', tag: 'FCMTest');

    // 2. 토큰 확인
    final token = await getToken();
    AppLogger.info('토큰 상태: ${token != null ? "있음" : "없음"}', tag: 'FCMTest');

    // 3. 초기화 상태 확인
    AppLogger.info('초기화 상태: $_isInitialized', tag: 'FCMTest');

    // 4. 네비게이션 서비스 상태 확인
    _navigationService.diagnose();

    AppLogger.logBanner('FCM 연결 테스트 완료');
  }

  /// 서비스 정리 (메모리 누수 방지)
  void dispose() {
    AppLogger.info('FCMService 정리 시작', tag: 'FCMService');
    _onNotificationTapStream.close();
    AppLogger.info('FCMService 정리 완료', tag: 'FCMService');
  }
}

/// 백그라운드 메시지 처리 핸들러 (반드시 최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // 백그라운드 핸들러에서는 AppLogger 대신 debugPrint 사용
  // (백그라운드 isolate에서는 AppLogger가 제대로 초기화되지 않을 수 있음)
  if (kDebugMode) {
    debugPrint('=== 백그라운드 메시지 수신 ===');
    debugPrint('메시지 ID: ${message.messageId}');
    debugPrint('제목: ${message.notification?.title}');
    debugPrint('내용: ${message.notification?.body}');
    debugPrint('데이터: ${message.data}');
  }
  return;
}

/// 알림 페이로드 모델 (확장)
class NotificationPayload {
  final String title;
  final String body;
  final NotificationType type;
  final String targetId;
  final String? senderId;
  final Map<String, dynamic>? additionalData;

  NotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    this.senderId,
    this.additionalData,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type.name,
    'targetId': targetId,
    'senderId': senderId,
    'additionalData': additionalData,
  };

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _typeFromString(json['type']),
      targetId: json['targetId'] ?? '',
      senderId: json['senderId'],
      additionalData: json['additionalData'] as Map<String, dynamic>?,
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
