// lib/onboarding/presentation/splash_screen_root.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:devlink_mobile_app/onboarding/presentation/splash_screen.dart';

class SplashScreenRoot extends ConsumerStatefulWidget {
  const SplashScreenRoot({super.key});

  @override
  ConsumerState<SplashScreenRoot> createState() => _SplashScreenRootState();
}

class _SplashScreenRootState extends ConsumerState<SplashScreenRoot> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // 스플래시 화면 표시 후 2초 후에 온보딩으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/onboarding'); // 명시적으로 온보딩으로 이동
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
