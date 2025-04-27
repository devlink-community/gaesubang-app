# 🖥️ Screen 설계 가이드 (최신 Riverpod 기반)

---

## ✅ 목적

Screen은 사용자에게 보여지는 **순수 UI 계층**이다.  
상태(state)와 액션(onAction)을 외부로부터 주입받아,  
오직 화면 렌더링만을 담당하며 **context를 직접 사용하지 않는다**.

---

## ✅ 설계 원칙

- 항상 **StatelessWidget**으로 작성한다.
- 화면에 필요한 모든 데이터(state)와 이벤트 핸들러(onAction)는 **외부에서 주입받는다**.
- **context를 직접 사용하지 않는다.**
  - 화면 이동(context.push 등)
  - 다이얼로그 호출(showDialog 등)
  - SnackBar 호출(ScaffoldMessenger 등)
- 화면은 작은 빌드 함수로 세분화하여 유지보수성과 가독성을 높인다.
- 모든 상태 분기는 **AsyncValue** 기반으로 처리한다.

---

## ✅ 파일 구조 및 위치

- 경로: `lib/{기능}/presentation/`
- 파일명: `{기능명}_screen.dart`
- 클래스명: `{기능명}Screen`

예시:  
`HomeScreen`, `ProfileScreen`, `LoginScreen`

---

## ✅ Screen 기본 구성 예시

```dart
class HomeScreen extends StatelessWidget {
  final HomeState state;
  final void Function(HomeAction action) onAction;

  const HomeScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final recipes = state.recipeList;

    switch (recipes) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError():
        return const Center(child: Text('에러가 발생했습니다.'));
      case AsyncData():
        return _buildRecipeList(recipes.value ?? []);
    }
  }

  Widget _buildRecipeList(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const Center(child: Text('레시피가 없습니다.'));
    }

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return ListTile(
          title: Text(recipe.title),
          onTap: () => onAction(HomeAction.tapRecipe(recipe.id)),
        );
      },
    );
  }
}
```

---

## ✅ 상태 기반 렌더링 (AsyncValue + switch)

AsyncValue 타입으로 관리되는 상태는 **switch-case**를 사용하여 분기한다.  
복잡한 pattern matching 없이 기본적인 Dart 구문으로 작성한다.

- AsyncLoading → 로딩 스피너
- AsyncError → 에러 메시지
- AsyncData → 데이터 렌더링

state 내부의 AsyncValue 필드를 기준으로 switch 분기를 수행한다.

---

## ✅ _buildXXX 함수 분리 원칙

Screen은 복잡해질 수 있는 화면 구조를 작은 빌드 함수로 세분화하여 유지보수성을 높인다.

### 세분화 기준

- UI 구조가 2~3단계 이상 중첩될 때
- 반복적인 리스트나 카드 뷰를 그릴 때
- 조건 분기가 필요한 상태를 표시할 때
- 액션(onAction)이 필요한 위젯 그룹

### 작성 규칙

- `_buildHeader()`, `_buildList()`, `_buildBody()`처럼 목적에 맞게 명확히 함수명을 작성한다.
- 하나의 _buildXXX 함수는 하나의 역할만 수행한다.
- _buildXXX 함수에서는 외부 주입받은 state와 onAction만 사용한다.
- context 기반 동작(context.push, showDialog 등)은 절대 호출하지 않는다.

### 장점

- 가독성 향상 (구조를 빠르게 파악할 수 있다)
- 유지보수성 향상 (특정 영역만 수정 가능)
- 테스트성 향상 (각 build 함수 단위로 테스트 가능)
- 변경 범위 최소화 (영향 범위가 작음)

---

## ✅ 책임 분리 요약

| 계층 | 책임 |
|:---|:---|
| Root | 상태 주입, 액션 연결, context 기반 작업(화면 이동, 다이얼로그 등) |
| Screen | 상태를 기반으로 UI만 렌더링, 액션을 onAction으로 위임 |
| Notifier | 비즈니스 로직 실행, 상태 변경 관리 |

---

## ✅ 테스트 전략

- Screen은 단위 테스트에 적합하다.
- 주입된 가짜 상태(state)를 통해 다양한 화면 조건을 검증할 수 있다.
- onAction이 정상 호출되는지 확인한다.

예시:

```dart
testWidgets('레시피 목록이 있을 때 리스트를 렌더링한다', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        state: HomeState(
          recipeList: const AsyncData([
            Recipe(id: 1, title: 'Test Recipe'),
          ]),
        ),
        onAction: (_) {},
      ),
    ),
  );

  expect(find.text('Test Recipe'), findsOneWidget);
});
```

---

## 📌 최종 요약

- Screen은 StatelessWidget으로 작성한다.
- 상태(state)와 onAction은 외부에서 주입받는다.
- AsyncValue는 switch-case를 통해 분기한다.
- 화면 요소는 _buildXXX() 함수로 작은 단위로 나눈다.
- context 직접 호출은 절대 하지 않고, Root를 통해 간접 호출한다.