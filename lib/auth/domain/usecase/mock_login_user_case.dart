import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/model/user.dart';
import '../../domain/usecase/login_use_case.dart';

class MockLoginUseCase implements LoginUseCase {
  @override
  Future<AsyncValue<User>> execute({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 실제 로그인처럼 딜레이 추가

    return const AsyncData(
      User(id: 'mock-id', email: 'mock@example.com', nickname: 'MockUser'),
    );
  }
}
