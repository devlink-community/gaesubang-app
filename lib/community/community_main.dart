import 'package:devlink_mobile_app/community/module/community_router.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(communityRouterProvider);
    return MaterialApp.router(
      title: '커뮤니티 스크린',
      routerConfig: router,
      theme: ThemeData(),
    );
  }
}
