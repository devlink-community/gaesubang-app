// lib/main.dart - 간단한 ErrorApp 구현

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
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '앱 실행 중 오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '다음 단계를 따라주세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // 단계별 안내
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStep('1', '현재 앱을 완전히 종료하세요'),
                        const SizedBox(height: 16),
                        _buildStep('2', '최근 앱에서 개수방을 제거하세요'),
                        const SizedBox(height: 16),
                        _buildStep('3', '홈 화면에서 앱을 다시 실행하세요'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 추가 안내
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '문제가 계속되면 기기를 재부팅하거나\n앱을 재설치해주세요',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 단계별 안내 위젯
  Widget _buildStep(String number, String description) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}