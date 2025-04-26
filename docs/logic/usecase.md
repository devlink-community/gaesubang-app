# ⚙️ UseCase 설계 가이드

## ✅ 목적

UseCase는 하나의 명확한 도메인 동작을 수행하는 단위로,  
Repository를 통해 데이터를 요청하고,  
ViewModel이 상태를 관리할 수 있도록 **직접 결과 또는 예외를 반환**합니다.

---

## 🧱 설계 원칙

- 하나의 클래스는 하나의 역할만 갖는다 (`Single Responsibility`)
- 클래스명은 `{동작명}UseCase` (예: `LoginUseCase`)
- 반환은 일반 객체 or 예외 throw  
  (Repository에서 Result<T>를 해제하고, UseCase는 ViewModel이 상태를 만들 수 있도록 순수 객체 또는 예외만 반환)
- ViewModel은 `AsyncNotifier`, 상태는 `AsyncValue<T>`로 관리

---

## ✅ 파일 구조 및 위치

```
lib/
└── user/
    └── domain/
        └── usecase/
            ├── login_use_case.dart
            └── update_profile_use_case.dart
```

> 📎 전체 폴더 구조는 [../arch/folder.md](../arch/folder.md)

---

## ✅ 클래스 구성 예시

```dart
class LoginUseCase {
  final UserRepository _repository;

  LoginUseCase(this._repository);

  Future<User> execute(String email, String password) async {
    // Repository에서 받은 Result<T>는 여기서 해제해 ViewModel이 직접 상태 분기를 하도록 한다.
    final result = await _repository.login(email, password);
    return result.when(
      success: (data) => data,
      error: (e) => throw e,
    );
  }
}
```

> 📎 Repository 설계는 [repository.md](repository.md) 참고  
> 📎 예외 변환 전략은 [../arch/error.md](../arch/error.md)

---

## 📌 ViewModel 연동 흐름

```dart
class LoginViewModel extends AsyncNotifier<User> {
  final LoginUseCase _loginUseCase;

  LoginViewModel(this._loginUseCase);

  @override
  FutureOr<User> build() => throw UnimplementedError();

  Future<void> login(String email, String pw) async {
    state = const AsyncLoading();
    try {
      final user = await _loginUseCase.execute(email, pw);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

> 📎 ViewModel 구성은 [../ui/screen.md](../ui/screen.md) 참고

---

## ✅ 테스트 가이드

- Repository를 mock 처리
- 반환값이 기대한 객체인지 검증
- 예외가 발생했을 경우 throw되는지 확인

```dart
test('execute returns User on success', () async {
  when(mockRepository.login(any, any)).thenAnswer(
    (_) async => Result.success(mockUser),
  );

  final user = await useCase.execute('email', 'pw');

  expect(user.email, 'mock@user.com');
});

test('execute throws on failure', () async {
  when(mockRepository.login(any, any)).thenAnswer(
    (_) async => Result.error(Failure('로그인 실패')),
  );

  expect(() => useCase.execute('email', 'pw'), throwsA(isA<Failure>()));
});
```