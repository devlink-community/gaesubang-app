# 🌐 DataSource 설계 가이드

## ✅ 목적

DataSource는 외부 데이터와의 연결 지점을 담당하며,  
API 호출, Firebase 작업, LocalStorage 접근 등을 수행하는 **실제 입출력 계층**입니다.  
Repository는 이 계층을 통해 데이터를 요청하고, 예외 상황을 처리합니다.

---

## 🧱 설계 원칙

- 항상 **interface 정의 → 구현체 분리**
- 실제 API 기반 구현체 외에 Firebase 또는 목업 구현도 병행 가능
- **Exception은 그대로 throw**, 가공은 Repository에서 처리

---

## ✅ 파일 구조 및 위치

```
lib/
└── auth/
    └── data/
        └── data_source/
            ├── auth_data_source.dart                 # 인터페이스
            ├── auth_data_source_impl.dart            # 일반 API용
            ├── auth_firebase_data_source_impl.dart   # Firebase용
            └── mock_auth_data_source.dart            # 테스트용
```

> 📎 전체 폴더 구조 가이드는 [../arch/folder.md](../arch/folder.md)

---

## ✅ 네이밍 및 클래스 구성

```dart
// 인터페이스
abstract interface class AuthDataSource {
  Future<Map<String, dynamic>> fetchLogin(String email, String password);
}
```

### 일반 API 구현체

```dart
class AuthDataSourceImpl implements AuthDataSource {
  @override
  Future<Map<String, dynamic>> fetchLogin(String email, String password) async {
    // 일반 API 호출
  }
}
```

### Firebase 구현체

```dart
class AuthFirebaseDataSourceImpl implements AuthDataSource {
  @override
  Future<Map<String, dynamic>> fetchLogin(String email, String password) async {
    // FirebaseAuth 또는 Firestore 사용
  }
}
```

### Mock 구현체

```dart
class MockAuthDataSource implements AuthDataSource {
  @override
  Future<Map<String, dynamic>> fetchLogin(String email, String password) async {
    return {'id': 1, 'email': email, 'username': 'MockUser'};
  }
}
```
> 📎 메소드명 등의 네이밍 규칙은 [../arch/naming.md](../arch/naming.md)
> 📎 DTO 구조는 [dto.md](dto.md)  
> 📎 Mapper 예시는 [mapper.md](mapper.md)

---

## ✅ 예외 처리 전략

- DataSource에서는 오류가 발생해도 직접 처리하지 않고, 그대로 예외를 던집니다  
  (예: `throw Exception(...)`, `throw DioError(...)`, `throw FirebaseAuthException(...)` 등).
- 예외를 try-catch로 잡아서 Failure로 바꾸는 일은 Repository에서 담당합니다.
- 즉, 예외 처리 코드는 Repository에만 작성하고, DataSource에는 작성하지 않습니다.

> 📎 예외 매핑 유틸은 [../arch/error.md](../arch/error.md)

---

## 🧪 테스트 가이드

- 실제 테스트는 `MockDataSource` 또는 Firebase Emulator로 구성
- 비즈니스 로직 테스트 시 `AuthRepository`에 mock 주입

> 📎 Repository 테스트 및 흐름 구조는 [repository.md](repository.md)