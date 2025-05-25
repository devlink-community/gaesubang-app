# 🧩 Firebase User 도메인 모델

---
TODO: 이 문서는 업데이트가 필요합니다.

## 📁 1. Firestore 컬렉션 구조: `users/{userId}`

| 필드명                     | 타입           | 설명                                 |
|--------------------------|----------------|--------------------------------------|
| `email`                  | `string`       | 로그인용 이메일                       |
| `nickname`               | `string`       | 닉네임 또는 표시 이름                  |
| `uid`                    | `string`       | Firebase Auth UID (문서 ID와 동일)    |
| `image`                  | `string`       | 프로필 이미지 URL                    |
| `agreedTermId`           | `string`       | 동의한 약관 버전 ID                   |
| `description`            | `string`       | 자기소개                             |
| `onAir`                  | `boolean`      | 현재 활동 중 여부                     |
| `position`               | `string`       | 직책/포지션 (예: 프론트엔드 개발자)    |
| `skills`                 | `string`       | 보유 기술 (예: Flutter, React)        |
| `streakDays`             | `number`       | 연속 학습일                          |
| `isServiceTermsAgreed`   | `boolean`      | 서비스 이용약관 동의 여부             |
| `isPrivacyPolicyAgreed`  | `boolean`      | 개인정보 수집 이용 동의 여부          |
| `isMarketingAgreed`      | `boolean`      | 마케팅 수신 동의 여부                 |
| `agreedAt`               | `timestamp`    | 약관 동의 시간                        |
| `joingroup`              | `array`        | 가입된 그룹 목록 (JoinedGroup 객체 배열) |

### ✅ JoinedGroup 객체 구조

| 필드명         | 타입      | 설명                    |
|----------------|-----------|-------------------------|
| `group_name`   | `string`  | 그룹 이름               |
| `group_image`  | `string`  | 그룹 대표 이미지 URL     |

### ✅ 예시 JSON

```json
{
  "email": "test@example.com",
  "nickname": "개발돌이",
  "uid": "firebase-uid-123",
  "image": "https://cdn.example.com/profile.jpg",
  "agreedTermId": "v2.3",
  "description": "Flutter 개발자입니다",
  "onAir": false,
  "position": "프론트엔드 개발자",
  "skills": "Flutter, Dart, Firebase",
  "streakDays": 7,
  "isServiceTermsAgreed": true,
  "isPrivacyPolicyAgreed": true,
  "isMarketingAgreed": false,
  "agreedAt": "2025-05-13T10:00:00Z",
  "joingroup": [
    {
      "group_name": "개발자모임",
      "group_image": "https://cdn.example.com/group1.jpg"
    },
    {
      "group_name": "타이머스터디",
      "group_image": "https://cdn.example.com/group2.jpg"
    }
  ]
}
```

### ✅ 예시 쿼리

```js
// 닉네임으로 검색
db.collection("users").where("nickname", "==", "개발돌이").get();

// 마케팅 동의 유저 목록
db.collection("users").where("isMarketingAgreed", "==", true).get();
```

---

## 📁 2. 하위 컬렉션: `users/{userId}/timerActivities/{activityId}`

사용자의 타이머 활동 기록을 저장하는 하위 컬렉션입니다.

| 필드명       | 타입                     | 설명                                   |
|--------------|--------------------------|----------------------------------------|
| `memberId`   | `string`                 | 활동을 수행한 사용자 ID                |
| `type`       | `string`                 | `"start"`, `"pause"`, `"resume"`, `"end"` 중 하나 |
| `timestamp`  | `timestamp`              | 활동 발생 시간                         |
| `metadata`   | `object`                 | 부가 데이터 (기기, 태스크명 등)         |

### ✅ 예시 JSON

```json
{
  "memberId": "user123",
  "type": "start",
  "timestamp": "2025-05-13T10:00:00Z",
  "metadata": {
    "from": "mobile",
    "task": "공부 타이머"
  }
}
```

### ✅ 예시 쿼리

```js
// 특정 유저의 모든 활동 로그
db.collection("users")
  .doc("user123")
  .collection("timerActivities")
  .orderBy("timestamp", "desc")
  .get();

// 특정 날짜 이후 활동
db.collection("users")
  .doc("user123")
  .collection("timerActivities")
  .where("timestamp", ">=", new Date("2025-05-13T00:00:00Z"))
  .get();
```

---

## 📁 3. 하위 컬렉션: `users/{userId}/bookmarks/{postId}`

사용자가 북마크한 게시글을 저장하는 하위 컬렉션입니다.

| 필드명       | 타입        | 설명                |
|--------------|-------------|---------------------|
| `postId`     | `string`    | 북마크한 게시글 ID   |
| `timestamp`  | `timestamp` | 북마크 추가 시간     |

### ✅ 예시 JSON

```json
{
  "postId": "post123",
  "timestamp": "2025-05-13T15:30:00Z"
}
```

### ✅ 예시 쿼리

```js
// 사용자의 모든 북마크 조회
db.collection("users")
  .doc("user123")
  .collection("bookmarks")
  .orderBy("timestamp", "desc")
  .get();
```

---

## 📦 DTO 구조 정리

### 1. UserDto

| 필드명                   | 타입                   | nullable | @JsonKey | 설명                                  |
|------------------------|------------------------|----------|----------|---------------------------------------|
| `email`                | `String`              | ✅        | -        | 사용자 이메일                         |
| `nickname`             | `String`              | ✅        | -        | 사용자 닉네임                         |
| `uid`                  | `String`              | ✅        | -        | Firebase UID (문서 ID와 동일)          |
| `image`                | `String`              | ✅        | -        | 프로필 이미지 URL                     |
| `agreedTermId`         | `String`              | ✅        | -        | 약관 버전 ID                          |
| `description`          | `String`              | ✅        | -        | 자기소개                              |
| `onAir`                | `bool`                | ✅        | -        | 현재 활동 중 여부                      |
| `position`             | `String`              | ✅        | -        | 직책/포지션                            |
| `skills`               | `String`              | ✅        | -        | 보유 기술                              |
| `streakDays`           | `int`                 | ✅        | -        | 연속 학습일                            |
| `isServiceTermsAgreed` | `bool`                | ✅        | -        | 서비스 이용약관 동의 여부              |
| `isPrivacyPolicyAgreed`| `bool`                | ✅        | -        | 개인정보처리방침 동의 여부             |
| `isMarketingAgreed`    | `bool`                | ✅        | -        | 마케팅 동의 여부                       |
| `agreedAt`             | `DateTime`            | ✅        | 특수처리   | 동의한 시점                            |
| `joinedGroups`         | `List<JoinedGroupDto>`| ✅        | `joingroup` | 가입한 그룹 목록                       |

### 2. JoinedGroupDto

| 필드명         | 타입      | nullable | @JsonKey | 설명                    |
|----------------|-----------|----------|----------|-------------------------|
| `groupName`    | `String`  | ✅        | `group_name` | 그룹 이름               |
| `groupImage`   | `String`  | ✅        | `group_image` | 그룹 대표 이미지 URL     |

### 3. TimerActivityDto

| 필드명     | 타입                     | nullable | @JsonKey | 설명                                            |
|------------|--------------------------|----------|----------|-------------------------------------------------|
| `id`       | `String`                | ✅        | -        | 활동 ID (문서 ID와 동일)                        |
| `memberId` | `String`                | ✅        | -        | 활동을 수행한 사용자 ID                         |
| `type`     | `String`                | ✅        | -        | `"start"`, `"pause"`, `"resume"`, `"end"` 중 하나 |
| `timestamp`| `DateTime`              | ✅        | 특수처리   | 활동 발생 시간                                   |
| `metadata` | `Map<String, dynamic>`  | ✅        | -        | 부가 정보 (기기, 태스크명 등)                     |

---

## 📝 구현 최적화

### 1. 사용자 정보와 타이머 활동을 병렬로 조회

사용자 정보와 타이머 활동을 한 번에 조회하기 위해 병렬 처리를 사용합니다:

```dart
Future<Map<String, dynamic>?> fetchCurrentUserWithTimerActivities() async {
  final user = _auth.currentUser;
  if (user == null) return null;

  // Firebase 병렬 처리
  final results = await Future.wait([
    // 1. 사용자 문서 조회
    _usersCollection.doc(user.uid).get(),

    // 2. 타이머 활동 조회 (최근 30일)
    _usersCollection
        .doc(user.uid)
        .collection('timerActivities')
        .where('timestamp', isGreaterThan: thirtyDaysAgo)
        .orderBy('timestamp', descending: true)
        .get(),
  ]);

  // 결과 조합
  final userData = results[0].data()!;
  final activities = results[1].docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  
  return {
    ...userData,
    'timerActivities': activities,
  };
}
```

### 2. 통계 계산 최적화

타이머 활동 데이터를 기반으로 한 통계 계산은 별도의 유틸리티 클래스를 활용합니다:

```dart
final focusStats = FocusStatsCalculator.calculateFromActivities(activities);
```

### 3. 인증 상태 캐싱

인증 상태 변화 감지 및 데이터 캐싱을 통해 불필요한 API 호출을 방지합니다:

```dart
// 캐시된 사용자와 동일한 경우 API 호출 생략
if (_lastFirebaseUserId == firebaseUser.uid && _cachedMember != null) {
  return AuthState.authenticated(_cachedMember!);
}
```

---

## 📚 관련 문서

- [main_firebase_model](firebase_model.md) - Firebase 모델 공통 가이드
- [firebase_group_model](firebase_group_model.md) - Group 도메인 모델
- [firebase_post_model](firebase_post_model.md) - Post 도메인 모델