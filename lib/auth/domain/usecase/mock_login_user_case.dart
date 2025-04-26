import '../../domain/model/user.dart';
import '../../domain/usecase/login_use_case.dart';

class MockLoginUseCase implements LoginUseCase {
  @override
  Future<User> execute({
    required String email,
    required String password,
  }) async {
    // 여기서 그냥 바로 가짜 데이터 return
    return const User(
      id: 'mock-id',
      email: 'mock@example.com',
      nickname: 'MockUser',
    );
  }
}
