import 'package:devlink_mobile_app/core/router/app_router.dart';

import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth/module/auth_di.dart';

void main() {
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
      theme: ThemeData(),
    );
  }
}
