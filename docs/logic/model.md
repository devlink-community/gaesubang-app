# 📄 `docs/logic/model.md`

---

# 🧬 Model (Entity) 설계 가이드

## ✅ 목적

Model은 앱 내부에서 사용하는 **도메인 중심의 데이터 구조**입니다.  
UI, UseCase, Repository 등에서 공통적으로 사용되며,  
외부 의존성이 없는 **순수 비즈니스 객체**로 유지하는 것이 원칙입니다.

---

## 🧱 설계 원칙

- 모든 모델은 **Freezed** 기반으로 정의
- 불변성(Immutable) 유지
- **필수값은 `required`**, 선택값은 `nullable` 처리
- API 기반 DTO와는 분리하며, 필요 시 Mapper를 통해 변환
- freezed 3.x 최신 방식으로 직접 constructor를 작성한다.  
  (const User({required this.id}) 형태 사용, const factory = _User 형태 금지'

---

## ✅ 파일 위치 및 네이밍

| 항목 | 규칙 |
|------|------|
| 파일 경로 | `lib/{기능}/domain/model/` |
| 파일명 | `snake_case.dart` (예: `user.dart`) |
| 클래스명 | `PascalCase` (예: `User`) |
| 관련 파일 | `.freezed.dart` 는 codegen 자동 생성 |

---

## ✅ 예시

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const User({
    required this.id,
    required this.email,
    required this.username,
  });

  final int id;
  final String email;
  final String username;
}
```

---

## 📌 설계 팁

- 모델은 UI에 직접 노출되지 않아야 하며, ViewModel이나 Mapper에서 가공 후 전달
- 날짜나 금액 등은 가능한 한 **타입 명확성** 유지 (ex: `DateTime`, `int`, `double`)
- 확장 가능성을 고려해 `copyWith`, `==`, `hashCode`는 `freezed`로 자동 생성

---

## 🧪 테스트 전략

- 모델은 테스트 자체보다는 **Mapper 또는 ViewModel 레벨에서 활용도 확인**
- 데이터 간 일관성 검증이 필요할 경우, 별도 `value object`로 감싸는 것도 고려

---

## 🔁 관련 문서 링크

- [dto.md](dto.md): API 응답/요청 데이터 구조
- [mapper.md](mapper.md): DTO ↔ Model 변환 방식
- [usecase.md](usecase.md): 모델을 기반으로 상태 가공하는 흐름