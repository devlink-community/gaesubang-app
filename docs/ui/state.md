# 🧱 상태 클래스 (State) 설계 가이드

---

## ✅ 목적

State 클래스는 화면에 필요한 모든 상태 값을 하나의 객체로 표현합니다.  
UI는 이 상태 객체를 구독하여 렌더링하며,  
ViewModel(Notifier)은 상태를 생성하고 변경합니다.
---

## 🧱 설계 원칙

- 상태는 화면에 필요한 데이터만 포함한 **최소 단위의 객체**로 설계한다.
- `@freezed`를 사용하여 불변 객체로 정의하고,  
  **const constructor** 방식으로 작성한다. (`const StateName({...})`)
- 상태는 직접 관리하지 않고,  
  **각 필드(특히 통신 결과)는 `AsyncValue<T>` 타입으로 세분화해서 관리**한다.
- 상태 객체 자체는 단순한 데이터 집합이며, 비즈니스 로직은 포함하지 않는다.

---

## ✅ 파일 구조 및 위치

```text
lib/
└── auth/
    └── presentation/
        └── login_state.dart
```

---

## ✅ 작성 규칙 및 구성

| 항목 | 규칙 |
|:---|:---|
| 어노테이션 | `@freezed` 사용 |
| 생성자 | `const StateName({})` 직접 constructor 사용 (const factory ❌) |
| 상태 값 | 모든 필드는 nullable 또는 기본값 제공 |
| 통신 결과 | `AsyncValue<T>` 타입 필드로 관리 |

---

## ✅ 예시

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/model/user.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const LoginState({
    this.loginUserResult = const AsyncLoading(),
  });

  final AsyncValue<User> loginUserResult;
}
```

✅ 주요 포인트
- `const LoginState({...})` 직접 constructor 사용
- `AsyncValue<User>` 필드로 통신 결과 관리
- 초기 상태는 필드 디폴트 값으로 설정

---

## 📌 상태 관리 흐름

- 상태 변경은 항상 **copyWith**를 사용하여 새로운 상태를 생성한 뒤  
  `state = newState`로 교체한다.
- 별도의 수동 알림(`notifyListeners`)은 필요 없다.  
  (`state` 값이 변경되면 Riverpod이 자동으로 감지하고 UI를 다시 빌드함)

---

## 🧠 예시 흐름

```dart
// 상태 변경 (예시)
state = state.copyWith(
  loginUserResult: const AsyncLoading(),
);

// 또는
state = state.copyWith(
  loginUserResult: AsyncData(user),
);

// 또는
state = state.copyWith(
  loginUserResult: AsyncError(error, stackTrace),
);
```

- 항상 **copyWith로 안전하게 새로운 상태 생성**
- 그리고 **state에 할당만 하면 자동으로 반영**된다.

---

## 📋 책임 구분

| 구성 요소 | 역할 |
|:---|:---|
| State | UI에 필요한 최소한의 데이터 보관 |
| Notifier | 상태를 생성하고 변경하는 책임 |
| Screen | 상태를 구독하고 UI를 렌더링하는 책임 |

---

## 🧪 테스트 전략

- 상태 객체 자체는 불변이므로 테스트는 단순 비교로 충분하다.
- `copyWith`로 수정했을 때 기대하는 값으로 바뀌는지 검증한다.

```dart
final initial = LoginState();
final loading = initial.copyWith(loginUserResult: const AsyncLoading());
final data = initial.copyWith(loginUserResult: AsyncData(mockUser));

expect(loading.loginUserResult, isA<AsyncLoading>());
expect(data.loginUserResult.value, mockUser);
```

---

## 🔁 관련 문서 링크

- [notifier.md](notifier.md): 상태를 관리하는 주체인 Notifier 설계 가이드
- [screen.md](screen.md): UI 상태 구독 및 렌더링 방법
- [usecase.md](../logic/usecase.md): 유즈케이스 흐름 및 상태 연결

---