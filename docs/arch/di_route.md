# 🧩 DI & Route 설계 가이드 (Riverpod 어노테이션 기반)

---

## ✅ 목적

본 문서는 프로젝트 내 의존성 주입(DI)과 라우팅(Route) 설정 방식을 정의한다.  
본 프로젝트는 **`@riverpod` 어노테이션 기반의 Riverpod 구조**를 사용하며,  
기존 `get_it` 방식이 아닌 **Provider 자체를 중심으로 DI와 상태 전달을 처리**한다.

---

## ✅ 설계 원칙

- DI는 DataSource, Repository, UseCase, ViewModel 전 계층에서 정의된다.
- 모든 의존 객체는 `@riverpod` 또는 `@Riverpod(keepAlive: true)`를 사용해 Provider로 등록한다.
- Provider는 `ref.watch(...)` 또는 `ref.read(...)`를 통해 자동으로 주입된다.
- ViewModel, UseCase는 각각 `@riverpod` 어노테이션을 사용하여 Provider로 등록한다.
- Provider 이름은 명확하게 기능명을 포함하며 `loginViewModel`, `getProfileUseCase` 형태로 선언한다.
- 기능별 라우팅은 `module/feature_route.dart` 내에서 정의한다.
- Root(ScreenRoot)는 `viewModel: ref.watch(...)` 형태의 주입이 아닌 내부에서 Provider를 바로 watch한다.
- 라우팅은 `GoRouter`를 사용하며, MainTab은 `StatefulShellRoute`를 활용한다.

---

## ✅ Provider 정의 (예시)

```dart
@riverpod
class LoginViewModel extends _$LoginViewModel {
  @override
  FutureOr<AsyncValue<User>> build() => const AsyncLoading();

  Future<void> login(String email, String pw) async {
    state = const AsyncLoading();
    final result = await ref.read(loginUseCaseProvider).execute(email, pw);
    state = result;
  }
}
```
```dart
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    AuthRepositoryImpl(dataSource: ref.watch(authDataSourceProvider));

```
```dart
@riverpod
LoginUseCase loginUseCase(LoginUseCaseRef ref) {
  return LoginUseCase(repository: ref.watch(authRepositoryProvider));
}

```

- `@riverpod` 어노테이션을 통해 Provider를 자동 생성하며,
- Provider 이름은 함수명 그대로 사용됨 (`loginUseCaseProvider`, `loginViewModelProvider`)

---

## ✅ DI 구성 원칙

- 모든 기능 모듈은 `module/{기능}_di.dart`에 의존성 등록용 Provider 함수를 정의한다.
- 예: `auth_di.dart`, `recipe_di.dart` 등
- Main 구성에서는 `export` 또는 `ref.watch(...)`를 통해 연결


## ✅ Route 구성 원칙

- 모든 기능 모듈은 `module/{기능}_route.dart`에 GoRoute 목록으로 정의한다.
- Route 내부에서는 Root(ScreenRoot)를 통해 ViewModel 주입을 수행한다.

```dart
final authRoutes = [
  GoRoute(
    path: '/login',
    builder: (context, state) => const LoginScreenRoot(),
  ),
];
```

- 모든 Route는 해당 기능의 `screen_root.dart`를 진입점으로 한다.
- Root 내부에서 ViewModel을 `ref.watch()`로 주입하여 상태와 액션을 연결한다.
- Screen은 순수 UI만 담당하며 context나 ref를 직접 사용하지 않는다.

---

## ✅ 기능별 모듈 구성

- 각 기능은 `module/{기능}_route.dart` 파일 내에 GoRoute 목록으로 정리한다.
- `main.dart` 또는 앱 라우트 설정부에서는 이 모듈만 import하여 통합 구성한다.

```dart
final routes = [
  ...authRoutes,
  ...recipeRoutes,
];
```

---

## ✅ ScreenRoot 내 DI 방식
- 
- Provider 이름은 ViewModel 클래스 이름 기반으로 자동 생성됨 (`loginViewModel` → `loginViewModelProvider`)
- `.notifier`를 통해 액션을 실행할 수 있는 ViewModel 인스턴스에 접근
- `.watch()`는 상태 구독, `.read()`는 1회성 액션에 적합

```dart
class LoginScreenRoot extends ConsumerWidget {
  const LoginScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final viewModel = ref.read(loginViewModelProvider.notifier);

    return LoginScreen(
      state: state,
      onAction: viewModel.onAction,
    );
  }
}
```

- ViewModel은 `ref.read(Provider.notifier)`로 접근
- 상태는 `ref.watch(Provider)`로 실시간 구독
- Root만 ref를 사용하고, Screen은 StatelessWidget으로 분리

---

## 🔁 참고 링크

- [folder.md](folder.md)
- [viewmodel.md](../ui/viewmodel.md)
- [usecase.md](../logic/usecase.md)
- [screen.md](../ui/screen.md)
- [root.md](../ui/root.md)