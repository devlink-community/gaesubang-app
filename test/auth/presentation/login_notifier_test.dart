import 'package:devlink_mobile_app/auth/domain/usecase/mock_login_user_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/login_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('LoginNotifier (with MockLoginUseCase)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [loginUseCaseProvider.overrideWithValue(MockLoginUseCase())],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('login 성공 시 user가 설정되고 isLoading이 false가 된다', () async {
      final notifier = container.read(loginNotifierProvider.notifier);

      await notifier.login('test@example.com', 'password123');
      final state = container.read(loginNotifierProvider);

      expect(state.isLoading, isFalse);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'mock@example.com');
      expect(state.user!.id, 'mock-id');
      expect(state.user!.nickname, 'MockUser');
      expect(state.errorMessage, isNull);
    });
  });
}
