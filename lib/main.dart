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

  // 로거 초기화 (가장 먼저)
  AppLogger.initialize();
  
  AppLogger.info(
    'Flutter 바인딩 초기화 완료',
    tag: 'AppInit',
  );

  try {
    // 앱 초기화 (Firebase, FCM, 기타 서비스)
    AppLogger.logStep(1, 3, '앱 서비스 초기화 시작');
    await AppInitializationService.initialize();
    
    AppLogger.info(
      '앱 초기화 서비스 완료',
      tag: 'AppInit',
    );

    // API 로깅 초기화 (필요시)
    AppLogger.logStep(2, 3, 'API 로깅 시스템 초기화');
    _initializeApiLogging();

    // 앱 실행
    AppLogger.logStep(3, 3, '앱 실행 시작');
    AppLogger.logBanner('개수방 앱 시작! 🚀');
    
    runApp(const ProviderScope(child: MyApp()));
    
  } catch (e, st) {
    AppLogger.severe(
      '앱 초기화 중 치명적 오류 발생',
      tag: 'AppInit',
      error: e,
      stackTrace: st,
    );
    
    // 앱 초기화 실패 시에도 기본 앱은 실행하되, 오류 상태 표시
    runApp(const ProviderScope(child: ErrorApp()));
  }
}

/// API 로깅 초기화 (개발/디버그 모드에서만)
void _initializeApiLogging() {
  try {
    ApiCallLogger.printStats();
    
    AppLogger.info(
      'API 로깅 초기화 완료',
      tag: 'ApiLogging',
    );
  } catch (e) {
    AppLogger.error(
      'API 로깅 초기화 실패',
      tag: 'ApiLogging',
      error: e,
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug(
      'MyApp 빌드 시작',
      tag: 'AppWidget',
    );

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

/// 앱 초기화 실패 시 표시할 에러 앱
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '개수방 - 오류',
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '앱 초기화 중 오류가 발생했습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '앱을 다시 시작해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // 앱 재시작 시도 (실제로는 시스템에서 처리해야 함)
                    AppLogger.info(
                      '앱 재시작 버튼 클릭',
                      tag: 'ErrorApp',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}