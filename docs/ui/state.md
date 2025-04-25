# 🧱 상태 클래스 (State) 설계 가이드

---

## ✅ 목적

State 클래스는 화면에 필요한 모든 상태 값을 하나의 불변 객체로 표현합니다.  
ViewModel은 이 상태 객체를 생성하고 갱신하며, UI는 이를 구독하여 렌더링합니다.

- 상태는 `AsyncNotifier<State>`를 통해 `AsyncValue<State>`로 UI에 전달됨
- 모든 상태는 `freezed`로 정의된 immutable 구조
- 상태는 기능별로 분리 (`LoginState`, `ProfileState` 등)

---

## 🧱 설계 원칙

- 상태는 화면에서 필요한 데이터만 포함한 **최소 단위 정보 객체**
- `@freezed`로 선언하며, `copyWith`를 통해 안전하게 갱신 가능
- 뷰와 연결될 때는 항상 `AsyncValue<State>` 형태로 다룸
- 상태 클래스는 비즈니스 로직을 포함하지 않으며, 단순 데이터 보관 역할만 수행

---

## ✅ 파일 구조 및 위치

```
lib/
└── auth/
    └── presentation/
        └── login_state.dart
```

> 📎 전체 폴더 구조는 [../arch/folder.md](../arch/folder.md) 참고

---

## ✅ 네이밍 및 클래스 구성

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/model/user.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    @Default(false) bool isLoading,
    User? user,
    String? errorMessage,
  }) = _LoginState;
}
```

- `@Default()`를 활용해 초기 상태를 명확하게 설정
- 모든 필드는 nullable 또는 기본값 제공 필드로 구성
- 내부에서만 상태 추적용 boolean (`isLoading`, `hasError` 등) 포함 가능
  물론, 아래 한 줄만 복사해서 넣으면 돼:

> 📎 네이밍 규칙은 [../arch/naming.md](../arch/naming.md) 참고

---

## 📌 책임 구분

| 구성 요소 | 역할 |
|-----------|------|
| State | UI 렌더링을 위한 데이터 캡슐 |
| ViewModel | 상태 생성 및 갱신 책임 |
| Screen | 상태를 기반으로 UI 구성 |
| Root | ViewModel로부터 상태를 주입받고 UI에 전달 |

---

## ✅ 테스트 팁

- 상태 객체는 순수 데이터이므로 단위 테스트가 간단
- 상태 갱신 흐름이 예상대로 이루어지는지 ViewModel 테스트 시 함께 검증
- `copyWith`를 활용해 부분 상태만 수정했을 때 UI 반영 여부 확인

```dart
final initial = LoginState();
final updated = initial.copyWith(user: mockUser);

expect(updated.user, isNotNull);
expect(updated.isLoading, isFalse); // 그대로 유지됨
```

---

## 🔁 관련 문서 링크

- [viewmodel.md](viewmodel.md): 상태 관리 및 흐름 처리 방식
- [screen.md](screen.md): 상태 기반 UI 구현 방식
- [../logic/model.md](../logic/model.md): 상태에 포함되는 도메인 모델 정의