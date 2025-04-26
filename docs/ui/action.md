# 🎯 Action 설계 가이드

---

## ✅ 목적

Action은 사용자 인터랙션을 추상화하여 ViewModel 또는 Root에 명확하게 전달하는 단위입니다.  
UI에서 발생한 이벤트는 직접 처리하지 않고 Action으로 표현되며,  
비즈니스 로직 처리와 UI 반응의 책임을 분리하는 역할을 합니다.

---

## ✅ 설계 원칙

- 모든 사용자 이벤트는 Action 클래스로 추상화하여 전달한다.
- Action은 `freezed` 기반의 `sealed class`로 정의한다.
- UI는 Action을 생성하여 전달만 하며, 내부에 처리 로직을 포함하지 않는다.
- Action은 상태 변경이 필요한 경우 ViewModel에서, context 기반 UI 처리가 필요한 경우 Root에서 처리한다.
- `BuildContext`는 절대 Action 내부에 포함하지 않는다.

---

## ✅ 예시

```dart
@freezed
sealed class ProfileAction with _$ProfileAction {
  const factory ProfileAction.onTapFollow(int userId) = OnTapFollow;
  const factory ProfileAction.onTapEdit() = OnTapEdit;
}
```

---

## ✅ 파일 구조 및 위치

- 위치: `lib/{기능}/presentation/`
- 파일명: `{기능명}_action.dart`
- 클래스명: `{기능명}Action` (예: `LoginAction`, `ProfileAction`)

- 폴더 구조 관련 내용은 [../arch/folder.md]([../arch/folder.md])
- 네이밍 규칙은 [../arch/naming.md]([../arch/naming.md])

---

## ✅ 네이밍 규칙

- 각 액션은 **사용자 인터랙션의 의도를 명확히 표현하는 방식**으로 명명해야 한다.
- 이벤트를 **기술적으로 처리하는 방식**이 아니라, 사용자가 **무엇을 시도했는지를 표현**하는 것이 중요하다.
- 예를 들어 `fetchData`, `submitForm` 같은 표현은 내부 구현 중심이며, `onTapSubmit`, `onLoadItems` 등 **행동 중심 표현**으로 바꾸는 것이 적절하다.

| 유형           | 접두사             | 예시                             |
|----------------|--------------------|----------------------------------|
| 버튼 클릭       | onTap, onPressed   | onTapFollow(int id)              |
| 입력 변경       | onChange           | onChangeNickname(String name)    |
| 요청 트리거     | onLoad, onRequest  | onLoadUser()                     |
| 초기화/닫기     | onInit, onClose    | onInitForm(), onCloseDialog()    |

- ✅ **사용자 중심 표현**: onTapEdit, onLoadPosts
- ❌ **구현 중심 표현**: fetchProfileData, submitEditForm

---

## ✅ 액션 처리 위치: ViewModel과 Root의 역할 구분

사용자 이벤트는 모두 액션으로 표현되며, 이를 **어디에서 처리할지는 목적에 따라 분리**되어야 한다.  
Action을 **ViewModel이 처리할지**, 또는 **Root에서 처리할지**는 **다음 기준**을 따른다.

---

### 🔹 ViewModel이 처리해야 하는 경우

- 상태를 변경하거나 서버 요청 등 **비즈니스 로직**이 포함된 경우
- UI가 아닌 **앱 상태 자체를 변경하는** 책임

**예시**
- `onChangeTitle(String)` → 상태 업데이트
- `onTapFollow(int id)` → 팔로우 상태 토글
- `onLoadProfile()` → 프로필 정보 API 요청

---

### 🔸 Root에서 처리해야 하는 경우

- `context`가 필요한 작업 등 **UI 반응을 위한 처리**
- ViewModel에서 상태를 바꾸지 않고, **단순히 반응하는 동작**

**예시**
- `onTapEdit()` → `context.push()`로 이동
- `onShowToast(String message)` → 메시지 표시
- `onCloseModal()` → Navigator pop

---

## 🔁 참고 링크

- [viewmodel.md](viewmodel.md)
- [screen.md](screen.md)
- [state.md](state.md)
- [view_vs_root.md](view_vs_root.md)

---

이제 정확한 구조와 표현으로 완성된 `action.md` 문서입니다.  
이 상태로 확정하셔도 되고, 수정이 필요하면 말씀만 주세요.