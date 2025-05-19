import 'package:devlink_mobile_app/map/presentation/map_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 맵 기능 테스트용 메인 파일
///
/// 명령어: flutter run -t lib/map/module/map_test_main.dart
void main() {
  runApp(const ProviderScope(child: MapTestApp()));
}

class MapTestApp extends StatelessWidget {
  const MapTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '맵 테스트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D5FEF)),
        useMaterial3: true,
      ),
      home: const MapScreenRoot(),
    );
  }
}
