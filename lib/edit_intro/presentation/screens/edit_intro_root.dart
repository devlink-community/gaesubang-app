import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/screens/edit_intro_screen.dart';

class EditIntroRoot extends ConsumerWidget {
  const EditIntroRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EditIntroScreen();
  }
} 