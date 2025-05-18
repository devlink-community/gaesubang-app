import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'open_source_license_screen.dart';

/// 오픈소스 라이센스 화면의 Root 컴포넌트
/// 상태 주입과 Context 처리를 담당한다
class OpenSourceLicenseScreenRoot extends ConsumerWidget {
  const OpenSourceLicenseScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이 화면은 외부 상태를 주입받거나 액션 처리가 필요 없으므로
    // 단순히 화면을 반환한다
    return const OpenSourceLicenseScreen();
  }
}
