# 🚨 예외 처리 및 Failure 설계 가이드

---

## ✅ 목적

데이터 계층에서 발생하는 다양한 예외를 일관된 방식으로 다루기 위해,  
`Failure` 클래스 기반의 예외 포장 전략을 사용한다.  
이 방식은 앱 전체에 통일된 에러 핸들링 구조를 제공하며,  
테스트 가능성, 디버깅 효율, 사용자 경험 모두를 향상시킨다.

---

## ✅ 설계 원칙

- **DataSource**는 외부 호출 중 발생한 예외를 그대로 throw 한다.
- **Repository**는 모든 예외를 `Failure`로 변환한 뒤, `Result.error(Failure)`로 감싼다.
- **UseCase/AsyncNotifier**는 `Result`를 받아 상태를 `AsyncValue<T>`로 구성한다.
- 모든 예외는 **하나의 Failure 객체로 통합**되며, 타입, 메시지, 원인(cause)을 포함한다.

---

## ✅ 예외 → Failure 흐름 구조

```
DataSource        → throw Exception
Repository        → try-catch → Result.error(Failure)
UseCase/ViewModel → Result → AsyncValue
UI                → AsyncValue.when() → 에러 메시지 표시
```

---

## ✅ Failure 클래스 정의

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

  bool get isNetwork => type == FailureType.network;
  bool get isTimeout => type == FailureType.timeout;

  @override
  String toString() =>
      'Failure(type: $type, message: $message, cause: $cause)';
}
```

---

## ✅ 예외 매핑 유틸 (`mapExceptionToFailure()`)

```dart
Failure mapExceptionToFailure(Object error) {
  if (error is TimeoutException) {
    return Failure(FailureType.timeout, '요청 시간이 초과되었습니다', cause: error);
  } else if (error is FormatException) {
    return Failure(FailureType.parsing, '데이터 형식 오류입니다', cause: error);
  } else if (error.toString().contains('SocketException')) {
    return Failure(FailureType.network, '인터넷 연결을 확인해주세요', cause: error);
  } else {
    return Failure(FailureType.unknown, '알 수 없는 오류가 발생했습니다', cause: error);
  }
}
```

---

## ✅ Repository 내 사용 예시

```dart
Future<Result<User>> login(String email, String pw) async {
  try {
    final dto = await remote.login(email, pw);
    return Result.success(dto.toModel());
  } catch (e) {
    final failure = mapExceptionToFailure(e);
    return Result.error(failure);
  }
}
```

---

## ✅ 디버깅을 위한 assert 및 로그 전략

```dart
try {
  ...
} catch (e, st) {
  debugPrintStack(label: 'Repository Error', stackTrace: st);
  assert(false, '처리되지 않은 예외: $e');
  return Result.error(mapExceptionToFailure(e));
}
```

> 개발 중 assert로 오류를 강제 종료할 수 있고, `debugPrintStack`으로 로그 추적이 가능하다.

---

## ✅ UI 처리 예시 (AsyncValue 기반)

```dart
ref.watch(loginProvider).when(
  loading: () => const CircularProgressIndicator(),
  data: (user) => Text('환영합니다 ${user.email}'),
  error: (e, _) => Text('에러: ${(e as Failure).message}'),
);
```

---

## 🔁 참고 링크

- [result.md](result.md)
- [usecase.md](../logic/usecase.md)
- [viewmodel.md](../ui/viewmodel.md)
- [state.md](../ui/state.md)
- [folder.md](folder.md)