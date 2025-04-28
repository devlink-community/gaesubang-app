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

✅ `build()`에서는 의존성 주입과 초기 상태 설정까지만 수행합니다.  
✅ 비즈니스 로직 실행은 onAction을 통해 별도로 트리거합니다.  
✅ 데이터 호출은 반드시 UseCase를 통해 수행합니다.

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
- 네트워크 요청은 별도 메서드로 분리하여 처리한다

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

- 페이지 진입 시 서버 데이터가 필수로 필요한 경우 사용
- build() 자체를 비동기로 구성하여 통신한다

```dart
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  late final GetProfileUseCase _getProfileUseCase;

  @override
  Future<ProfileState> build() async {
    _getProfileUseCase = ref.watch(getProfileUseCaseProvider);
    final profileAsyncValue = await _getProfileUseCase.execute();
    return ProfileState(profileResult: profileAsyncValue);
  }
}
```

> ✅ AsyncNotifier를 사용하는 경우에만 build()에서 비동기 통신을 수행합니다.

---

## 🧠 build() 동기/비동기 선택 기준

| 상황 | 권장 방식 |
|:---|:---|
| 기본 상태만 세팅, API 호출 없음 | 동기형 build() (Notifier) |
| 진입 즉시 서버 데이터가 필요한 경우 | 비동기형 build() (AsyncNotifier) |

> 상황에 따라 적절히 동기/비동기 구조를 선택합니다.

---

# 👁️ 상태 구독 및 사용

## ✅ Root 예시 (LoginScreenRoot)

```dart
class LoginScreenRoot extends ConsumerWidget {
  const LoginScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginNotifierProvider);
    final notifier = ref.watch(loginNotifierProvider.notifier);

    return LoginScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}
```

## ✅ Screen 예시 (LoginScreen)

```dart
class LoginScreen extends StatelessWidget {
  final LoginState state;
  final void Function(LoginAction action) onAction;

  const LoginScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Text('이메일: ${state.loginUserResult.value?.email ?? ''}');
  }
}
```

✅ Root가 상태 주입을 담당하고, Screen은 StatelessWidget으로 순수 UI만 담당합니다.

---

# ✅ AsyncValue 패턴 매칭 처리 예시

## ✅ Root 예시 (ProfileScreenRoot)

```dart
class ProfileScreenRoot extends ConsumerWidget {
  const ProfileScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);
    final notifier = ref.watch(profileNotifierProvider.notifier);

    return ProfileScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}
```

## ✅ Screen 예시 (ProfileScreen)

```dart
class ProfileScreen extends StatelessWidget {
  final ProfileState state;
  final void Function(ProfileAction action) onAction;

  const ProfileScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.profileResult) {
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

✅ AsyncValue는 switch-case로 분기하여 상태를 표현합니다.

---

# 🛠️ 사용자 액션 처리 (onAction 패턴)

- 모든 사용자 액션은 반드시 onAction() 메서드로 수집하여 관리합니다.
- 복잡한 액션은 필요에 따라 별도 메서드로 분리할 수 있습니다.

✅ Screen은 액션 발생 시 onAction(LoginAction)을 호출합니다.  
✅ Notifier는 onAction()에서 switch-case로 액션을 분기하여 처리합니다.

---

# 🧪 테스트 전략

- Notifier 초기 상태 테스트
- onAction 호출 후 상태 변이 테스트
- AsyncValue 기반 상태 변화 검증

---

# 🧩 책임 구분

| 계층 | 역할 |
|:---|:---|
| State | UI에 필요한 최소한의 데이터 구조 (immutable, freezed 사용) |
| Notifier | 상태를 보관하고, 액션을 통해 상태를 변경 |
| UseCase | 비즈니스 로직 실행 (Repository 접근 포함) |
| Screen | Notifier의 상태를 구독하고 UI를 렌더링 |
| Root | 상태를 주입하고, context 기반 처리를 담당 |

---

# 🔁 관련 문서 링크

- [state.md](state.md): 상태 객체 작성 가이드
- [usecase.md](../logic/usecase.md): 비즈니스 로직 실행 흐름
- [repository.md](../logic/repository.md): 외부 데이터 통신 구조

---

# ✅ 문서 요약

- build()는 초기 상태 세팅 전용이다.
- 동기형/비동기형 Notifier를 상황에 맞게 선택한다.
- 모든 사용자 액션은 onAction()으로 통일 관리한다.
- 데이터 호출은 반드시 UseCase를 통해 진행한다.
- 상태 분기는 switch-case 패턴을 사용한다.
- 테스트는 상태 변화 중심으로 수행한다.