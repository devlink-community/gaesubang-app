// lib/core/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._(); // 인스턴스화 방지

  /// Auth 기능 Mock/Firebase 전환 설정
  ///
  /// 사용법:
  /// 1. Mock 사용 (기본값):
  ///    flutter run
  ///
  /// 2. Firebase 사용:
  ///    flutter run --dart-define=USE_MOCK_AUTH=false
  ///
  /// 3. 모든 Mock 비활성화:
  ///    flutter run --dart-define=USE_MOCK_AUTH=false --dart-define=USE_MOCK_GROUP=false --dart-define=USE_MOCK_COMMUNITY=false
  ///
  /// 4. VS Code launch.json 설정 예시:
  ///    {
  ///      "name": "Flutter (Firebase)",
  ///      "request": "launch",
  ///      "type": "dart",
  ///      "args": [
  ///        "--dart-define=USE_MOCK_AUTH=false"
  ///      ]
  ///    }
  static const bool useMockAuth = bool.fromEnvironment(
    'USE_MOCK_AUTH',
    defaultValue: false, // 개발 편의를 위해 기본값을 false로 설정
  );

  /// Mock 그룹 데이터 사용 여부
  static const bool useMockGroup = bool.fromEnvironment(
    'USE_MOCK_GROUP',
    defaultValue: false,
  );

  /// Mock 커뮤니티 데이터 사용 여부
  static const bool useMockCommunity = bool.fromEnvironment(
    'USE_MOCK_COMMUNITY',
    defaultValue: false,
  );

  /// Flutter의 기본 디버그 모드 감지
  /// kDebugMode는 --release 플래그가 없으면 true
  static bool get isDebug => kDebugMode;

  /// Firebase 사용 여부 (Mock과 반대)
  static bool get useFirebase => !useMockAuth;

  /// API 호출 로깅 활성화 여부
  /// 기본적으로 디버그 모드에서만 활성화
  /// 필요시 DISABLE_API_LOGGING=true로 끌 수 있음
  static bool get enableApiLogging =>
      isDebug &&
      !const bool.fromEnvironment('DISABLE_API_LOGGING', defaultValue: false);

  /// 상세한 디버깅 로그 활성화 여부
  /// API 호출의 파라미터, 응답 시간, 중복 호출 경고 등 포함
  /// 기본적으로 디버그 모드에서만 활성화, 필요시 추가로 끌 수 있음
  static bool get enableVerboseLogging =>
      isDebug &&
      !const bool.fromEnvironment(
        'DISABLE_VERBOSE_LOGGING',
        defaultValue: false,
      );

  /// 환경 정보 출력 (디버그용)
  static void printConfig() {
    if (isDebug) {
      print('=== AppConfig ===');
      print('isDebug: $isDebug');
      print('useMockAuth: $useMockAuth');
      print('useMockGroup: $useMockGroup');
      print('useMockCommunity: $useMockCommunity');
      print('useFirebase: $useFirebase');
      print('enableApiLogging: $enableApiLogging');
      print('enableVerboseLogging: $enableVerboseLogging');
      print('================');
    }
  }
}
