# 🧩 Firebase Group 도메인 모델

---

## 📁 1. 컬렉션 구조: `groups/{groupId}`

| 필드명            | 타입            | 설명                                  |
|------------------|-----------------|---------------------------------------|
| `name`           | `string`        | 그룹 이름                              |
| `description`    | `string`        | 그룹 설명                              |
| `imageUrl`       | `string`        | 그룹 대표 이미지 URL                   |
| `createdAt`      | `timestamp`     | 그룹 생성 시간                          |
| `createdBy`      | `string`        | 생성자 ID (방장)                       |
| `maxMemberCount` | `number`        | 최대 멤버 수                            |
| `hashTags`       | `array`         | 해시태그 리스트 (예: ["스터디", "공부"]) |
| `memberCount`    | `number`        | 현재 멤버 수 (비정규화 필드)             |

### ✅ 예시 JSON

```json
{
  "name": "공부 타이머 그룹",
  "description": "같이 집중해서 공부하는 그룹",
  "imageUrl": "https://cdn.example.com/group.jpg",
  "createdAt": "2025-05-13T09:00:00Z",
  "createdBy": "user_abc",
  "maxMemberCount": 10,
  "hashTags": ["스터디", "공부"],
  "memberCount": 5
}
```

---

## 📁 2. 하위 컬렉션: `groups/{groupId}/members/{userId}`

| 필드명       | 타입      | 설명                                       |
|--------------|-----------|--------------------------------------------|
| `userId`     | `string`  | 사용자 ID                                  |
| `userName`   | `string`  | 사용자 닉네임 또는 이름                        |
| `profileUrl` | `string`  | 프로필 이미지 URL                           |
| `role`       | `string`  | 역할 (`"owner"`, `"member"`)              |
| `joinedAt`   | `timestamp` | 그룹 가입 시간                              |

### ✅ 예시 JSON

```json
{
  "userId": "user_123",
  "userName": "홍길동",
  "profileUrl": "https://cdn.example.com/profile.jpg",
  "role": "member",
  "joinedAt": "2025-05-12T15:00:00Z"
}
```

---

## 📁 3. 하위 컬렉션: `groups/{groupId}/timerActivities/{activityId}`

| 필드명      | 타입                   | 설명                                             |
|-------------|------------------------|--------------------------------------------------|
| `memberId`  | `string`               | 타이머를 수행한 멤버 ID                             |
| `memberName`| `string`               | 멤버 이름 (비정규화: 조회 최적화)                    |
| `type`      | `string`               | `"start"`, `"end"` 등 타이머 액션 타입              |
| `timestamp` | `timestamp`            | 발생 시각                                         |
| `groupId`   | `string`               | 그룹 ID (역참조용)                                 |
| `metadata`  | `object`               | 선택적 메타 정보 (예: 태그, 디바이스 정보 등)        |

### ✅ 예시 JSON

```json
{
  "memberId": "user_123",
  "memberName": "홍길동",
  "type": "start",
  "timestamp": "2025-05-13T10:30:00Z",
  "groupId": "group_abc",
  "metadata": {
    "device": "iOS"
  }
}
```

---

## 📦 DTO 구조 정리

### 1. GroupDto (독립 문서 - ID 필요)

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
| `memberCount`    | `int`           | ✅        | -        | 현재 멤버 수 (비정규화)           |
| `isJoinedByCurrentUser` | `bool`  | ✅        | UI 전용   | 현재 사용자 참여 여부 (UI 전용)   |

---

### 2. GroupMemberDto (독립 문서 - ID 필요)

| 필드명       | 타입      | nullable | @JsonKey | 설명                         |
|--------------|-----------|----------|----------|------------------------------|
| `id`         | `String` | ✅        | -        | 멤버 ID (문서 ID와 동일)       |
| `userId`     | `String` | ✅        | -        | 사용자 ID                     |
| `userName`   | `String` | ✅        | -        | 닉네임                         |
| `profileUrl` | `String` | ✅        | -        | 프로필 이미지 URL              |
| `role`       | `String` | ✅        | -        | 역할: `"owner"`, `"member"`  |
| `joinedAt`   | `DateTime` | ✅        | 특수처리   | 가입 시각                      |

---

### 3. GroupTimerActivityDto (독립 문서 - ID 필요)

| 필드명      | 타입                     | nullable | @JsonKey | 설명                                      |
|-------------|--------------------------|----------|----------|-------------------------------------------|
| `id`        | `String`                | ✅        | -        | 활동 ID (문서 ID와 동일)                   |
| `memberId`  | `String`                | ✅        | -        | 활동한 멤버 ID                             |
| `memberName`| `String`                | ✅        | -        | 멤버 이름 (비정규화)                       |
| `type`      | `String`                | ✅        | -        | 활동 타입: "start", "end"                 |
| `timestamp` | `DateTime`              | ✅        | 특수처리   | 활동 발생 시각                              |
| `groupId`   | `String`                | ✅        | -        | 그룹 ID (역참조)                           |
| `metadata`  | `Map<String, dynamic>`  | ✅        | -        | 선택적 메타데이터                           |
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