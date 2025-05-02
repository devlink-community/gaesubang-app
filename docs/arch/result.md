# 🎯 Result 패턴 설계 가이드

---

## ✅ 목적

Repository 계층에서 발생하는 성공/실패 응답을 예외 없이 흐름으로 처리하기 위해  
Result 패턴을 사용한다. 이를 통해 도메인 계층에서 예외를 래핑하고,  
ViewModel은 흐름만 받아 상태를 구성한다. 테스트성과 추적성이 향상되고  
상태 기반 UI 연동이 자연스럽게 이어진다.

---

## ✅ 설계 원칙

- Repository는 항상 `Result<T>`를 반환한다.
- Result는 `Success<T>`와 `Error(Failure)` 두 가지 형태를 갖는 sealed class이다.
- 예외를 직접 throw하지 않고, `Failure`로 포장한 후 `Result.error()`로 감싼다.
- ViewModel은 Result를 직접 다루지 않고, UseCase에서 변환된 `AsyncValue<T>`만 처리한다.
- DataSource는 외부 호출 중 발생하는 Exception을 throw하고,  
  Repository는 이를 catch하여 Result로 변환한다.

---

## ✅ 흐름 구조 요약

```text
data_source      → throws Exception
repository       → try-catch → Result<T> (Failure 포함)
usecase          → Result<T> → AsyncValue<T>
viewmodel        → state = await usecase() (AsyncValue<T>)
ui               → ref.watch(...).when(...) 로 상태 분기 처리
```

---

## ✅ Result 클래스 정의

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.error(Failure failure) = Error<T>;
}
```

---

## ✅ Failure 정의

```dart
enum FailureType {
  network,
  unauthorized,
  timeout,
  server,
  parsing,
  unknown,
}

class Failure {
  final FailureType type;
  final String message;
  final Object? cause;

  const Failure(this.type, this.message, {this.cause});
}
```

---

## ✅ 예외 → Result 변환 예시 (Repository)

```dart
Future<Result<User>> login(String email, String pw) async {
  try {
    final response = await _remote.login(email, pw);
    return Result.success(response);
  } catch (e) {
    return Result.error(mapExceptionToFailure(e));
  }
}
```

---

## ✅ Exception → Failure 매핑 유틸

```dart
Failure mapExceptionToFailure(Object error, StackTrace stackTrace) {
  if (error is TimeoutException) {
    return Failure(
      FailureType.timeout,
      '요청 시간이 초과되었습니다',
      cause: error,
      stackTrace: stackTrace,
    );
  } else if (error is FormatException) {
    return Failure(
      FailureType.parsing,
      '데이터 형식 오류입니다',
      cause: error,
      stackTrace: stackTrace,
    );
  } else if (error.toString().contains('SocketException')) {
    return Failure(
      FailureType.network,
      '인터넷 연결을 확인해주세요',
      cause: error,
      stackTrace: stackTrace,
    );
  } else {
    return Failure(
      FailureType.unknown,
      '알 수 없는 오류가 발생했습니다',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
```

---

## ✅ ViewModel에서 상태 처리

```dart
Future<void> login(String email, String pw) async {
  state = const AsyncLoading();
  state = await _loginUseCase(email, pw);
}
```

> UseCase는 Result를 받아 적절히 AsyncValue로 변환 후 전달

---

## ✅ UI (리버팟 + AsyncValue)

```dart
final loginState = ref.watch(loginProvider);

switch (loginState) {
  case AsyncLoading():
    return CircularProgressIndicator();
  case AsyncData(:final user):
    return Text('환영합니다 ${user.email}');
  case AsyncError(:final error, :_):
    return Text('에러 발생: $error');
}
```

---

## ✅ 흐름 요약

| 단계       | 처리 방식                          |
|------------|-----------------------------------|
| DataSource | Exception throw                   |
| Repository | try-catch → `Result<T>`             |
| UseCase    | `Result` → `AsyncValue` 변환           |
| ViewModel  | state = AsyncValue                |
| UI         | switch 문을 이용해 AsyncValue 분기 렌더링 |

---

## 🔁 참고 링크

- [error.md](error.md)
- [usecase.md](../logic/usecase.md)
- [viewmodel.md](../ui/viewmodel.md)
- [state.md](../ui/state.md)
- [folder.md](folder.md)
