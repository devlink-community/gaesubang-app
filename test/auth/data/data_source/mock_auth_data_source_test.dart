import 'package:devlink_mobile_app/auth/data/data_source/mock_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAuthDataSource dataSource;

  setUp(() {
    dataSource = MockAuthDataSource();
  });

  group('MockAuthDataSource', () {
    test('fetchLogin 성공 테스트', () async {
      final result = await dataSource.fetchLogin(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result['email'], 'test@example.com');
      expect(result['nickname'], 'MockUser');
    });

    test('fetchLogin 실패 테스트', () async {
      expect(
        () => dataSource.fetchLogin(
          email: 'wrong@example.com',
          password: 'wrongpassword',
        ),
        throwsException,
      );
    });

    test('createUser 성공 테스트', () async {
      final result = await dataSource.createUser(
        email: 'newuser@example.com',
        password: 'password123',
        nickname: 'NewUser',
      );

      expect(result['email'], 'newuser@example.com');
      expect(result['nickname'], 'NewUser');
    });

    test('createUser 실패 테스트 (이메일 중복)', () async {
      expect(
        () => dataSource.createUser(
          email: 'duplicate@example.com',
          password: 'password123',
          nickname: 'DuplicateUser',
        ),
        throwsException,
      );
    });

    test('fetchCurrentUser 반환 테스트', () async {
      await dataSource.fetchLogin(
        email: 'test@example.com',
        password: 'password123',
      );
      final user = await dataSource.fetchCurrentUser();

      expect(user, isNotNull);
      expect(user!['nickname'], 'MockUser');
    });

    test('signOut 이후 fetchCurrentUser는 null 반환', () async {
      await dataSource.fetchLogin(
        email: 'test@example.com',
        password: 'password123',
      );
      await dataSource.signOut();
      final user = await dataSource.fetchCurrentUser();

      expect(user, isNull);
    });
  });
}
