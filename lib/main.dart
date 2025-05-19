import 'package:devlink_mobile_app/core/router/app_router.dart';
import 'package:devlink_mobile_app/core/service/notification_service.dart';
import 'package:devlink_mobile_app/core/styles/app_theme.dart';
import 'package:devlink_mobile_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 알림 서비스 초기화 - 권한 요청 없이
  await NotificationService().init(requestPermissionOnInit: false);

  // await NaverMapSdk.instance.initialize(
  //   clientId: 'ye49o0dcu6',

  //   onAuthFailed: (ex) {
  //     print("********* 네이버맵 인증오류 : $ex *********");
  //   },
  // );

  // 환경에 따라 클라이언트 ID를 가져오는 방식으로 변경
  final naverMapClientId = const String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'ye49o0dcu6', // 개발 환경용 기본값
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Flutter Demo',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // 라이트 테마 적용
      darkTheme: AppTheme.darkTheme, // 다크 테마 적용
      themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 변경
    );
  }
}
