import 'package:devlink_mobile_app/core/router/app_router.dart';
import 'package:devlink_mobile_app/core/service/app_initialization_service.dart';
import 'package:devlink_mobile_app/core/styles/app_theme.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 초기화 (Firebase, FCM, 기타 서비스)
  await AppInitializationService.initialize();

  // API 로깅 초기화 (필요시)
  _initializeApiLogging();

  // 로거 초기화
  AppLogger.initialize();

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
    );
  }
}
