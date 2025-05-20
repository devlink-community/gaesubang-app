# 🧩 Firebase Group 도메인 모델

---

## 📁 1. 컬렉션: `groups/{groupId}`

| 필드명            | 타입            | 설명                                  |
|------------------|-----------------|---------------------------------------|
| `name`           | `string`        | 그룹 이름                              |
| `description`    | `string`        | 그룹 설명                              |
| `imageUrl`       | `string`        | 그룹 대표 이미지 URL                   |
| `createdAt`      | `timestamp`     | 그룹 생성 시간                          |
| `createdBy`      | `string`        | 생성자 ID                              |
| `maxMemberCount` | `number`        | 최대 멤버 수                            |
| `hashTags`       | `array`         | 해시태그 리스트 (예: ["#스터디", "#공부"]) |

### ✅ 예시 JSON

```json
{
  "name": "공부 타이머 그룹",
  "description": "같이 집중해서 공부하는 그룹",
  "imageUrl": "https://cdn.example.com/group.jpg",
  "createdAt": "2025-05-13T09:00:00Z",
  "createdBy": "user_abc",
  "maxMemberCount": 10,
  "hashTags": ["#스터디", "#공부"]
}
```

### ✅ 예시 쿼리

```js
// 해시태그로 그룹 검색
db.collection("groups")
  .where("hashTags", "array-contains", "#스터디")
  .get();

// 최신 생성 그룹 조회
db.collection("groups")
  .orderBy("createdAt", "desc")
  .limit(10)
  .get();
```

---

## 📁 2. 하위 컬렉션: `groups/{groupId}/members/{userId}`

| 필드명       | 타입       | 설명                                       |
|--------------|-----------|--------------------------------------------|
| `userId`     | `string`  | 사용자 ID                                  |
| `userName`   | `string`  | 사용자 닉네임 또는 이름                        |
| `profileUrl` | `string`  | 프로필 이미지 URL                           |
| `role`       | `string`  | 역할 (`"admin"`, `"moderator"`, `"member"`) |
| `joinedAt`   | `timestamp` | 그룹 가입 시간                              |
| `isActive`   | `boolean` | 현재 활동 중인지 여부                        |

### ✅ 예시 JSON

```json
{
  "userId": "user_123",
  "userName": "홍길동",
  "profileUrl": "https://cdn.example.com/profile.jpg",
  "role": "member",
  "joinedAt": "2025-05-12T15:00:00Z",
  "isActive": false
}
```

### ✅ 예시 쿼리

```js
// 활성 상태인 멤버 조회
db.collection("groups")
  .doc("group_123")
  .collection("members")
  .where("isActive", "==", true)
  .get();

// 관리자 권한 멤버 조회
db.collection("groups")
  .doc("group_123")
  .collection("members")
  .where("role", "==", "admin")
  .get();
```

---

## 📁 3. 하위 컬렉션: `groups/{groupId}/timerActivities/{activityId}`

| 필드명      | 타입                   | 설명                                             |
|-------------|------------------------|--------------------------------------------------|
| `memberId`  | `string`               | 타이머를 수행한 멤버 ID                             |
| `type`      | `string`               | `"start"`, `"pause"`, `"resume"`, `"end"` 중 하나 |
| `timestamp` | `timestamp`            | 발생 시각                                         |
| `metadata`  | `object`               | 선택적 메타 정보 (예: 태그, 디바이스 정보 등)        |

### ✅ 예시 JSON

```json
{
  "memberId": "user_123",
  "type": "pause",
  "timestamp": "2025-05-13T10:30:00Z",
  "metadata": {
    "reason": "잠시 휴식",
    "device": "iOS"
  }
}
```

### ✅ 예시 쿼리

```js
// 특정 멤버의 타이머 활동 조회
db.collection("groups")
  .doc("group_123")
  .collection("timerActivities")
  .where("memberId", "==", "user_123")
  .orderBy("timestamp", "desc")
  .get();

// 오늘의 타이머 활동 조회
const today = new Date();
today.setHours(0, 0, 0, 0);
db.collection("groups")
  .doc("group_123")
  .collection("timerActivities")
  .where("timestamp", ">=", today)
  .get();
```

---

## 📁 4. 하위 컬렉션: `groups/{groupId}/attendance/{date}`

출석 정보를 저장하는 하위 컬렉션입니다. 날짜별로 문서를 생성합니다.

| 필드명       | 타입      | 설명                               |
|--------------|-----------|-----------------------------------|
| `date`       | `string`  | 날짜 (YYYY-MM-DD 형식)            |
| `members`    | `array`   | 출석한 멤버 목록 (AttendanceMember 객체 배열) |

### ✅ AttendanceMember 객체 구조

| 필드명           | 타입       | 설명                        |
|------------------|------------|----------------------------|
| `userId`         | `string`   | 사용자 ID                  |
| `userName`       | `string`   | 사용자 이름                |
| `attendedAt`     | `timestamp`| 출석 시간                  |
| `focusMinutes`   | `number`   | 집중한 시간 (분 단위)       |

### ✅ 예시 JSON

```json
{
  "date": "2025-05-13",
  "members": [
    {
      "userId": "user_123",
      "userName": "홍길동",
      "attendedAt": "2025-05-13T09:30:00Z",
      "focusMinutes": 120
    },
    {
      "userId": "user_456",
      "userName": "김영희",
      "attendedAt": "2025-05-13T10:15:00Z",
      "focusMinutes": 90
    }
  ]
}
```

### ✅ 예시 쿼리

```js
// 특정 날짜의 출석 정보 조회
db.collection("groups")
  .doc("group_123")
  .collection("attendance")
  .doc("2025-05-13")
  .get();

// 일정 기간의 출석 정보 조회
db.collection("groups")
  .doc("group_123")
  .collection("attendance")
  .where("date", ">=", "2025-05-01")
  .where("date", "<=", "2025-05-31")
  .get();
```

---

## 📦 DTO 구조 정리

### 1. GroupDto

| 필드명            | 타입            | nullable | @JsonKey | 설명                           |
|------------------|-----------------|----------|----------|--------------------------------|
| `id`             | `String`        | ✅        | -        | 그룹 ID (문서 ID와 동일)         |
| `name`           | `String`        | ✅        | -        | 그룹 이름                        |
| `description`    | `String`        | ✅        | -        | 그룹 설명                        |
| `imageUrl`       | `String`        | ✅        | -        | 이미지 URL                       |
| `createdAt`      | `DateTime`      | ✅        | 특수처리   | 생성 시각                        |
| `createdBy`      | `String`        | ✅        | -        | 생성자 ID                        |
| `maxMemberCount` | `int`           | ✅        | -        | 최대 멤버 수                     |
| `hashTags`       | `List<String>`  | ✅        | -        | 해시태그 목록                     |

### 2. GroupMemberDto

| 필드명       | 타입      | nullable | @JsonKey | 설명                         |
|--------------|-----------|----------|----------|------------------------------|
| `id`         | `String`  | ✅        | -        | 멤버 ID (문서 ID와 동일)       |
| `userId`     | `String`  | ✅        | -        | 사용자 ID                     |
| `userName`   | `String`  | ✅        | -        | 닉네임                         |
| `profileUrl` | `String`  | ✅        | -        | 프로필 이미지 URL              |
| `role`       | `String`  | ✅        | -        | 역할: `"admin"`, `"moderator"`, `"member"` |
| `joinedAt`   | `DateTime` | ✅       | 특수처리   | 가입 시각                      |
| `isActive`   | `bool`    | ✅        | -        | 현재 활동 여부                 |

### 3. GroupTimerActivityDto

| 필드명      | 타입                     | nullable | @JsonKey | 설명                                      |
|-------------|--------------------------|----------|----------|-------------------------------------------|
| `id`        | `String`                | ✅        | -        | 활동 ID (문서 ID와 동일)                   |
| `memberId`  | `String`                | ✅        | -        | 활동한 멤버 ID                             |
| `type`      | `String`                | ✅        | -        | 활동 타입                                  |
| `timestamp` | `DateTime`              | ✅        | 특수처리   | 활동 발생 시각                              |
| `metadata`  | `Map<String, dynamic>`  | ✅        | -        | 선택적 메타데이터 (이유, 디바이스 등)         |

### 4. AttendanceDto

| 필드명       | 타입                      | nullable | @JsonKey | 설명                      |
|--------------|--------------------------|----------|----------|---------------------------|
| `date`       | `String`                | ✅        | -        | 날짜 (YYYY-MM-DD 형식)    |
| `members`    | `List<AttendanceMemberDto>` | ✅   | -        | 출석 멤버 목록             |

### 5. AttendanceMemberDto

| 필드명           | 타입       | nullable | @JsonKey | 설명                     |
|------------------|------------|----------|----------|--------------------------|
| `userId`         | `String`   | ✅        | -        | 사용자 ID                |
| `userName`       | `String`   | ✅        | -        | 사용자 이름              |
| `attendedAt`     | `DateTime` | ✅        | 특수처리   | 출석 시간                |
| `focusMinutes`   | `int`      | ✅        | -        | 집중 시간 (분)            |

---

## 📝 구현 최적화

### 1. 실시간 그룹 타이머 동기화

타이머 활동 추가 시 트랜잭션을 활용한 원자적 업데이트:

```dart
return _firestore.runTransaction((transaction) async {
  // 1. 그룹 멤버 문서 조회
  final memberDoc = await transaction.get(
    _groupsCollection.doc(groupId).collection('members').doc(userId)
  );
  
  // 2. 멤버 상태 확인 및 업데이트
  if (memberDoc.exists) {
    // 활동 상태 업데이트
    transaction.update(memberDoc.reference, {'isActive': isStarting});
    
    // 타이머 활동 추가
    final activityRef = _groupsCollection
        .doc(groupId)
        .collection('timerActivities')
        .doc();
        
    transaction.set(activityRef, {
      'memberId': userId,
      'type': isStarting ? 'start' : 'end',
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    });
  }
});
```

### 2. 출석 정보 일괄 업데이트

출석 정보 추가 시 배열 필드 업데이트 최적화:

```dart
// 배열 필드에 새 요소 추가 (arrayUnion 사용)
await _groupsCollection
    .doc(groupId)
    .collection('attendance')
    .doc(dateString)
    .set({
      'date': dateString,
      'members': FieldValue.arrayUnion([{
        'userId': userId,
        'userName': userName,
        'attendedAt': Timestamp.now(),
        'focusMinutes': focusMinutes
      }])
    }, SetOptions(merge: true));
```

### 3. 멤버 관리 최적화

그룹 멤버 추가/제거 시 사용자의 joingroup 필드도 함께 업데이트:

```dart
return _firestore.runTransaction((transaction) async {
  // 1. 사용자 문서와 그룹 문서 조회
  final userDoc = await transaction.get(_usersCollection.doc(userId));
  final groupDoc = await transaction.get(_groupsCollection.doc(groupId));
  
  if (!userDoc.exists || !groupDoc.exists) {
    throw Exception('사용자 또는 그룹을 찾을 수 없습니다');
  }
  
  // 2. 그룹 멤버 추가
  transaction.set(
    _groupsCollection.doc(groupId).collection('members').doc(userId), 
    memberData
  );
  
  // 3. 사용자의 joingroup 필드 업데이트
  final joingroup = List<Map<String, dynamic>>.from(
    userDoc.data()?['joingroup'] ?? []
  );
  
  joingroup.add({
    'group_name': groupDoc.data()?['name'],
    'group_image': groupDoc.data()?['imageUrl'],
  });
  
  transaction.update(_usersCollection.doc(userId), {'joingroup': joingroup});
});
```

---

## 📚 관련 문서

- [main_firebase_model](firebase_model.md) - Firebase 모델 공통 가이드
- [firebase_user_model](firebase_user_model.md) - User 도메인 모델
- [firebase_post_model](firebase_post_model.md) - Post 도메인 모델