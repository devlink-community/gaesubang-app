import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/login_use_case.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MockLoginUseCase implements LoginUseCase {
  @override
  Future<AsyncValue<User>> execute({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 실제 로그인처럼 딜레이 추가

    return const AsyncData(
      User(
        id: '0',
        email: 'mock@example.com',
        nickname: 'MockUser',
        uid: 'whatsup',
        onAir: false,
        image: 'mock/image/path',
      ),
    );
  }
}
