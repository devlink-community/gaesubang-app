# ⚙️ UseCase 설계 가이드

---

## ✅ 목적

UseCase는 하나의 명확한 도메인 동작을 수행하는 단위다.  
Repository를 통해 데이터를 요청하고,  
ViewModel(Notifier)에서 관리할 수 있도록  
**결과를 변환해 반환하는 책임**을 가진다.

---

## 🧱 설계 원칙

- 하나의 UseCase는 하나의 목적(도메인 동작)만 수행한다.
- Repository에서 받은 `Result<T>`를 받아 처리하고,  
  이를 `AsyncValue<T>`로 변환하여 반환한다.
- 예외나 실패는 **Failure 객체**로 변환하며,  
  **Failure를 AsyncError로 감싸서** 상위 계층에 전달한다.
- UseCase는 상태를 직접 관리하지 않고,  
  오직 **변환(Repository → AsyncValue)** 책임만 가진다.

---

## ✅ 파일 구조 및 위치

```text
lib/
└── auth/
    └── domain/
        └── usecase/
            ├── login_use_case.dart
            └── update_profile_use_case.dart
```

---

## ✅ 기본 작성 예시

```dart
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<AsyncValue<User>> execute(String email, String password) async {
    final result = await _repository.login(email, password);

    switch (result) {
      case Success(:final value):
        return AsyncData(value);
      case Error(:final failure):
        return AsyncError(failure);
    }
  }
}
```

✅ 주요 포인트
- `Result<T>` → `AsyncValue<T>` 변환
- 성공은 `AsyncData(value)`
- 실패는 `AsyncError(Failure)` (Failure를 포장해서 전달)

---

## 📌 흐름 요약

```text
Repository → Result<T> 반환
UseCase → Result<T> → AsyncValue<T> 변환
Notifier → AsyncValue<T>를 받아 상태 관리
```

> UseCase는 Result를 직접 다루지 않고  
> ViewModel/Notifier가 바로 사용할 수 있도록 AsyncValue로 변환해준다.

---

## 🔥 상태 처리 흐름 예시

```dart
@riverpod
class LoginNotifier extends _$LoginNotifier {
  late final LoginUseCase _loginUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    return const LoginState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loginUserResult: const AsyncLoading());

    final asyncResult = await _loginUseCase.execute(email, password);

    state = state.copyWith(loginUserResult: asyncResult);
  }
}
```

✅ UseCase는 AsyncValue<User>를 반환하므로  
✅ Notifier에서는 별도의 분기 없이 바로 상태에 반영할 수 있다.

---

## 🔥 실패(Failure) 처리 전략

- Repository 단계에서 Exception을 **Failure 객체**로 변환
- UseCase 단계에서는 이 Failure를 받아 **AsyncError(Failure)** 형태로 포장
- Notifier/Screen에서는 `AsyncValue.when` 또는 `switch`를 통해  
  **Failure.message**를 표시하거나, 필요한 추가 분기를 진행한다.

> 예외(Exception)를 직접 다루지 않고, 항상 **Failure 기준**으로 관리한다.

---

## 📋 책임 구분

| 계층 | 역할 |
|:---|:---|
| Repository | 외부 통신 및 데이터 반환, 실패 시 Failure 포장 |
| UseCase | Result<T>를 받아 AsyncValue<T>로 변환 |
| Notifier | AsyncValue<T>를 관리하고, UI 상태를 구성 |

---

## 🧪 테스트 전략

- Repository를 Mock 처리하고
- 성공/실패에 따라 UseCase가 정확한 AsyncValue 타입을 반환하는지 검증

```dart
test('execute returns AsyncData on success', () async {
  when(mockRepository.login(any, any)).thenAnswer(
    (_) async => const Result.success(mockUser),
  );

  final result = await useCase.execute('email@example.com', 'password123');

  expect(result, isA<AsyncData<User>>());
});

test('execute returns AsyncError on failure', () async {
  when(mockRepository.login(any, any)).thenAnswer(
    (_) async => const Result.error(mockFailure),
  );

  final result = await useCase.execute('email@example.com', 'password123');

  expect(result, isA<AsyncError<Failure>>());
});
```

✅ 성공/실패 상황 모두 명확히 테스트 가능

---

## 🔁 관련 문서 링크

- [repository.md](repository.md): Result 반환 및 예외 처리 구조
- [notifier.md](../ui/notifier.md): 상태를 관리하는 주체인 Notifier 설계 가이드
- [state.md](../ui/state.md): State 객체 작성 및 관리 흐름

---

# ✅ 문서 요약

- UseCase는 Result<T>를 받아 AsyncValue<T>로 변환하는 책임만 가진다.
- Result.success는 AsyncData로, Result.error(Failure)는 AsyncError로 변환한다.
- 상태를 직접 변경하지 않고, Notifier가 관리한다.
- 실패 처리는 항상 Failure 객체 기준으로 일관성 있게 다룬다.
- 최신 Dart switch 패턴 매칭을 사용하여 깔끔하게 변환 분기한다.