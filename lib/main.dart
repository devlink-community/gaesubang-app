import 'dart:async';

import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/router/app_router.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/core/styles/app_theme.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase 연결 확인 로그 추가
  print('=== Firebase 초기화 완료 ===');
  print('Firebase App Name: ${Firebase.app().name}');
  print('Firebase Project ID: ${Firebase.app().options.projectId}');
  AppConfig.printConfig(); // 설정 정보 출력

  // Firebase Remote Config 초기화 추가
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // 기본값 설정 - 값을 찾지 못할 경우 사용
    await remoteConfig.setDefaults({
      'vertex_ai_key': '', // 비어있는 기본값
    });

    // 설정 가져오기
    final fetchSuccess = await remoteConfig.fetchAndActivate();

    if (fetchSuccess) {
      print('Remote Config 가져오기 성공!');
    } else {
      print('Remote Config 가져오기 실패!');
    }

    final vertexKey = remoteConfig.getString('vertex_ai_key');
    print('Vertex AI 키 존재 여부: ${vertexKey.isNotEmpty ? '있음' : '없음'}');
  } catch (e) {
    print('Remote Config 초기화 중 오류 발생: $e');
  }

  // API 로깅 초기화 및 주기적 통계 출력 설정
  _initializeApiLogging();

  // 알림 서비스 초기화 - 권한 요청 없이
  await NotificationService().init(requestPermissionOnInit: false);

  // 환경에 따라 클라이언트 ID를 가져오는 방식으로 변경
  final naverMapClientId = const String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'uubpy6izp6', // 개발 환경용 기본값
  );

  try {
    await NaverMapSdk.instance.initialize(
      clientId: naverMapClientId,
      onAuthFailed: (ex) {
        print("********* 네이버맵 인증오류 : $ex *********");
        // TODO: 사용자에게 오류 메시지 표시 또는 대체 기능 제공
      },
    );
  } catch (e) {
    print("네이버맵 초기화 실패: $e");
    // TODO: 초기화 실패 시 대체 처리 로직
  }

  runApp(const ProviderScope(child: MyApp()));
}

/// API 로깅 초기화 및 주기적 통계 출력 설정
void _initializeApiLogging() {
  if (!AppConfig.enableApiLogging) return;

  print('=== API 로깅 시스템 초기화 ===');
  print('enableApiLogging: ${AppConfig.enableApiLogging}');
  print('enableVerboseLogging: ${AppConfig.enableVerboseLogging}');
  print('==============================');

  // 5분마다 API 통계 출력
  Timer.periodic(const Duration(minutes: 5), (timer) {
    final activeCalls = ApiCallLogger.getActiveCalls();

    // 활성 호출이 있는 경우 경고
    if (activeCalls > 0) {
      print('⚠️  경고: $activeCalls개의 API 호출이 아직 완료되지 않았습니다');
    }

    // 통계 출력
    ApiCallLogger.printStats();
  });

  // 앱 종료 시 최종 통계 출력
  _setupAppLifecycleListener();
}

/// 앱 생명주기 리스너 설정 (종료 시 최종 통계 출력)
void _setupAppLifecycleListener() {
  if (!AppConfig.enableApiLogging) return;

  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
}

/// 앱 생명주기 관찰자 클래스
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!AppConfig.enableApiLogging) return;

    switch (state) {
      case AppLifecycleState.paused:
        print('=== 앱 일시정지 - API 통계 ===');
        ApiCallLogger.printStats();
        break;
      case AppLifecycleState.detached:
        print('=== 앱 종료 - 최종 API 통계 ===');
        ApiCallLogger.printStats();

        // 완료되지 않은 API 호출 확인
        final activeCalls = ApiCallLogger.getActiveCalls();
        if (activeCalls > 0) {
          print('⚠️  경고: 앱 종료 시 $activeCalls개의 API 호출이 완료되지 않았습니다');
        }

        print('============================');
        break;
      case AppLifecycleState.resumed:
        if (AppConfig.enableVerboseLogging) {
          print('=== 앱 재시작 - API 로깅 시스템 활성 ===');
        }
        break;
      default:
        break;
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Flutter Demo',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 라이트 테마 적용
      darkTheme: AppTheme.darkTheme,
      // 다크 테마 적용
      themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 변경
    );
  }
}
