# 🧩 Root 설계 가이드

---

## ✅ 목적

Root는 ViewModel 상태를 구독하고, 사용자 액션을 처리하여 UI에 전달하는 중간 계층입니다.
UI 렌더링을 담당하는 Screen과 분리하여, context 처리, 상태 주입, 생명주기 제어 등의 책임을 담당합니다.
이를 통해 테스트 가능성과 유지보수성을 높이고, 화면 구성의 복잡도를 낮출 수 있습니다.

---

## ✅ 설계 원칙

- ViewModel의 상태를 구독하고, 상태에 따라 UI를 동적으로 구성한다.
- context가 필요한 처리 (라우팅, 다이얼로그, SnackBar 등)는 Root에서만 수행한다.
- ViewModel은 Root에서 생성자 또는 DI를 통해 주입하며, 직접 생성하지 않는다.
- 상태 변화 감지를 위해 `ListenableBuilder`, `ref.watch()`, `StateNotifierListener` 등의 방식 사용 가능
- Screen은 순수 위젯으로 유지하고, 상태/로직은 Root에서 연결한다.

---

## ✅ 파일 구조 및 위치

- 위치: `lib/{기능}/presentation/`
- 파일명: `{기능명}_screen_root.dart`
- 클래스명: `{기능명}ScreenRoot`

- 폴더 구조는 [../arch/folder.md]([../arch/folder.md])
- 네이밍 규칙은 [../arch/naming.md]([../arch/naming.md])

---

## ✅ 클래스 구성 및 패턴

### 기본 구성

```dart
class ProfileScreenRoot extends ConsumerWidget {
const ProfileScreenRoot({super.key});

@override
Widget build(BuildContext context, WidgetRef ref) {
final state = ref.watch(profileProvider);
final viewModel = ref.watch(profileProvider.notifier);

return ProfileScreen(
state: state,
onAction: viewModel.onAction,
);
}
}
```

- ViewModel의 상태를 구독하고, Screen에 전달
- ViewModel의 onAction을 Screen에 주입
- 상태 렌더링은 `.when()` 또는 분기 함수로 처리

---

## ✅ 책임 분리: Root vs Screen

| 항목             | Screen                      | Root                                   |
|------------------|-----------------------------|----------------------------------------|
| 상태 구독         | ❌                          | ✅ (ref.watch, ListenableBuilder 등)    |
| context 사용      | ❌ (금지)                   | ✅ (라우팅, 다이얼로그, Toast 등)       |
| ViewModel 접근    | ❌                          | ✅ (DI 또는 ref를 통한 주입)             |
| 생명주기 처리     | ❌                          | ✅ (StatefulWidget에서 initState 등)     |
| 테스트 용이성     | ✅ (순수 위젯)              | 🔁 (상태 기반 분리 시 유연함)           |

---

## ✅ 상태 구독 및 렌더링 방식

- ViewModel 상태가 `AsyncValue<T>`일 경우 `.when()`, `.map()`으로 분기
- 복잡한 렌더링 분기는 `_buildByState()` 또는 별도 위젯으로 분리

예시:

```dart
ref.watch(profileProvider).when(
loading: () => const LoadingView(),
error: (e, _) => ErrorView(e),
data: (state) => ProfileScreen(
state: state,
onAction: ref.read(profileProvider.notifier).onAction,
),
);
```

---

## ✅ 테스트 가이드

- Root는 상태 전달 및 context 처리만 담당하므로 단위 테스트는 ViewModel에 집중
- UI 렌더링 테스트는 Screen 단위로 수행
- Root 테스트는 필요 시 `pumpWidget`, mock ViewModel을 통해 렌더링 테스트 가능

---

## 🔁 참고 링크

- [screen.md](screen.md)
- [viewmodel.md](viewmodel.md)
- [view_vs_root.md](view_vs_root.md)
- [../arch/folder.md](../arch/folder.md)
- [../arch/naming.md](../arch/naming.md)