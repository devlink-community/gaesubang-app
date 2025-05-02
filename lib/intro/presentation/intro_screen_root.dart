import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'intro_notifier.dart';
import 'intro_screen.dart';

class IntroScreenRoot extends ConsumerWidget {
  const IntroScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(introNotifierProvider.notifier);
    final state = ref.watch(introNotifierProvider);

    return state.when(
      data: (data) => IntroScreen(state: data, onAction: notifier.onAction),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
