// lib/core/service/app_initialization_service.dart
import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/firebase_options.dart';
import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 앱 초기화를 담당하는 서비스
class AppInitializationService {
  static bool _isInitialized = false;

  /// 앱 초기화 메인 메서드
  static Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('앱이 이미 초기화되어 있습니다', tag: 'AppInit');
      return;
    }

    try {
      AppLogger.logBanner('개수방 앱 초기화 시작');

      // 1. Firebase 초기화
      await _initializeFirebase();

      // 2. FCM 서비스 초기화
      await _initializeFCM();

      // 3. 기타 서비스 초기화
      await _initializeOtherServices();

      _isInitialized = true;
      AppLogger.logBanner('개수방 앱 초기화 완료');
    } catch (e, stackTrace) {
      AppLogger.severe(
        '앱 초기화 중 오류 발생',
        tag: 'AppInit',
        error: e,
        stackTrace: stackTrace,
      );
      // 초기화 실패해도 앱은 계속 실행
    }
  }

  /// Firebase 초기화
  static Future<void> _initializeFirebase() async {
    try {
      AppLogger.logStep(1, 3, 'Firebase 초기화 시작');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      AppLogger.info('Firebase 초기화 완료', tag: 'Firebase');
      AppLogger.info(
        'Firebase Project ID: ${Firebase.app().options.projectId}',
        tag: 'Firebase',
      );

      // 앱 설정 정보 출력
      AppConfig.printConfig();
    } catch (e) {
      AppLogger.error(
        'Firebase 초기화 실패',
        tag: 'Firebase',
        error: e,
      );
      rethrow;
    }
  }

  /// FCM 서비스 초기화
  static Future<void> _initializeFCM() async {
    try {
      AppLogger.logStep(2, 3, 'FCM 서비스 초기화 시작');

      // FCM 서비스 초기화
      final fcmService = FCMService();
      await fcmService.initialize();

      // 권한 상태 확인
      final fcmTokenService = FCMTokenService();
      final hasPermission = await fcmTokenService.hasNotificationPermission();
      AppLogger.info('FCM 권한 상태: $hasPermission', tag: 'FCM');

      if (!hasPermission) {
        AppLogger.warning(
          'FCM 권한이 없습니다. 로그인 후 권한을 요청합니다',
          tag: 'FCM',
        );
      }

      AppLogger.info('FCM 서비스 초기화 완료', tag: 'FCM');
    } catch (e) {
      AppLogger.error(
        'FCM 서비스 초기화 실패',
        tag: 'FCM',
        error: e,
      );
      // FCM 실패가 앱 전체를 중단시키지 않도록 함
    }
  }

  /// 기타 서비스 초기화
  static Future<void> _initializeOtherServices() async {
    try {
      AppLogger.logStep(3, 3, '기타 서비스 초기화 시작');

      // 1. 로컬 알림 서비스 초기화
      await NotificationService().init(requestPermissionOnInit: false);
      AppLogger.info('로컬 알림 서비스 초기화 완료', tag: 'Notification');

      // 2. 네이버 맵 초기화
      await _initializeNaverMap();

      AppLogger.info('기타 서비스 초기화 완료', tag: 'AppInit');
    } catch (e) {
      AppLogger.error(
        '기타 서비스 초기화 실패',
        tag: 'AppInit',
        error: e,
      );
      // 기타 서비스 실패가 앱 전체를 중단시키지 않도록 함
    }
  }

  /// 네이버 맵 초기화
  static Future<void> _initializeNaverMap() async {
    try {
      final naverMapClientId = const String.fromEnvironment(
        'NAVER_MAP_CLIENT_ID',
        defaultValue: 'uubpy6izp6',
      );

      await NaverMapSdk.instance.initialize(
        clientId: naverMapClientId,
        onAuthFailed: (ex) {
          AppLogger.error(
            '네이버맵 인증오류',
            tag: 'NaverMap',
            error: ex,
          );
        },
      );

      AppLogger.info('네이버맵 초기화 완료', tag: 'NaverMap');
    } catch (e) {
      AppLogger.error(
        '네이버맵 초기화 실패',
        tag: 'NaverMap',
        error: e,
      );
    }
  }

  /// FCM 상태 진단 (필요시 호출)
  static Future<void> diagnose() async {
    try {
      AppLogger.logBanner('FCM 상태 진단 시작');

      final fcmService = FCMService();
      await fcmService.testFCMConnection();

      final fcmTokenService = FCMTokenService();
      final hasPermission = await fcmTokenService.hasNotificationPermission();
      final currentToken = await fcmTokenService.getCurrentDeviceToken();

      AppLogger.info('FCM 진단 결과:', tag: 'FCM');
      AppLogger.info('- 권한: $hasPermission', tag: 'FCM');
      AppLogger.info('- 토큰: ${currentToken != null ? "있음" : "없음"}', tag: 'FCM');

      AppLogger.logBanner('FCM 상태 진단 완료');
    } catch (e) {
      AppLogger.error(
        'FCM 상태 진단 실패',
        tag: 'FCM',
        error: e,
      );
    }
  }
}
