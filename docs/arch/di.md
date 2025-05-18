# 🧩 의존성 주입 (DI) 설계 가이드

---

## ✅ 목적

- **Riverpod Provider**를 통해 앱의 의존성 주입을 체계적으로 관리
- 기능별로 모듈화된 DI 구성으로 확장성과 유지보수성 확보
- Provider 생명주기 관리를 통한 효율적인 메모리 사용

---

## 🧱 설계 원칙

- 기능별로 `module_di.dart` 파일을 분리하여 관리
- `@riverpod` 어노테이션을 사용한 코드 생성 기반 Provider 정의
- 계층별 의존성은 하향식으로만 주입 (UI → UseCase → Repository → DataSource)
- Provider 이름은 camelCase로 작성하고 접미사로 Provider 사용

---

## ✅ 파일 구조 및 위치

```
lib/
└── {기능}/
    └── module/
        └── {기능}_di.dart
```

예시: `lib/auth/module/auth_di.dart`, `lib/group/module/group_di.dart`

---

## ✅ Provider 정의 예시

### DataSource Provider

```dart
@riverpod
AuthDataSource authDataSource(AuthDataSourceRef ref) => AuthDataSourceImpl();

// Mock DataSource (상태 유지가 필요한 경우)
@Riverpod(keepAlive: true)
GroupDataSource groupDataSource(GroupDataSourceRef ref) => MockGroupDataSourceImpl();
```

### Repository Provider

```dart
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) =>
    AuthRepositoryImpl(dataSource: ref.watch(authDataSourceProvider));
```

### UseCase Provider

```dart
@riverpod
LoginUseCase loginUseCase(LoginUseCaseRef ref) =>
    LoginUseCase(repository: ref.watch(authRepositoryProvider));
```

### Notifier Provider

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
    // 액션 처리 로직
  }
}
```

---

## 🔄 Provider 생명주기 관리

### keepAlive 사용 기준

| Provider 타입 | keepAlive 설정 | 사용 사례 |
|--------------|----------------|-----------|
| **DataSource** | `true` | 상태 유지가 필요한 Mock DataSource |
| **DataSource** | `false` (기본) | 실제 API 호출, 상태 없는 Mock |
| **Repository** | `false` (기본) | 일반적으로 상태를 보관하지 않음 |
| **UseCase** | `false` (기본) | 순수 함수 형태로 동작 |
| **Notifier** | `false` (기본) | Riverpod이 자동으로 생명주기 관리 |

### keepAlive 설정의 영향

**keepAlive: true인 경우:**
- Provider 인스턴스가 앱 생명주기 동안 유지됨
- 메모리 사용량이 증가할 수 있음
- Mock 데이터의 상태 보존 가능

**keepAlive: false인 경우 (기본값):**
- 더 이상 참조되지 않으면 자동 dispose됨
- 메모리 효율적
- 상태가 초기화될 수 있음

---

## 🧪 테스트 전략

- Provider 별로 독립적인 테스트 가능
- Mock Provider를 이용한 단위 테스트
- ProviderContainer를 이용한 통합 테스트

```dart
test('LoginUseCase Provider 테스트', () {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
    ],
  );
  
  final loginUseCase = container.read(loginUseCaseProvider);
  expect(loginUseCase, isA<LoginUseCase>());
});
```

---

## 📋 의존성 주입 흐름

```
UI Layer (Root/Screen)
    ↓ ref.watch()
Notifier Provider
    ↓ ref.watch()
UseCase Provider  
    ↓ ref.watch()
Repository Provider
    ↓ ref.watch()
DataSource Provider
    ↓
External Services (API, Firebase, etc.)
```

---

## 🔁 관련 문서 링크

- [route.md](route.md): 라우팅 설계 가이드
- [../ui/notifier.md](../ui/notifier.md): Notifier 설계 가이드
- [../logic/usecase.md](../logic/usecase.md): UseCase 설계 가이드
- [../logic/repository.md](../logic/repository.md): Repository 설계 가이드
- [../logic/datasource.md](../logic/datasource.md): DataSource 설계 가이드

---