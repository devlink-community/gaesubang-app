import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 그룹 타이머 테스트용 메인 파일
///
/// 명령어: flutter run -t lib/group/group_timer_test.dart
void main() {
  // 테스트용 그룹 ID
  const testGroupId = 'group_0';

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: '그룹 타이머 테스트',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const GroupTimerTestScreen(groupId: testGroupId),
      ),
    ),
  );
}

/// 그룹 타이머 테스트 화면 래퍼
class GroupTimerTestScreen extends StatelessWidget {
  final String groupId;

  const GroupTimerTestScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return GroupTimerScreenRoot(groupId: groupId);
  }
}
