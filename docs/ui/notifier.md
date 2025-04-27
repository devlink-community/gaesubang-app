# 🧩 Notifier 설계 가이드 (@riverpod 기반)

---

## ✅ 목적

Notifier는 앱의 상태를 보존하고, 사용자 액션을 처리하는  
**상태 관리 계층**입니다.

이 프로젝트에서는 Riverpod의 `@riverpod` 어노테이션과  
`AsyncNotifier<T>`, `Notifier<T>` 구조를 활용하여  
모든 화면의 상태를 일관성 있게 관리합니다.

---

## 📚 ViewModel 레이어와의 관계

- 구조상 **ViewModel 레이어**는 유지됩니다.
- 다만, 전통적인 MVVM 구조에서 ViewModel이 담당하던 역할을  
  이 프로젝트에서는 **Notifier** 객체가 대신 수행합니다.
- 따라서 문서 및 코드에서도 ViewModel 대신 Notifier 용어를 사용합니다.

---

# ⚙️ 기본 구조 예시 (UseCase 주입)

```dart
@riverpod
class LoginNotifier extends _$LoginNotifier {
  late final LoginUseCase _loginUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    return const LoginState();
  }
}
```

✅ `build()`에서는 의존성 주입과 초기 상태 설정까지만 수행합니다.  
✅ **비즈니스 로직 실행은 절대 build()에서 직접 하지 않습니다.**  
(API 요청 등은 별도 메서드를 통해 실행)

---

# 🏗️ 파일 구조 및 명명 규칙

```text
lib/
└── auth/
    └── presentation/
        ├── login_notifier.dart
        └── login_state.dart
```

| 항목 | 규칙 |
|:---|:---|
| 파일 경로 | `lib/{기능}/presentation/` |
| 파일명 | `{기능}_notifier.dart` |
| 클래스명 | `{기능}Notifier` |

---

# 🔥 상태 초기화 (build 메서드)

## ✅ 동기형 build()

- 초기값만 설정할 경우 사용
- 네트워크 요청은 별도로 메서드 분리

```dart
@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  LoginState build() {
    return const LoginState();
  }
}
```

---

## ✅ 비동기형 Future build()

- 페이지 진입 시 서버 데이터가 필수인 경우 사용
- build() 자체를 비동기로 구성

```dart
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<ProfileState> build() async {
    final profile = await api.fetchProfile();
    return ProfileState(profileResult: AsyncData(profile));
  }
}
```

---

## 🧠 build() 동기/비동기 선택 기준

| 상황 | 권장 방식 |
|:---|:---|
| 기본 상태만 세팅, API 호출 없음 | 동기 build() |
| 서버 데이터가 필요 | 비동기 Future build() |

---

# 👁️ 상태 구독 및 사용

## ✅ 기본 구독 방법

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginNotifierProvider);

    return Text('이메일: ${state.loginUserResult.value?.email ?? ''}');
  }
}
```

✅ `ref.watch()`를 통해 Notifier의 상태를 구독하고,  
✅ 상태가 변경될 때마다 UI가 자동으로 리렌더링됩니다.

---

## ✅ AsyncValue 처리

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);

    switch (profileState.profileResult) {
      case AsyncData(:final value):
        return Text('Hello, ${value.name}');
      case AsyncLoading():
        return const CircularProgressIndicator();
      case AsyncError(:final error, :_):
        final failure = error as Failure;
        return Text('에러 발생: ${failure.message}');
    }
  }
}
```

---

# 🛠️ 사용자 액션 처리 (onAction 패턴)

## ✅ 액션 클래스 정의 (sealed class)

```dart
sealed class LoginAction {}

class SubmitLogin extends LoginAction {
  final String email;
  final String password;
  const SubmitLogin(this.email, this.password);
}

class ResetLoginForm extends LoginAction {
  const ResetLoginForm();
}
```

---

## ✅ Notifier 액션 처리

```dart
@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  LoginState build() => const LoginState();

  Future<void> onAction(LoginAction action) async {
    switch (action) {
      case SubmitLogin(:final email, :final password):
        await _handleLogin(email, password);
      case ResetLoginForm():
        _handleReset();
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    state = state.copyWith(loginUserResult: const AsyncLoading());
    final asyncResult = await _loginUseCase.execute(email, password);
    state = state.copyWith(loginUserResult: asyncResult);
  }

  void _handleReset() {
    state = const LoginState();
  }
}
```

✅ 액션을 명시적으로 분기하여 관리합니다.

✅ 비동기 액션은 async/await로 처리하고,  
✅ 동기 액션은 간단히 메서드 호출로 처리합니다.

---

# 🧪 테스트 전략

## ✅ 초기 상태 테스트

```dart
test('초기 상태는 AsyncLoading이다', () {
  final notifier = LoginNotifier();
  expect(notifier.state.loginUserResult, isA<AsyncLoading>());
});
```

---

## ✅ 액션 후 상태 변이 테스트

```dart
test('로그인 성공 후 상태는 AsyncData이다', () async {
  when(mockLoginUseCase.execute(any, any))
      .thenAnswer((_) async => AsyncData(mockUser));

  await notifier.onAction(SubmitLogin('test@example.com', 'password'));

  expect(notifier.state.loginUserResult, isA<AsyncData<User>>());
});
```

---

## ✅ 에러 발생 시 상태 테스트

```dart
test('로그인 실패 시 상태는 AsyncError이다', () async {
  when(mockLoginUseCase.execute(any, any))
      .thenAnswer((_) async => AsyncError(mockFailure));

  await notifier.onAction(SubmitLogin('wrong@example.com', 'wrongpass'));

  expect(notifier.state.loginUserResult, isA<AsyncError<Failure>>());
});
```

---

# 🧩 책임 구분

| 계층 | 역할 |
|:---|:---|
| State | UI에 필요한 최소한의 데이터 구조 (immutable, freezed 사용) |
| Notifier | 상태를 보관하고, 액션을 통해 상태를 변경 |
| Screen | Notifier의 상태를 구독하고 UI를 렌더링 |
| Root | 상태를 주입하고, context(의존성 관리, Provider 연결)를 담당 |

---

# 🔁 관련 문서 링크

- [state.md](state.md): 상태 객체 작성 가이드
- [usecase.md](../logic/usecase.md): 비즈니스 로직 실행 흐름
- [repository.md](../logic/repository.md): 외부 데이터 통신 구조

---

# ✅ 문서 요약

- build()는 초기 상태 세팅 전용
- 네트워크 요청은 onAction()을 통한 메서드 실행으로 분리
- 상태 구독은 ref.watch로 수행
- AsyncValue.when을 통한 상태 분기
- Failure는 AsyncError로 감싸고, 사용자 메시지를 명확히 표시
- 액션은 onAction 패턴으로 통일 관리
- 테스트 전략과 책임 분리가 명확

---