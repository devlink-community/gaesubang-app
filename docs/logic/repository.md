# 🧩 Repository 설계 가이드

## ✅ 목적

Repository는 DataSource를 통해 외부 데이터를 가져오고,  
앱 내부에서 사용할 수 있도록 도메인 모델로 가공하는 **중간 추상화 계층**입니다.  
UseCase 또는 ViewModel은 Repository를 통해 간접적으로 데이터를 접근합니다.

---

## 🧱 설계 원칙

- 항상 `interface` + `impl` 구조로 분리합니다.
- 내부에서 DataSource를 호출하며, 외부 예외는 `Failure`로 변환합니다.
- 반환 타입은 `Result<T>`
- 외부로 노출되는 데이터는 DTO가 아닌 **Entity(Model)** 을 기준으로 처리합니다.

---

## ✅ 파일 구조 및 위치

```
lib/
└── user/
    ├── domain/
    │   └── repository/user_repository.dart              # 인터페이스
    └── data/
        └── repository_impl/user_repository_impl.dart         # 구현체
```

> 📎 전체 폴더 구조는 [../arch/folder.md](../arch/folder.md)

---

## ✅ 네이밍 및 클래스 구성

### 인터페이스 예시

```dart
abstract interface class UserRepository {
  Future<Result<User>> login(String email, String password);
  Future<Result<void>> updateProfile(User updated);
}
```

### 구현체 예시

```dart
class UserRepositoryImpl implements UserRepository {
  final AuthDataSource _dataSouce;

  UserRepositoryImpl(this._dataSouce);

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final dto = await _dataSouce.fetchLogin(email, password);
      return Result.success(dto.toModel());
    } catch (e) {
      return Result.error(mapExceptionToFailure(e));
    }
  }
}
```

> 📎 DataSource 구성은 [datasource.md](datasource.md)  
> 📎 Mapper 확장 방식은 [mapper.md](mapper.md)  
> 📎 모델 정의는 [model.md](model.md)  
> 📎 네이밍 규칙은 [../arch/naming.md](../arch/naming.md)

---

## 📌 책임 구분

| 계층 | 역할 |
|------|------|
| DataSource | 외부 호출 + DTO 반환 + 예외 throw |
| Repository | 예외 → Failure 변환, DTO → Model 변환, Result<T> 반환 |
| UseCase | Result → UiState 변환 |

> 📎 UseCase 흐름은 [usecase.md](usecase.md)

---

## ✅ 예외 처리 전략

- 모든 외부 호출은 try-catch로 감싸야 함
- 예외 발생 시 `Failure`로 변환하여 `Result.error`로 반환
- 공통 변환 유틸: `mapExceptionToFailure()`

> 📎 예외 → Failure 변환 로직은 [../arch/error.md](../arch/error.md)

---

## 🧪 테스트 가이드

- Repository 테스트 시 DataSource는 mock으로 대체
- 성공/실패/예외에 따른 `Result<T>` 상태를 검증
- 비즈니스 로직 없이 단순한 흐름만 검증 가능

```dart
test('login returns Result.success on valid credentials', () async {
  when(mockDataSource.fetchLogin(any, any)).thenAnswer((_) async => mockDto);
  final result = await repository.login('email', 'pw');
  expect(result, isA<Success<User>>());
});
```

> 📎 DTO 구조는 [dto.md](dto.md)  
> 📎 Model 정의는 [model.md](model.md)
