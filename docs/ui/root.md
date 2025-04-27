# 🧩 Root 설계 가이드 (최신 Riverpod 기반)

---

## ✅ 목적

Root는 Notifier 상태를 구독하고, 사용자 액션을 분기하여 처리하는 **중간 계층**이다.  
Screen(순수 UI)과 로직(context 사용, 화면 이동, 다이얼로그 처리 등)을 명확히 분리하여  
구조적 일관성, 테스트성, 유지보수성을 높인다.

---

## ✅ 설계 원칙

- Root는 반드시 **ConsumerWidget**으로 작성한다.
- **ref.watch()** 를 통해 Notifier의 **상태(state)** 와 **액션(notifier)** 를 **분리 구독**한다.
- 상태(state)는 Screen에 주입하고, onAction도 Root에서 주입한다.
- 화면 이동(context.push 등)이나 다이얼로그 표시(context 사용)는 반드시 Root에서만 수행한다.
- Screen은 context를 직접 사용하지 않고, 순수 UI만을 담당한다.
- 초기 데이터 로딩은 별도 initState 없이, **build() 흐름에서 자동 트리거**되도록 구성한다.

---

## ✅ 파일 구조 및 위치

- 경로: `lib/{기능}/presentation/`
- 파일명: `{기능명}_screen_root.dart`
- 클래스명: `{기능명}ScreenRoot`

예시:  
`HomeScreenRoot`, `ProfileScreenRoot`, `LoginScreenRoot`

---

## ✅ 기본 작성 예시

```dart
class HomeScreenRoot extends ConsumerWidget {
  const HomeScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeNotifierProvider);
    final notifier = ref.watch(homeNotifierProvider.notifier);

    return HomeScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case HomeAction.tapRecipe(final recipeId):
            await context.push(Routes.recipeDetailPath(recipeId));
          case HomeAction.searchTouch():
            await context.push(Routes.homeSearch);
          default:
            await notifier.onAction(action);
        }
      },
    );
  }
}
```

---

## ✅ 상태와 액션 연결

| 역할 | 설명 |
|:---|:---|
| state | `ref.watch(notifierProvider)` 로 상태만 구독하여 Screen에 주입한다. |
| notifier | `ref.watch(notifierProvider.notifier)` 로 액션 메서드를 가져온다. |
| onAction | 사용자 액션을 받아 분기 처리한다. Root에서는 화면 이동 등 context 기반 로직만 직접 수행하고, 나머지는 notifier로 위임한다. |

---

## ✅ 액션 처리 기준

- **화면 이동** (`context.push`, `context.pop`)  
  → Root에서 직접 처리한다.

- **비즈니스 로직, 상태 변경**  
  → Notifier의 `onAction()` 메서드로 위임한다.

- **UI 전용 이벤트** (SnackBar 표시, Dialog 오픈 등)  
  → Root에서 context를 사용하여 처리한다.

---

## ✅ 상태 초기화 전략

- 별도의 `initState()`를 사용하지 않는다.
- Notifier의 `build()` 메서드에서 초기 로딩 메서드를 호출하거나, 필요한 경우 비동기 `build()`를 사용한다.

```dart
@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  HomeState build() {
    _loadInitialData();
    return const HomeState();
  }

  Future<void> _loadInitialData() async {
    // 초기 데이터 불러오기
  }
}
```

※ build()는 항상 가볍게 유지하고, 실제 네트워크 통신은 별도 메서드에서 분리 실행한다.

---

## ✅ 책임 분리 요약

| 계층 | 책임 |
|:---|:---|
| Root | 상태 주입, 액션 연결, context 기반 작업(화면 이동, 다이얼로그 등) |
| Screen | 순수 UI 구성, 상태 기반 렌더링, onAction 호출 |
| Notifier | 비즈니스 로직 수행, 상태 변경 처리 |

---

## ✅ 주의사항

- Root가 없으면 Screen은 절대 context를 직접 사용할 수 없다.
- 모든 이벤트 흐름은 **onAction → Root → (필요시) Notifier** 방식으로 통일한다.
- ref.watch()는 **state**와 **notifier**를 명확히 구분해서 각각 watch한다.
- 초기에 반드시 **ConsumerWidget** 구조로 시작하고, StatefulWidget 기반 Root는 더 이상 사용하지 않는다.

---

# 📌 요약

- Root는 ConsumerWidget이다.
- 상태(state)와 액션(notifier)를 분리해서 watch한다.
- context 사용은 오직 Root만 담당한다.
- Screen은 순수 UI만 담당한다.
- 초기 로딩은 build() 흐름에서 처리한다.

---