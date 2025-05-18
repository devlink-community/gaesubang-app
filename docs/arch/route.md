# 🛣️ 라우팅 (Route) 설계 가이드

---

## ✅ 목적

- **GoRouter 객체**를 **Riverpod Provider**를 통해 관리하여 앱의 전체 라우팅 경로를 설정
- 경로(path)와 Root 화면을 연결하는 역할만 담당
- 라우팅은 네비게이션만 처리하고, 비즈니스 로직은 포함하지 않음

---

## 🧱 설계 원칙

- GoRouter는 `@riverpod` 어노테이션을 사용해 Provider로 등록
- 기능별로 `module_route.dart` 파일을 분리하여 관리
- Root는 Notifier 주입, 상태 구독, 액션 연결을 담당
- Screen은 StatelessWidget이며, 외부 Provider나 context 직접 접근 없이 상태와 액션만 사용
- Route는 경로-Root 매핑만 담당하며, 상태/인증 체크 등 비즈니스 로직을 처리하지 않음

---

## ✅ 파일 구조 및 위치

```
lib/
├── core/
│   └── router/
│       └── app_router.dart              # 메인 라우터
└── {기능}/
    └── module/
        └── {기능}_route.dart            # 기능별 라우트 정의
```

---

## ✅ 기능별 Route 정의 예시

### module_route.dart 예시

```dart
final authRoutes = [
  GoRoute(
    path: '/login',
    builder: (context, state) => const LoginScreenRoot(),
  ),
  GoRoute(
    path: '/signup',
    builder: (context, state) => const SignupScreenRoot(),
  ),
];
```

### 메인 라우터 Provider 정의

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ...authRoutes,
      ...groupRoutes,
      ...communityRoutes,
    ],
    errorBuilder: (context, state) => const ErrorScreenRoot(),
  );
}
```

---

## 🏗️ 라우트 구조 예시

### 1. 기본 라우트

```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreenRoot(),
)
```

### 2. Dynamic Parameter Route

```dart
GoRoute(
  path: '/group/:id',
  builder: (context, state) {
    final groupId = state.pathParameters['id']!;
    return GroupTimerScreenRoot(groupId: groupId);
  },
)
```

### 3. Named Route

```dart
GoRoute(
  name: 'profile',
  path: '/profile',
  builder: (context, state) => const ProfileScreenRoot(),
)

// 사용 시
context.goNamed('profile');
```

### 4. Nested Routing

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreenRoot(),
  routes: [
    GoRoute(
      path: 'account',
      builder: (context, state) => const AccountSettingsScreenRoot(),
    ),
    GoRoute(
      path: 'notifications',
      builder: (context, state) => const NotificationSettingsScreenRoot(),
    ),
  ],
)
```

---

## 🔄 고급 라우팅 구조

### 1. ShellRoute 사용 (탭 구조)

```dart
ShellRoute(
  builder: (context, state, child) => MainTabScreenRoot(child: child),
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreenRoot(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreenRoot(),
    ),
  ],
)
```

### 2. StatefulShellRoute 사용 (탭 상태 유지)

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => 
      MainTabScreenRoot(shell: navigationShell),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreenRoot(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreenRoot(),
        ),
      ],
    ),
  ],
)
```

---

## 📋 라우팅 흐름

| 단계 | 역할 |
|:---|:---|
| AppRouter | 전체 경로 구성 및 초기 위치 설정 |
| Route | 경로 → Root 연결 |
| Root | Notifier 주입 + 상태 구독 + 액션 연결 |
| Screen | 주입받은 상태와 액션을 기반으로 UI 렌더링 |

---

## 🔄 네비게이션 메서드

### 기본 네비게이션

```dart
// 새 화면으로 이동 (스택에 추가)
context.push('/profile');

// 현재 화면 교체
context.pushReplacement('/home');

// 전체 스택 교체
context.go('/login');

// 뒤로 가기
context.pop();
```

### Named Route 네비게이션

```dart
// Named route로 이동
context.goNamed('profile');

// Named route로 이동 + 파라미터
context.goNamed('groupDetail', pathParameters: {'id': groupId});
```

---

## 🔒 인증 및 라우트 가드

### Redirect를 이용한 인증 처리

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).isLoggedIn;
      final isLoginPage = state.uri.path == '/login';
      
      // 로그인하지 않았고 로그인 페이지가 아닌 경우 → 로그인 페이지로
      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }
      
      // 이미 로그인했고 로그인 페이지인 경우 → 홈으로
      if (isLoggedIn && isLoginPage) {
        return '/home';
      }
      
      return null; // 리다이렉트 없음
    },
    routes: routes,
  );
}
```

---

## 📌 딥링크 구조 대비

- 현재 딥링크 기능은 직접 구현하지 않음
- Dynamic Parameter Route 기반 구조로 설계하여 추후 딥링크 추가 시 대응 가능
- initialLocation은 커스터마이즈 가능

---

## ✅ 최종 요약

| 항목 | 요약 |
|:---|:---|
| Router Provider | 전체 라우트 구성 및 관리 |
| Route | Path → Root 연결만 담당 |
| Root | Notifier 주입 + 상태 구독 + 액션 연결 |
| Screen | 상태와 액션만 받아서 순수 UI 렌더링 |
| Navigation | push, go, pop 등 상황에 맞는 메서드 사용 |
| 확장성 | ShellRoute, StatefulShellRoute 등 고급 구조 지원 |

---

## 🔁 관련 문서 링크

- [di.md](di.md): 의존성 주입 설계 가이드
- [../ui/root.md](../ui/root.md): Root 설계 가이드
- [../ui/screen.md](../ui/screen.md): Screen 설계 가이드
- [../ui/notifier.md](../ui/notifier.md): Notifier 설계 가이드

---