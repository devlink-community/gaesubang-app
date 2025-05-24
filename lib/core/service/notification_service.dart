// lib/core/service/notification_service.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_settings/app_settings.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 로컬 알림을 관리하는 서비스 클래스
/// 앱 내 모든 알림은 이 서비스를 통해 처리
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 초기화 메서드 - 앱 시작 시 main.dart에서 호출
  Future<void> init({bool requestPermissionOnInit = false}) async {
    // 안드로이드 설정
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정 - 권한 요청 없이 초기화만 수행
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false, // 변경: 초기화 시 권한 요청 안함
          requestBadgePermission: false, // 변경: 초기화 시 권한 요청 안함
          requestSoundPermission: false, // 변경: 초기화 시 권한 요청 안함
        );

    // 초기화 설정
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    // 플러그인 초기화
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 선택적으로 권한 요청
    if (requestPermissionOnInit) {
      await requestPermission();
    }
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      // 안드로이드에서는 직접 권한 요청 API 사용
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidPlugin != null) {
          // 최신 API에서는 requestNotificationsPermission() 메서드 사용
          return await androidPlugin.requestNotificationsPermission() ?? false;
        }
        return false;
      } catch (e) {
        AppLogger.error(
          '알림 권한 요청 에러',
          tag: 'NotificationService',
          error: e,
        );
        return false;
      }
    } else if (Platform.isIOS) {
      // iOS에서는 이미 init 시 권한 요청됨
      return true;
    }
    return false;
  }

  /// 알림 설정 화면으로 이동
  Future<void> openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        // 안드로이드에서는 앱 설정 화면으로 이동
        // 패키지 이름을 동적으로 가져옴
        final packageInfo = await PackageInfo.fromPlatform();
        final AndroidIntent intent = AndroidIntent(
          action: 'android.settings.APP_NOTIFICATION_SETTINGS',
          arguments: <String, String>{
            'android.provider.extra.APP_PACKAGE': packageInfo.packageName,
          },
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        // iOS에서는 설정 앱 열기
        await AppSettings.openAppSettings();
      }
    } catch (e) {
      // 설정 화면 열기 실패 시 사용자에게 안내
      AppLogger.error(
        '알림 설정 화면 열기 실패',
        tag: 'NotificationService',
        error: e,
      );

      // 필요 시 직접적인 알림(예: SnackBar, Dialog) 표시를 위한 콜백이나
      // 상태 업데이트를 이곳에 구현 (현재는 로깅만 수행)
      // 주의: 다른 UI 컴포넌트와의 결합을 피하기 위해 직접 UI 요소는 생성하지 않음
    }
  }

  /// 알림 탭 이벤트 처리
  void _onNotificationTap(NotificationResponse response) {
    // 알림 탭 시 액션 처리 (필요한 경우 라우팅 등)
    if (response.payload != null) {
      // 페이로드 기반 액션 (예: 특정 화면으로 이동)
      AppLogger.info(
        '알림 탭: ${response.payload}',
        tag: 'NotificationService',
      );
    }
  }

  /// 타이머 종료 알림 표시
  Future<void> showTimerEndedNotification({
    required String groupName,
    required int elapsedSeconds,
    String titlePrefix = '', // 앱 종료 시 접두사 추가
  }) async {
    // 시간 포맷팅 (HH:MM:SS)
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    final timeStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // 안드로이드 알림 상세 설정
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'timer_channel',
          '타이머 알림',
          channelDescription: '타이머 관련 알림 채널입니다.',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          color: Color(0xFF8080FF),
          ledColor: Color(0xFF8080FF),
          ledOnMs: 1000,
          ledOffMs: 500,
        );

    // iOS 알림 상세 설정
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // 플랫폼 통합 알림 상세 설정
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 알림 표시 (타이틀에 접두사 추가)
    await _flutterLocalNotificationsPlugin.show(
      0, // 알림 ID
      '${titlePrefix}타이머가 종료되었습니다',
      '$groupName 그룹의 타이머가 종료되었습니다. (집중 시간: $timeStr)',
      details,
      payload: 'timer_ended', // 알림 탭 시 사용할 페이로드
    );
  }

  /// 알림 취소
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}