# 🛠️ 유틸리티 설계 가이드

---

## ✅ 목적

프로젝트에서 사용하는 공통 유틸리티들의 작성 규칙과 관리 방법을 정의합니다.  
중복 코드를 방지하고, 일관된 방식으로 유틸리티를 관리하여 코드의 재사용성과 유지보수성을 높입니다.

---

## 🧱 설계 원칙

- **중복 방지**: 새로운 유틸 작성 전 기존 유틸 확인 필수
- **단일 책임**: 하나의 유틸 클래스는 하나의 목적만 수행
- **테스트 가능**: 순수 함수 형태로 작성하여 테스트 용이성 확보
- **중앙 집중**: 모든 유틸리티는 `lib/core/utils/`에서 관리

---

## 📁 파일 위치 및 네이밍

### 위치
- **모든 유틸리티**: `lib/core/utils/`에서 중앙 관리
- 기능별 분산 금지 - 중복 방지와 일관성 유지를 위해

### 네이밍 규칙

| 유형 | 네이밍 패턴 | 예시 |
|------|-------------|------|
| **상수 클래스** | `{도메인}Constants` | `AuthConstants`, `AppConstants` |
| **에러 메시지** | `{도메인}ErrorMessages` | `AuthErrorMessages`, `NetworkErrorMessages` |
| **변환 유틸** | `{대상}Converter` | `FirebaseTimestampConverter`, `DateConverter` |
| **예외 매퍼** | `{도메인}ExceptionMapper` | `AuthExceptionMapper`, `NetworkExceptionMapper` |
| **유효성 검사** | `{도메인}Validator` | `EmailValidator`, `PasswordValidator` |
| **헬퍼 클래스** | `{기능}Helper` | `ImageHelper`, `UrlHelper` |

---

## 📋 기존 유틸리티 목록

### 1. 에러 메시지 유틸

#### `lib/core/utils/auth_error_messages.dart`
인증 관련 모든 에러 메시지를 중앙 관리합니다.

주요 메시지:
- `loginFailed`: 로그인에 실패했습니다
- `noLoggedInUser`: 로그인된 사용자가 없습니다
- `emailAlreadyInUse`: 이미 사용 중인 이메일입니다
- `nicknameAlreadyInUse`: 이미 사용 중인 닉네임입니다

사용법:
```dart
Exception(AuthErrorMessages.noLoggedInUser)
```

### 2. Firebase 변환 유틸

#### `lib/core/utils/firebase_timestamp_converter.dart`
Firebase Timestamp와 Dart DateTime 간 변환을 처리합니다.

주요 메서드:
- `timestampFromJson()`: Firebase Timestamp → DateTime
- `timestampToJson()`: DateTime → Firebase Timestamp

사용법:
```dart
@JsonKey(
  fromJson: FirebaseTimestampConverter.timestampFromJson,
  toJson: FirebaseTimestampConverter.timestampToJson,
)
final DateTime? createdAt;
```

### 3. 예외 매핑 유틸

#### `lib/core/utils/auth_exception_mapper.dart`
인증 관련 예외를 Failure 객체로 변환합니다.

주요 메서드:
- `mapAuthException()`: Exception → Failure 변환
- `validateEmail()`: 이메일 유효성 검사
- `validateNickname()`: 닉네임 유효성 검사

사용법:
```dart
return Result.error(AuthExceptionMapper.mapAuthException(e, st));
```

---

## ✅ 유틸 작성 가이드

### 1. 새 유틸 작성 전 체크리스트

1. **기존 유틸 확인**: `lib/core/utils/` 폴더에서 유사한 기능 검색
2. **네이밍 검토**: 위의 네이밍 규칙 적용
3. **구조 설계**: static 메서드 기반으로 작성
4. **테스트**: 순수 함수 형태로 테스트 가능하게 설계

### 2. 작성 템플릿

#### 상수 클래스
```dart
class {Domain}Constants {
  // 생성자 private으로 설정
  const {Domain}Constants._();
  
  static const String key1 = 'value1';
  static const int timeout = 30;
}
```

#### 변환 유틸
```dart
class {Target}Converter {
  const {Target}Converter._();
  
  static TargetType convert(SourceType source) {
    // 변환 로직
  }
  
  static SourceType reverse(TargetType target) {
    // 역변환 로직
  }
}
```

#### 에러 메시지
```dart
class {Domain}ErrorMessages {
  const {Domain}ErrorMessages._();
  
  static const String error1 = '에러 메시지 1';
  static const String error2 = '에러 메시지 2';
}
```

#### 예외 매퍼
```dart
class {Domain}ExceptionMapper {
  const {Domain}ExceptionMapper._();
  
  static Failure mapException(Object error, StackTrace stackTrace) {
    // 예외 매핑 로직
  }
}
```

### 3. 사용 시 주의사항

- 새 유틸 작성 전 반드시 기존 유틸 확인
- 비슷한 기능이 있다면 기존 유틸 확장 검토
- 유틸 수정 시 영향 범위 확인
- 테스트 코드 작성 필수

---

## 🧪 테스트 전략

- 모든 유틸리티는 단위 테스트 필수
- 순수 함수 형태로 작성하여 테스트 용이성 확보
- 경계값, 예외 상황에 대한 테스트 포함

---

## 🔁 관련 문서 링크

- [error.md](error.md): 예외 처리 및 Failure 설계
- [result.md](result.md): Result 패턴 설계
- [naming.md](naming.md): 전반적인 네이밍 규칙

---

## ✅ 문서 요약

- 모든 유틸리티는 `lib/core/utils/`에서 중앙 관리
- 일관된 네이밍 규칙 적용
- 새 유틸 작성 전 기존 유틸 확인 필수
- static 메서드 기반으로 작성
- 테스트 가능한 순수 함수 형태 권장
