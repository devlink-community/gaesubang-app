import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/firebase_options.dart';
import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 앱 초기화를 담당하는 서비스
class AppInitializationService {
  static bool _isInitialized = false;

  /// 앱 초기화 메인 메서드
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('앱이 이미 초기화되어 있습니다.');
      return;
    }

    try {
      debugPrint('=== 개수방 앱 초기화 시작 ===');

      // 1. Firebase 초기화
      await _initializeFirebase();

      // 2. FCM 서비스 초기화
      await _initializeFCM();

      // 3. 기타 서비스 초기화
      await _initializeOtherServices();

      _isInitialized = true;
      debugPrint('=== 개수방 앱 초기화 완료 ===');
    } catch (e, stackTrace) {
      debugPrint('❌ 앱 초기화 중 오류 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
      // 초기화 실패해도 앱은 계속 실행
    }
  }

  /// Firebase 초기화
  static Future<void> _initializeFirebase() async {
    try {
      debugPrint('--- Firebase 초기화 시작 ---');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('✅ Firebase 초기화 완료');
      debugPrint('Firebase Project ID: ${Firebase.app().options.projectId}');

      // 앱 설정 정보 출력
      AppConfig.printConfig();
    } catch (e) {
      debugPrint('❌ Firebase 초기화 실패: $e');
      rethrow;
    }
  }

  /// FCM 서비스 초기화
  static Future<void> _initializeFCM() async {
    try {
      debugPrint('--- FCM 서비스 초기화 시작 ---');

      // FCM 서비스 초기화
      final fcmService = FCMService();
      await fcmService.initialize();

      // 권한 상태 확인
      final fcmTokenService = FCMTokenService();
      final hasPermission = await fcmTokenService.hasNotificationPermission();
      debugPrint('FCM 권한 상태: $hasPermission');

      if (!hasPermission) {
        debugPrint('⚠️ FCM 권한이 없습니다. 로그인 후 권한을 요청합니다.');
      }

      debugPrint('✅ FCM 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ FCM 서비스 초기화 실패: $e');
      // FCM 실패가 앱 전체를 중단시키지 않도록 함
    }
  }

  /// 기타 서비스 초기화
  static Future<void> _initializeOtherServices() async {
    try {
      debugPrint('--- 기타 서비스 초기화 시작 ---');

      // 1. 로컬 알림 서비스 초기화
      await NotificationService().init(requestPermissionOnInit: false);
      debugPrint('✅ 로컬 알림 서비스 초기화 완료');

      // 2. 네이버 맵 초기화
      await _initializeNaverMap();

      debugPrint('✅ 기타 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 기타 서비스 초기화 실패: $e');
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
          debugPrint("❌ 네이버맵 인증오류: $ex");
        },
      );

      debugPrint('✅ 네이버맵 초기화 완료');
    } catch (e) {
      debugPrint("❌ 네이버맵 초기화 실패: $e");
    }
  }

  /// FCM 상태 진단 (필요시 호출)
  static Future<void> diagnose() async {
    try {
      debugPrint('=== FCM 상태 진단 시작 ===');

      final fcmService = FCMService();
      await fcmService.testFCMConnection();

      final fcmTokenService = FCMTokenService();
      final hasPermission = await fcmTokenService.hasNotificationPermission();
      final currentToken = await fcmTokenService.getCurrentDeviceToken();

      debugPrint('FCM 진단 결과:');
      debugPrint('- 권한: $hasPermission');
      debugPrint('- 토큰: ${currentToken != null ? "있음" : "없음"}');

      debugPrint('=== FCM 상태 진단 완료 ===');
    } catch (e) {
      debugPrint('❌ FCM 상태 진단 실패: $e');
    }
  }
}
