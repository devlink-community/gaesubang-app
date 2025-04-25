# 🧱 레이어별 책임 및 흐름 가이드

---

## ✅ 목적

이 문서는 프로젝트 전반에 적용되는 **클린 아키텍처 기반의 레이어 책임**을 정의하며,  
각 레이어의 역할, 흐름, 의존 관계를 명확히 하여 **일관된 구조와 유지보수성**을 확보한다.

---

## ✅ 설계 원칙

- 모든 로직은 `data → domain → presentation` 순서로 흐름이 이동한다.
- UI는 오직 상태를 기반으로 렌더링만 수행하며, 처리 책임은 하위 계층에 위임한다.
- 레이어 간 의존성은 반드시 아래 방향(하향식)으로만 흐른다:
    - UI → ViewModel → UseCase → Repository Interface → DataSource
- Repository 구현체는 domain을 참조하지만, domain은 data를 알지 못한다.
- 의존성 주입과 라우팅은 module 계층에서만 수행하며, presentation에서 직접 DI를 호출하지 않는다.

---

## ✅ 레이어 구조 및 흐름 요약

```
UI (Screen)
↓
ScreenRoot → ViewModel (상태 관리 및 액션 처리)
↓
UseCase (도메인 중심 로직 수행, 객체 형태 반환 -> RiverPod 자체 패턴)
↓
Repository Interface (정의만 존재, Result 패턴으로 반환)
↓
Repository Impl → DataSource (구현 + 외부 연동)
```

> 각 단계에서 발생한 예외는 Result 또는 Failure로 변환하여 상위 계층으로 안전하게 전달된다.

---

## ✅ 레이어별 책임 정리

| 레이어 | 설명 |
|--------|------|
| Screen | 순수 UI 구성. 상태 기반으로만 렌더링. 직접 처리 없음 |
| ScreenRoot | ViewModel 상태 주입 및 context 처리 (UI 반응 책임) |
| ViewModel | 상태 관리 및 액션 핸들링. 모든 유즈케이스 호출은 여기서 시작 |
| UseCase | 도메인 중심 로직을 실행하고, Result → 상태로 변환 |
| Repository Interface | 도메인 기준의 데이터 조회/저장 정의 |
| Repository Impl | 실제 API, DB 호출 포함. 예외 처리 포함 |
| DataSource | 외부 API 통신 또는 Firebase, LocalStorage 호출 |
| Mapper | DTO ↔ 도메인 Model 간 변환 책임 |
| Model | 앱 내 비즈니스 개념을 반영한 순수 데이터 구조 |

---

## 🔁 참고 링크

- [folder.md](folder.md)
- [naming.md](naming.md)
- [result.md](result.md)
- [error.md](error.md)
- [usecase.md](../logic/usecase.md)
- [viewmodel.md](../ui/viewmodel.md)
- [screen.md](../ui/screen.md)