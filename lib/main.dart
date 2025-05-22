import 'package:devlink_mobile_app/core/router/app_router.dart';
import 'package:devlink_mobile_app/core/service/app_initialization_service.dart';
import 'package:devlink_mobile_app/core/styles/app_theme.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 초기화 (Firebase, FCM, 기타 서비스)
  await AppInitializationService.initialize();

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  // FCM 서비스 기본 초기화 (사용자별 토큰 등록은 로그인 시 처리)
  final fcmService = FCMService();
  await fcmService.initialize();

  // FCM 기본 권한 요청 (사용자 로그인과 무관하게 처리)
=======
  // FCM 서비스 초기화
  final fcmService = FCMService();
  await fcmService.initialize();
>>>>>>> 66158447 (fix: main 에 fcm 서비스 초기화 추가 완료)
=======
  // FCM 서비스 초기화
  final fcmService = FCMService();
  await fcmService.initialize();
>>>>>>> 01ad0f1e (fix: main 에 fcm 서비스 초기화 추가 완료)
=======
  // FCM 서비스 기본 초기화 (사용자별 토큰 등록은 로그인 시 처리)
  final fcmService = FCMService();
  await fcmService.initialize();

  // FCM 기본 권한 요청 (사용자 로그인과 무관하게 처리)
>>>>>>> 295055be (fix: fcm service 기본 초기화 및 권한 요청, 토큰 등록은 login 시 처리)
  await fcmService.requestPermission();

  // Firebase 연결 확인 로그 추가
  print('=== Firebase 초기화 완료 ===');
  print('Firebase App Name: ${Firebase.app().name}');
  print('Firebase Project ID: ${Firebase.app().options.projectId}');
  AppConfig.printConfig(); // 설정 정보 출력

  // API 로깅 초기화 및 주기적 통계 출력 설정
=======
  // API 로깅 초기화 (필요시)
>>>>>>> f2eb244b (fix: main initialization 분리 후 간소화)
  _initializeApiLogging();

=======
  // API 로깅 초기화 (필요시)
  _initializeApiLogging();

>>>>>>> 93342ffe988801372968965945de141989ff1d54
  // 앱 실행
  runApp(const ProviderScope(child: MyApp()));
}

/// API 로깅 초기화 (개발/디버그 모드에서만)
void _initializeApiLogging() {
  try {
    ApiCallLogger.printStats();
    print('✅ API 로깅 초기화 완료');
  } catch (e) {
    print('API 로깅 초기화 실패: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '개수방',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // 앱 빌드 완료 후 FCM 상태 확인
      builder: (context, child) {
        _performPostBuildCheck();
        return child ?? const SizedBox.shrink();
      },
    );
  }

  /// 앱 빌드 완료 후 상태 확인
  void _performPostBuildCheck() {
    // 2초 후에 FCM 상태 진단 (부담 없이)
    Future.delayed(const Duration(seconds: 2), () {
      AppInitializationService.diagnose();
    });
  }
}
