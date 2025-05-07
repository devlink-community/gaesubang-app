import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 수정: 기존 routerProvider 대신 introRouterProvider 를 import
import 'intro/module/intro_route.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 기존 ref.watch(routerProvider) 대신
    final router = ref.watch(introRouterProvider);

    return MaterialApp.router(
      title: 'Flutter Demo',
      routerConfig: router,
      theme: ThemeData(),
    );
  }
}
