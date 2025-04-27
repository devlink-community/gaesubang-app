# 🧱 레이어별 책임 및 흐름 가이드

---

# ✅ 아키텍처 구조 배경

이 프로젝트는 기본적으로 **MVVM + MVI + Root 아키텍처**를 기반으로 화면 구조를 설계합니다.

- **MVVM**을 통해 ViewModel(Notifier) 중심으로 상태 관리를 수행하고,
- **MVI** 패턴을 통해 사용자 액션을 상태 변이와 명확하게 연결하며,
- **Root 구조**를 통해 상태 주입과 UI 분리를 엄격히 구분합니다.

하지만 이 구조만으로는 화면/상태 흐름은 명확해지지만,  
**비즈니스 로직 처리(UseCase, Repository, DataSource)와 데이터 흐름에 대한 책임 구분은 명확히 설명되지 않습니다.**

따라서 이 문서에서는  
**UI 아키텍처 흐름을 보완하는 레이어 구분**을 추가하여,
- 각 계층의 책임을 명확히 하고,
- 데이터 흐름을 일관성 있게 유지하며,
- 비즈니스 로직이 올바른 위치에서 처리되도록 강제하는  
  기준을 제공합니다.

---

# 🏛️ 레이어 구조

### 1. Presentation Layer

- **UI 계층**입니다.
- 상태(state)를 구독하고, 사용자 액션(onAction)을 트리거합니다.
- Root(ConsumerWidget)에서 상태를 주입받고, Screen(StatelessWidget)은 순수 UI만 담당합니다.
- 직접 비즈니스 로직을 실행하거나 외부 데이터 통신을 호출하지 않습니다.

---

### 2. Domain Layer

- **비즈니스 로직 계층**입니다.
- UseCase를 통해 비즈니스 규칙을 실행합니다.
- Repository 인터페이스를 정의하고, 이 인터페이스만 의존합니다.
- 외부 통신은 직접 호출하지 않고, Repository를 통해 간접적으로 수행합니다.

---

### 3. Data Layer

- **외부 데이터 통신 및 가공 계층**입니다.
- DataSource를 통해 외부 통신을 수행합니다.
- RepositoryImpl을 통해 Domain Layer의 Repository 인터페이스를 구현합니다.
- DTO와 Mapper를 통해 외부 데이터 ↔ 도메인 모델 변환을 수행합니다.

---

# 🔥 데이터 흐름

```
Presentation → Domain → Data → 외부 통신
```

- 흐름은 항상 단방향입니다.
- 상위 레이어가 하위 레이어에만 의존합니다.
- 하위 레이어는 상위 레이어를 참조하지 않습니다.

---

# 🧠 상태 및 결과 관리 규칙

- DataSource는 네트워크 호출 결과를 반환합니다.
- RepositoryImpl은 DataSource를 호출하고 결과를 변환합니다.
- RepositoryImpl은 결과를 **Result<T>** 형태로 감싸서 반환합니다.
- UseCase는 Repository로부터 받은 Result<T>를 AsyncValue<T>로 변환하여 반환합니다. 
- Notifier는 UseCase로부터 받은 AsyncValue<T>를 상태에 세팅하여 관리합니다.

✅ **Result<T> → AsyncValue<T> 변환은 반드시 UseCase가 담당합니다.**

> 이 책임 분리를 통해 통신/실패 로직과 UI 상태 관리 로직을 명확히 구분할 수 있습니다.

---

# 🗂️ 폴더 구조 설계 (보완 설명)

| 폴더 | 역할 |
|:---|:---|
| data/data_source | 외부 통신 전용 (Firebase, REST API 등) |
| data/dto | 서버와 통신하는 순수 데이터 객체 (Data Transfer Object) |
| data/mapper | DTO ↔ Domain Model 변환 책임 |
| data/repository_impl | Repository 인터페이스의 구현체 |
| domain/model | 도메인 순수 엔티티 (비즈니스 단위 객체) |
| domain/repository | Repository 인터페이스 (UseCase가 의존) |
| domain/usecase | 비즈니스 로직 실행 책임 |
| presentation/ | 상태 구독 및 액션 트리거 (Root, Screen, Notifier) |

✅ Repository 인터페이스는 domain에,  
✅ Repository 구현체는 data에 둡니다.  
✅ UseCase는 항상 Repository 인터페이스만 의존합니다.

---

# 🛠️ 레이어별 책임 요약

| 레이어 | 주요 책임 | 주의사항 |
|:---|:---|:---|
| Presentation (Root/Screen) | 상태 구독, 액션 전달 | 직접 비즈니스 로직이나 외부 통신 호출 금지 |
| Notifier | 상태 관리, 액션 분기 | UseCase 호출 외에는 비즈니스 로직 직접 처리 금지 |
| UseCase | 비즈니스 규칙 실행 | 직접 외부 통신(DataSource) 호출 금지 |
| Repository (Interface) | 외부 데이터 접근 추상화 | 직접 DataSource 호출 안 함 |
| RepositoryImpl (Implementation) | 외부 데이터 가공 및 제공 | Result<T>로 감싸서 반환 |
| DataSource | 외부 통신 수행 | 외부 데이터 접근만 담당 |

---

# 🧩 예시 흐름 (구체적)

1. 사용자가 버튼 클릭 → Screen에서 onAction 호출
2. Root를 통해 Notifier의 onAction 메서드 실행
3. Notifier가 해당 Action에 맞는 UseCase 호출
4. UseCase가 Repository(Interface)를 호출
5. RepositoryImpl이 DataSource를 통해 외부 통신
6. 통신 결과(Result<T>)가 RepositoryImpl → UseCase → Notifier로 전달
7. Notifier가 Result<T>를 AsyncValue<T>로 변환하여 상태 업데이트
8. 상태 변경을 감지한 Screen이 UI를 재렌더링

---

# ✅ 문서 요약

- 레이어는 Presentation → Domain → Data 순으로 구성합니다.
- 항상 단방향 흐름을 유지합니다.
- 비즈니스 로직은 UseCase에만 존재합니다.
- 외부 통신 결과는 RepositoryImpl에서 Result<T>로 감싸서 반환합니다.
- 상태 변환(AsyncValue<T>)은 Notifier가 담당합니다.
- 폴더 구조는 책임에 따라 세분화하여 관리합니다.