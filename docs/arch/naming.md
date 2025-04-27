# 🏷️ 네이밍 규칙 가이드

---

## ✅ 목적

이 문서는 프로젝트 전반에서 사용하는 클래스, 파일, 폴더, 컴포넌트, 프로바이더, 생성자 정의에 대한 명명 규칙을 정의한다.  
일관된 네이밍은 팀 협업, 구조 파악, 검색 가능성, 유지보수성을 높이며  
기능 단위 기반 폴더 구조와도 명확하게 연결되어야 한다.

---

## ✅ 설계 원칙

- 모든 네이밍은 **기능 중심**으로 작성한다.
- 축약, 약어 등을 지양하고 도메인 또는 용도나 의미가 드러나도록 명명한다.
- Snake case (`lower_snake_case`)와 Pascal case (`UpperCamelCase`)를 구분하여 사용한다.
- 파일명은 모두 소문자 + 언더스코어(`_`) 기반으로 작성한다.
- 각 계층별로 고정된 접미사 규칙을 따라야 한다. (아키텍처별 차별 및 추정 원칙)
- Firebase 구현체 외에 API 기반 구현체는 `Impl` 접미사만 사용하며, `Api`, `Rest` 등 기술명 접두사는 금지한다.

---

# ✅ 1. Repository & DataSource 네이밍 및 메서드 규칙

### 📁 Repository

- 도메인 중심 명명: `AuthRepository`, `RecipeRepository` 등
- 인터페이스와 구현 클래스는 동일한 이름 사용 (`AuthRepository`, `AuthRepositoryImpl`)
- 파일명도 동일하게 유지: `auth_repository.dart`, `auth_repository_impl.dart`

#### 📌 Repository 메서드 네이밍 규칙

| 동작 유형   | 접두사 예시              | 설명                         |
|-------------|--------------------------|------------------------------|
| 데이터 조회 | `get`, `load`            | 도메인 객체를 가져오는 경우 |
| 상태 변경   | `toggle`, `update`, `change` | 즐겨찾기, 팔로우 등 상태 전환 |
| 생성/등록   | `save`, `register`, `create` | 새로운 데이터 등록           |
| 삭제        | `delete`, `remove`       | 데이터 제거                  |
| 검증/확인   | `check`, `verify`        | 조건 확인, 유효성 검사 등    |

---

### 📁 DataSource (Firebase 포함)

| 구분        | 클래스명 예시               | 파일명 예시                        |
|-------------|-----------------------------|------------------------------------|
| 인터페이스  | `AuthDataSource`            | `auth_data_source.dart`            |
| API 구현체   | `AuthDataSourceImpl`        | `auth_data_source_impl.dart`       |
| Firebase 구현체 | `AuthFirebaseDataSource`     | `auth_firebase_data_source.dart`   |
| Mock 클래스 | `MockAuthDataSource`        | `mock_auth_data_source.dart`       |

- Firebase만 `Firebase` 접두사를 붙인다.
- API 기반 구현체는 `Impl`만 붙이고 기술명은 쓰지 않는다.
- Mock 클래스는 테스트에서 교체 가능하도록 동일한 인터페이스를 구현한다.

```dart
abstract class AuthDataSource {
  Future<Map<String, dynamic>> fetchLoginData(String email, String password);
}

class AuthFirebaseDataSource implements AuthDataSource {
  /// ...
}

class AuthDataSourceImpl implements AuthDataSource {
  /// ...
}

class MockAuthDataSource implements AuthDataSource {
 /// ...
}
```

#### 📌 DataSource 메서드 네이밍 규칙

| 동작 유형     | 접두사 예시         | 설명                                      |
|----------------|----------------------|-------------------------------------------|
| 네트워크 호출  | `fetch`, `post`, `put`, `delete` | HTTP or Firebase 호출               |
| 응답 변환      | `parse`, `extract`    | JSON, DocumentSnapshot → Model 변환 등   |

---

# ✅ 2. UseCase 네이밍 및 사용 규칙

- 클래스명: `{동작명}UseCase`  
  예: `LoginUseCase`, `ToggleBookmarkUseCase`
- 파일명: `{동작명}_use_case.dart`  
  예: `login_use_case.dart`, `get_profile_use_case.dart`
- 메서드는 기본적으로 `execute()` 사용

```dart
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<AsyncValue<User>> execute(String email, String pw) async {
    final result = await _repository.login(email, pw);
    return result.when(
      success: (user) => AsyncData(user),
      error: (e) => AsyncError(e.message),
    );
  }
}
```

---

# ✅ 3. Presentation 계층 네이밍

### 📁 구성 예시

```
presentation/
└── feature_name/
    ├── feature_name_action.dart
    ├── feature_name_state.dart
    ├── feature_name_view_model.dart
    ├── feature_name_screen_root.dart
    ├── feature_name_screen.dart
    └── component/
```

### 📌 컴포넌트 네이밍

- **기능명 접두사 필수**
    - `profile_header.dart`, `profile_stat_card.dart`
- 단순 역할명 (`header.dart`, `tab_bar.dart`) 지양
- 공통 요소가 되지 않은 컴포넌트는 각 기능 폴더 내에 위치시키고 `_common` 접미사 사용
    - 예: `profile_header_common.dart`

---

# ✅ 4. 생성자 정의 및 주입 규칙

- 모든 주입 필드는 `final` + `_` 접두사로 선언
- 생성자에서는 `required`로 명시적으로 받음
- 외부 노출을 막기 위해 `_` 접두사로 캡슐화
- 변경 불가능한 구조로 불변성 유지

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl({required AuthDataSource dataSource}) : _dataSource = dataSource;
}
```

---

# ✅ 5. 프로바이더 및 상태 객체 명명

- Notifier 기반 상태 프로바이더는 `{기능명}NotifierProvider`
- 도출 상태값은 `{도출명}Provider`, 파생값 명시
- 상태 클래스는 `{기능명}State`
- 액션 클래스는 `{기능명}Action`

---

# ✅ 네이밍 요약표

| 항목           | 예시                         | 설명                                    |
|----------------|------------------------------|-----------------------------------------|
| Repository     | `AuthRepository`             | interface / impl 동일                    |
| DataSource     | `AuthDataSourceImpl`         | API 전용, Firebase는 별도                |
| UseCase        | `LoginUseCase`               | 비즈니스 단위 로직                      |
| Notifier      | `ProfileNotifier`           | 상태 관리 + 액션 분기                   |
| State          | `ProfileState`               | freezed 기반 상태 클래스                |
| Action         | `ProfileAction`              | sealed class 기반 액션 정의             |
| ScreenRoot     | `ProfileScreenRoot`          | 상태 주입 및 context 처리               |
| Screen         | `ProfileScreen`              | 순수 UI                                 |
| Component      | `profile_stat_card.dart`     | 기능 접두사 필수                         |
| 공통 컴포넌트   | `profile_header_common.dart` | 공통화 이전 기능 내 위치                 |
| Provider       | `loginNotifierProvider`     | Notifier 기준 상태 주입                |
| 생성자 필드    | `_repository`                | final + 프라이빗 + required 주입        |

---

## 🔁 참고 링크

- [folder.md](folder.md)
- [layer.md](layer.md)
- [usecase.md](../logic/usecase.md)
- [Notifier.md](../logic/notifier.md)
- [repository.md](../logic/repository.md)
- [screen.md](../ui/screen.md)