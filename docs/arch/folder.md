# 📁 폴더 구조 설계 가이드

---

## ✅ 목적

이 프로젝트는 기능 단위(Feature-first) 기반으로 폴더를 구성하며,  
각 기능 폴더는 일관된 구조(presentation, domain, data, module)를 따릅니다.  
이를 통해 유지보수성과 가독성, 확장성, 팀 단위 협업의 효율을 높입니다.

---

## ✅ 설계 원칙

- 모든 화면/기능은 `lib/{기능}/` 하위에 구성하며, 도메인 기준으로 개별 폴더를 생성합니다.
- 각 기능 폴더는 아래 4개의 하위 폴더 또는 파일군을 포함합니다:
    - `presentation/` : 화면 및 상태
    - `domain/` : 모델, repository interface, usecase
    - `data/` : repository 구현체 및 데이터 소스
    - `module/` : DI, 라우팅 등 기능 초기화 등록

- 공통 요소는 `lib/shared/`에 위치시킵니다.  
  단, 공용화가 확정된 요소만 이동하며, 성급한 추출은 금지합니다.
- Repository 구현체는 반드시 `data/repository_impl/` 폴더에 위치합니다.
- `presentation/` 폴더 내 구성은 다음 항목을 원칙으로 합니다:
    - `screen/`, `screen_root/`, `state/`, `action/`, `view_model/`
- 레이어 간 의존성은 항상 하향식만 허용됩니다 (UI → UseCase → Repo Interface)

---

## ✅ 폴더 구조 예시

```
lib/
├── shared/                          # 공통 유틸, 위젯, 스타일 등
├── auth/
│   ├── data/
│   │   ├── data_source/            # API, Firebase 등 외부 연결
│   │   ├── repository_impl/        # Repository 구현체
│   │   ├── mapper/                 # DTO ↔ Model 변환
│   │   └── dto/
│   ├── domain/
│   │   ├── model/
│   │   ├── repository/             # 추상 Repository interface
│   │   └── usecase/
│   ├── presentation/
│   │   ├── auth_action.dart
│   │   ├── auth_state.dart
│   │   ├── auth_view_model.dart
│   │   ├── login_screen_root.dart
│   │   └── login_screen.dart
│   └── module/
│       ├── auth_route.dart
│       └── auth_di.dart
```

---

## ✅ 폴더별 책임 요약

| 폴더                  | 설명                                           |
|-----------------------|------------------------------------------------|
| `data_source/`        | 외부 API, Firebase, SharedPreferences 등 연결 |
| `repository_impl/`    | 추상 repository의 실제 구현                   |
| `mapper/`             | DTO ↔ Model 변환 확장                         |
| `model/`              | 앱 내부에서 사용하는 도메인 모델 정의         |
| `repository/`         | UseCase에서 참조하는 추상 repository interface |
| `usecase/`            | 하나의 도메인 기능을 수행하는 유즈케이스      |
| `presentation/`       | 상태, UI, 액션 처리 및 전달 담당               |
| `module/`             | 기능 단위 DI 및 라우팅 구성                    |

---

## ✅ 기능 템플릿 확산 전략

- 기능 추가 시 기존 기능 구조(auth 등)를 복제하여 시작합니다.
- 구조만 복제하지 않고 클래스명, 경로, DI/Route 모두 해당 기능에 맞게 수정해야 합니다.
- shell 또는 Dart CLI 기반 템플릿 자동 생성 스크립트를 사용하면 빠르게 구조 확산이 가능합니다.

---

## 🔁 참고 링크

- [layer.md](layer.md)
- [naming.md](naming.md)