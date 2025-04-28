# 🔄 `docs/logic/mapper.md`

---

# 🧭 Mapper 설계 가이드

## ✅ 목적

Mapper는 외부 DTO를 내부 Model로 변환하고,  
반대로 Model을 다시 DTO로 바꾸는 **데이터 구조 변환 계층**입니다.  
이 프로젝트에서는 **Dart의 `extension` 기능**을 활용해  
더 깔끔하고 직관적인 방식으로 변환을 수행합니다.

---

## 🧱 설계 원칙

- 모든 변환은 `extension`으로 정의
- 메서드 이름은 `toModel()`, `toDto()` 고정
- 리스트 변환도 별도의 extension으로 처리 (`toModelList()`)
- `null` 안전성 확보 필수

---

## ✅ 파일 위치 및 네이밍

| 항목 | 규칙 |
|------|------|
| 파일 경로 | `lib/{기능}/data/mapper/` |
| 파일명 | `snake_case_mapper.dart` (예: `user_mapper.dart`) |
| 클래스명 | 없음 → 대신 확장 대상명 + `Mapper` |
| 메서드명 | `toModel()`, `toDto()` 등 |

---

## ✅ 기본 예시

```dart
import '../../domain/model/user.dart';
import '../dto/user_dto.dart';
```

### 📌 DTO → Model 변환

```dart
extension UserDtoMapper on UserDto {
  User toModel() {
    return User(
      id: id?.toInt() ?? -1,
      email: email ?? '',
      username: username ?? '',
    );
  }
}
```

---

### 📌 Model → DTO 변환

```dart
extension UserModelMapper on User {
  UserDto toDto() {
    return UserDto(
      id: id,
      email: email,
      username: username,
    );
  }
}
```

---

### 📌 List<DTO> → List<Model> 변환

```dart
extension UserDtoListMapper on List<UserDto>? {
  List<User> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}
```

---

### 📌 Map → DTO 변환

```dart
extension MapToUserDto on Map<String, dynamic> {
  UserDto toDto() => UserDto.fromJson(this);
}
```

---

### 📌 List<Map<String, dynamic>> → List<DTO> 변환

```dart
extension MapListToUserDtoList on List<Map<String, dynamic>>? {
  List<UserDto> toUserDtoList() => this?.map((e) => UserDto.fromJson(e)).toList() ?? [];
}
```

---

## 🧪 테스트 전략

- 각 extension은 순수 함수이므로 단위 테스트 용이
- `dto.toModel()` 입력에 `null`, 빈 필드 포함 시 안전하게 처리되는지 확인
- 리스트 확장은 `null → []` 처리되는지 체크

---

## ✨ 장점 요약

| 항목 | 설명 |
|------|------|
| 가독성 | `dto.toModel()`처럼 체이닝 가능 |
| 확장성 | 다양한 DTO/Model 조합에 일관 적용 가능 |
| 테스트성 | 순수 함수 형태로 독립 테스트 용이 |

---

## 🔁 관련 문서 링크

- [dto.md](dto.md): 외부 응답 구조 정의
- [model.md](model.md): 내부 Entity 정의
- [repo.md](repository.md): Mapper 사용 위치
- [datasource.md](datasource.md): API 응답 DTO → Mapper 변환 위치