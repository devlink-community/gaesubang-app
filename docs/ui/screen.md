# 🖥️ Screen 설계 가이드

---

## ✅ 목적

Screen은 사용자에게 보여지는 UI를 구성하는 **순수 뷰 컴포넌트 계층**입니다.  
앱의 상태나 액션 처리 로직은 갖지 않으며, 오직 전달받은 상태(state)와 이벤트 핸들러만으로 화면을 구성합니다.

---

## 🧱 설계 원칙

- **StatelessWidget**으로 정의
- ViewModel 또는 context를 직접 참조하지 않음
- 상태와 액션은 외부에서 주입받음 (`state`, `onAction`)
- 내부 UI는 `_buildXXX()` 함수로 명확히 분리
- context가 필요한 로직 (navigation, dialog 등)은 Root에서만 수행

---

## ✅ 파일 구조 및 위치

```text
lib/
└── profile/
    └── presentation/
        ├── profile_screen.dart         # 순수 UI
        ├── profile_screen_root.dart    # 상태 주입 + context 사용
```

> 📎 전체 폴더 구조는 [../arch/folder.md](../arch/folder.md) 참고

---

## ✅ 클래스 구성 및 패턴

### Screen 예시

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
    return Column(
      children: [
        Text('이름: ${state.user.name}'),
        ElevatedButton(
          onPressed: () => onAction(const ProfileAction.onTapEdit()),
          child: const Text('편집'),
        ),
      ],
    );
  }
}
```

> 상태 기반 렌더링만 수행하며, 내부 조건 분기/컴포넌트 분리는 `_buildXXX()` 함수 활용

## ✅ `_buildXXX()` 로 분리 예시
### 1. `_buildHeader()`

상단 고정 타이틀, 프로필 정보, 아이콘 영역 등에 적합

```dart
Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('프로필', style: Theme.of(context).textTheme.titleLarge),
      IconButton(
        icon: Icon(Icons.settings),
        onPressed: () => onAction(const ProfileAction.onTapSetting()),
      ),
    ],
  );
}
```

---

### 2. `_buildContent()`

본문 상세 정보 블록(프로필 카드, 정보 리스트 등)에 적합

```dart
Widget _buildContent() {
  final user = state.user;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('이름: ${user.name}'),
      Text('이메일: ${user.email}'),
    ],
  );
}
```

---

### 3. `_buildPostList()`

게시물, 댓글, 알림 등 리스트 표현에 적합

```dart
Widget _buildPostList() {
  if (state.posts.isEmpty) {
    return const Center(child: Text('게시물이 없습니다.'));
  }

  return ListView.separated(
    itemCount: state.posts.length,
    separatorBuilder: (_, __) => const Divider(),
    itemBuilder: (_, index) {
      final post = state.posts[index];
      return ListTile(
        title: Text(post.title),
        onTap: () => onAction(ProfileAction.onTapPost(post.id)),
      );
    },
  );
}
```

---

### 4. `_buildBottomAction()`

하단 고정 버튼 영역(로그아웃, 저장, 완료 등)에 적합

```dart
Widget _buildBottomAction() {
  return ElevatedButton(
    onPressed: () => onAction(const ProfileAction.onTapLogout()),
    child: const Text('로그아웃'),
  );
}
```

---

### 5. `_buildLoadingOrError()`

로딩, 에러 등 상태 분기를 위한 공통 처리 영역

```dart
Widget _buildLoadingOrError() {
  return switch (state.status) {
    ProfileStatus.loading => const CircularProgressIndicator(),
    ProfileStatus.error => Text('에러: ${state.errorMessage}'),
    _ => const SizedBox.shrink(),
  };
}
```

---

### 6. `_buildMenuList()`

간단한 버튼 목록이나 고정 메뉴에 적합 (데이터 없음)

```dart
Widget _buildMenuList() {
  final items = ['설정', '로그아웃', '피드백'];

  return Column(
    children: items.map((title) {
      return ListTile(
        title: Text(title),
        onTap: () => onAction(ProfileAction.onTapMenu(title)),
      );
    }).toList(),
  );
}
```

---

### 7. `_buildStatusBanner(ProfileStatus status)`

파라미터 기반 조건 분기 표현 (enum 등 활용)

```dart
Widget _buildStatusBanner(ProfileStatus status) {
  switch (status) {
    case ProfileStatus.active:
      return const Text("정상 활동 중입니다.");
    case ProfileStatus.banned:
      return const Text("제재 중인 사용자입니다.");
    default:
      return const SizedBox.shrink();
  }
}
```

---

### 8. `_buildReviewTile(...)`

파라미터가 많아질 경우 명시적 인자 패턴 사용

```dart
Widget _buildReviewTile({
  required String author,
  required String comment,
  required double rating,
}) {
  return ListTile(
    title: Text(author),
    subtitle: Text(comment),
    trailing: Text('$rating점'),
  );
}
```

---

### 9. `_buildTaggedPosts(List<Post> posts, String tag)`

조건에 따라 필터링된 리스트를 표현할 때 적합

```dart
Widget _buildTaggedPosts(List<Post> posts, String tag) {
  final filtered = posts.where((p) => p.tags.contains(tag)).toList();

  return Column(
    children: filtered.map((p) => Text(p.title)).toList(),
  );
}
```

---

### 10. `_buildAsyncContent(AsyncValue<Profile> state)`

`.when()` 구문을 함수 내부로 캡슐화하여 깔끔한 외부 표현 가능

```dart
Widget _buildAsyncContent(AsyncValue<Profile> state) {
  return state.when(
    loading: () => const CircularProgressIndicator(),
    data: (profile) => _buildProfileCard(profile),
    error: (e, _) => Text('에러: $e'),
  );
}
```

---

## ✅ `_buildXXX()` 함수 분리의 장점

### 1. **가독성 향상**

- **간결하고 명확한 코드**로 유지보수가 쉬워짐
- UI 구성 요소를 작은 단위로 분리하여 **한눈에 보기 쉬운 구조**로 유지

### 2. **컴포넌트 재사용 용이**

- **반복되는 UI**를 함수로 분리함으로써, **다른 화면에서 재사용**하기 용이
- 필요할 때는 **위젯화**하여 다른 화면에서도 쉽게 활용 가능

### 3. **유지보수 및 확장성**

- 새로운 UI 요소를 추가하거나 기존 UI를 수정할 때,  
  변경이 필요한 부분을 **명확하게 구분**하여 유지보수하기 좋음
- 추후 **공통 컴포넌트로의 확장**이 용이함 (예: 버튼, 리스트 아이템 등)

### 4. **테스트 용이성**

- **단위 테스트**가 용이한 구조
- 함수 별로 UI 상태를 독립적으로 테스트하거나 **상태 변경 흐름**을 검증할 수 있음

### 5. **코드 중복 최소화**

- `ListView`, `Column` 등 여러 화면에서 반복될 UI 구성 요소를 한 번만 정의하고 **재사용** 가능
- 특정 UI 블록에 대한 **로직 변경**이 생기더라도 해당 함수만 수정하면 되므로, 중복 코드가 줄어들고 **변경 범위가 최소화**됨

### 6. **UI와 로직의 분리**

- UI 구성과 **비즈니스 로직**이 명확히 구분되어 서로의 의존도가 줄어들고,  
  **확장성과 테스트 가능성이 높아짐**

> 예시: `loginScreen`에서 로그인 로직과 화면 구성만 분리하여 관리

---

## 📌 책임 구분

| 계층 | 역할 |
|------|------|
| Screen | 순수 UI 구성, 상태 렌더링 |
| Root | 상태 구독, context 처리, ViewModel 주입 |
| ViewModel | 상태 관리 및 액션 처리 |
| UseCase | 비즈니스 로직 수행 |

> 📎 역할 분리는 [view_vs_root.md](view_vs_root.md) 참고

---

## ✅ 상태 렌더링 방식

- 단순 조건: if 문으로 직접 처리
- 복잡 분기: `_buildXXXByState()` 또는 서브 위젯 분리
- `AsyncValue` 기반 상태는 `.when()` 또는 `map()`으로 렌더링

```dart
ref.watch(profileProvider).when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('에러: $e'),
  data: (state) => ProfileScreen(
    state: state,
    onAction: ref.read(profileProvider.notifier).onAction,
  ),
);
```

---

## ✅ 테스트 가이드

- 상태 객체를 전달하여 다양한 UI 상태 조건 검증
- ViewModel/Root 분리로 인해 Screen은 **순수 단위 테스트 가능**
- 렌더링 분기, 버튼 텍스트, 이벤트 콜백 동작 등을 테스트

---

## 🔁 관련 문서 링크

- [viewmodel.md](viewmodel.md): 상태 전달 구조 및 이벤트 처리
- [state.md](state.md): 상태 모델 정의
- [view_vs_root.md](view_vs_root.md): Screen vs Root 역할 구분
- [../arch/naming.md](../arch/naming.md): 컴포넌트 네이밍 규칙