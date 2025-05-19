// lib/core/config/app_config.dart
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
    defaultValue: false, // 개발 편의를 위해 기본값을 true로 설정
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

  /// 디버그 모드 여부
  static const bool isDebug = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  /// Firebase 사용 여부 (Mock과 반대)
  static bool get useFirebase => !useMockAuth;

  /// 환경 정보 출력 (디버그용)
  static void printConfig() {
    if (isDebug) {
      print('=== AppConfig ===');
      print('useMockAuth: $useMockAuth');
      print('useMockGroup: $useMockGroup');
      print('useMockCommunity: $useMockCommunity');
      print('useFirebase: $useFirebase');
      print('================');
    }
  }
}
