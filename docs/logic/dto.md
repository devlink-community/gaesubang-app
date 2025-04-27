# 📥 DTO (Data Transfer Object) 설계 가이드

## ✅ 목적

DTO는 외부 시스템(API, Firebase 등)과의 통신을 위한  
**입출력 전용 데이터 구조**입니다.

앱 내부에서 직접 사용하는 도메인 모델(Entity)와는 분리되어야 하며,  
Mapper를 통해 변환해서 사용합니다.

---

## 🧱 설계 원칙

- **nullable 허용**: 외부 응답은 항상 불완전할 수 있으므로 모든 필드는 nullable로 정의
- **숫자형은 `num` 기본 사용**: API에서 `int`/ `double` 구분이 불명확한 경우 대비
- `fromJson`, `toJson` 메서드 포함
- `@JsonKey`로 snake_case → camelCase 매형 대응
- **중차/리스트 구조 포함 시 `explicitToJson: true`를 값으로 값을 명시적으로 할당**

---

## ✅ 파일 위치 및 네이밍

| 항목 | 규칙 |
|------|------|
| 파일 경로 | `lib/{기능}/data/dto/` |
| 파일명 | `snake_case_dto.dart` (예: `user_dto.dart`) |
| 클래스명 | PascalCase + `Dto` 접미사 (예: `UserDto`) |
| codegen 파일 | `.g.dart` 자동 생성 (`json_serializable` 사용 시) |

---

## ✅ 예시

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  const UserDto({
    this.id,
    this.email,
    this.username,
  });

  final num? id;
  final String? email;
  final String? username;

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
```

---

## 🔁 DTO ↔ Model 변환

- DTO는 직접 앱에 사용하지 않고 반복적으로 **Mapper**를 통해 Model로 변환합니다.
- DTO는 ViewModel 또는 UI에서 직접 접근하지 않습니다.
> 함수: [mapper.md](mapper.md)

---

## ✅ 기타 고려사항

| 항목 | 설명 |
|:---|:---|
| 불완전한 응답 대비 | 모든 필드를 `nullable`로 선언 |
| 서버 응답 필드명 다름 | `@JsonKey(name: "snake_case")` 활용 |
| 리스트/중첩 구조 | `List<SubDto>?`, `SubDto.fromJson()`을 통해 변환. `toJson` 시 `@JsonSerializable(explicitToJson: true)` 설정 필요 |
| freezed 버전 규정 | **freezed 3.x 최신 방식 준수**: `const UserDto({this.id})` 형태로 직접 constructor 작성. `const factory ... = _UserDto;` 형태는 사용 금지 |
| freezed 설정 주의 | DTO는 `@JsonSerializable`만 사용하여 관리. `@freezed` 어노테이션은 사용하지 않음 |

---

## ✅ 중차 및 리스트 구조 구성 예시

```dart
@JsonSerializable(explicitToJson: true)
class ParentDto {
  const ParentDto({this.children});

  final List<ChildDto>? children;

  factory ParentDto.fromJson(Map<String, dynamic> json) => _$ParentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ParentDtoToJson(this);
}
```

> 표준: 내부 DTO들의 `toJson()` 호출을 명시적으로 처리할 때 `explicitToJson: true`를 포함해야 안전함.

---

## 🔁 관련 문서 링크

- [mapper.md](mapper.md): DTO ↔ Model 변환 처리
- [model.md](model.md): 내부 Entity 정의
- [datasource.md](datasource.md): DTO를 사용하는 API 처리 로지구

