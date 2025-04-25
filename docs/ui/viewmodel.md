# 👁️ ViewModel 설계 가이드 (@riverpod 기반)

---

## ✅ 목적

ViewModel은 앱의 상태를 표현하고, UI에 전달하는 **상태 보존 계층**입니다.  
이 프로젝트에서는 Riverpod의 `@riverpod` 어노테이션과 `AsyncNotifier<T>`를 기반으로,  
기능별 상태를 `AsyncValue<T>`로 관리합니다.

---

## 🧱 설계 원칙

- ViewModel은 `@riverpod` 어노테이션을 사용 
- 클래스는 `extends _$ClassName`으로 정의
- 상태는 `AsyncValue<T>` 형식으로 표현
- DI는 `ref.watch()`로 주입하며, 주입 대상인 UseCase는 `@riverpod`로 등록되어 있어야 한다.
- 초기 상태는 `build()` 메서드에서 반환 (`FutureOr<T>` 사용 가능)

---

## ✅ 파일 구조 및 위치

```
lib/
└── user/
    └── presentation/
        ├── login_view_model.dart
        ├── login_state.dart
        └── login_action.dart
```

> 📎 전체 폴더 구조는 [../arch/folder.md](../arch/folder.md) 참고

---

## ✅ 네이밍 및 클래스 구성

### ViewModel 예시 (`login_view_model.dart`)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecase/login_use_case.dart';
import 'login_state.dart';

part 'login_view_model.g.dart';

@riverpod
class LoginViewModel extends _$LoginViewModel {
  late final LoginUseCase _loginUseCase;

    // DI: loginUseCaseProvider는 @riverpod 어노테이션으로 등록된 Provider여야 함
   // 상태는 기본 초기 상태로 구성됨
  @override
  FutureOr<LoginState> build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    return const LoginState();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    try {
      final user = await _loginUseCase.execute(email, password);
      state = AsyncData(LoginState(user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

> `loginViewModelProvider`는 자동 생성됨  
> `@riverpod` 사용 시 `.g.dart` 파일 생성 필요

---

## 📌 책임 구분

| 위치 | 역할 |
|------|------|
| ViewModel | 상태 흐름 관리, UI에 전달 |
| UseCase | 데이터 요청 및 예외 throw |
| UI | ViewModel 상태 구독 및 분기 처리 |

---

## ✅ 테스트 가이드

- 초기 상태, 로딩 상태, 데이터/에러 상태 전이 테스트
- `ref.read(loginViewModelProvider.notifier).login()` 호출 후 `state` 확인
- `AsyncLoading`, `AsyncData`, `AsyncError` 각각의 상태 분기를 검증

```dart
expect(viewModel.state, isA<AsyncLoading>());
await viewModel.login('email', 'pw');
expect(viewModel.state, isA<AsyncData>());
```

---

## 🔁 관련 문서 링크

- [usecase.md](../logic/usecase.md): 결과 전달 및 예외 처리 흐름
- [state.md](state.md): 상태 모델 정의 가이드
- [screen.md](screen.md): UI에서 상태 처리 방식
- [../arch/folder.md](../arch/folder.md): 전체 파일 구성 구조