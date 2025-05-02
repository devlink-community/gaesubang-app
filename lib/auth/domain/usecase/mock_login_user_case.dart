import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/model/member.dart';
import '../../domain/usecase/login_use_case.dart';

class MockLoginUseCase implements LoginUseCase {
  @override
  Future<AsyncValue<Member>> execute({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 실제 로그인처럼 딜레이 추가

    return const AsyncData(
      Member(id: 'mock-id', email: 'mock@example.com', nickname: 'MockUser'),
    );
  }
}
