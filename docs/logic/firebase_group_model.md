# 🧩 Group

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

### 1. 그룹 타이머 실시간 상태 관리

그룹 타이머 화면에서 멤버들의 활동 상태를 효율적으로 표시하기 위한 최적화:

```dart
// 멤버별 마지막 활동 상태를 직접 쿼리
final List<Future<QuerySnapshot>> memberLastActivities = [];

// 각 멤버별로 가장 최근 활동만 쿼리 (병렬 처리)
for (final memberId in memberIds) {
final query = _groupsCollection
    .doc(groupId)
    .collection('timerActivities')
    .where('memberId', isEqualTo: memberId)
    .orderBy('timestamp', descending: true)
    .limit(1)  // 각 멤버당 가장 최근 활동만 필요
    .get();

memberLastActivities.add(query);
}

// 모든 쿼리 실행 결과 수집
final results = await Future.wait(memberLastActivities);

// 활성 멤버 및 비활성 멤버 분류
final Map<String, int> activeMembers = {};
final List<String> inactiveMembers = [];
final now = DateTime.now();

for (final snapshot in results) {
if (snapshot.docs.isNotEmpty) {
final doc = snapshot.docs.first;
final activity = GroupTimerActivityDto.fromJson(doc.data());
final memberId = activity.memberId;

if (memberId != null) {
// 마지막 활동이 'start'인 경우 활성 멤버
if (activity.type == 'start') {
final startTime = activity.timestamp;
if (startTime != null) {
// 타이머 시작 시간부터 현재까지의 경과 시간 계산
final elapsedSeconds = now.difference(startTime).inSeconds;
activeMembers[memberId] = elapsedSeconds;
}
} else {
// 마지막 활동이 'end'인 경우 비활성 멤버
inactiveMembers.add(memberId);
}
}
}
}
```

### 2. 출석부 달력 최적화

출석부 달력 화면에서 날짜별 타이머 활동 시간을 효율적으로 집계:

```dart
// 월 단위 타이머 활동 일괄 조회
final monthActivities = await _groupsCollection
    .doc(groupId)
    .collection('timerActivities')
    .where('timestamp', isGreaterThanOrEqualTo: firstDayOfMonth)
    .where('timestamp', isLessThanOrEqualTo: lastDayOfMonth)
    .get();

// 멤버별, 날짜별 활동 시간 집계
final Map<String, Map<String, int>> memberDailyMinutes = {};

// 멤버별 start/end 페어 매칭
for (final memberId in memberIds) {
final memberActivities = monthActivities.docs
    .map((doc) => GroupTimerActivityDto.fromJson(doc.data()))
    .where((activity) => activity.memberId == memberId)
    .toList();

// 활동 시간순 정렬
memberActivities.sort((a, b) =>
a.timestamp?.compareTo(b.timestamp ?? DateTime.now()) ?? 0);

// start/end 매칭하여 날짜별 시간 계산
DateTime? startTime;
for (final activity in memberActivities) {
final date = _formatDate(activity.timestamp); // YYYY-MM-DD

if (activity.type == 'start') {
startTime = activity.timestamp;
} else if (activity.type == 'end' && startTime != null) {
final duration = activity.timestamp?.difference(startTime).inMinutes ?? 0;

memberDailyMinutes[memberId] ??= {};
memberDailyMinutes[memberId]![date] ??= 0;
memberDailyMinutes[memberId]![date] =
(memberDailyMinutes[memberId]![date] ?? 0) + duration;

startTime = null; // 페어 처리 완료
}
}
}
```

### 3. 그룹 멤버십 관리 최적화

그룹 가입/탈퇴 시 트랜잭션을 사용하여 원자적 업데이트 처리:

```dart
// 그룹 가입 처리 - 트랜잭션으로 memberCount 일관성 유지
return _firestore.runTransaction((transaction) async {
// 1. 그룹 문서 조회
final groupDoc = await transaction.get(_groupsCollection.doc(groupId));

if (!groupDoc.exists) {
throw Exception('그룹을 찾을 수 없습니다');
}

// 2. 현재 memberCount 확인
final data = groupDoc.data()!;
final currentMemberCount = data['memberCount'] as int? ?? 0;
final maxMemberCount = data['maxMemberCount'] as int? ?? 10;

// 3. 멤버 수 제한 확인
if (currentMemberCount >= maxMemberCount) {
throw Exception('그룹 최대 인원에 도달했습니다');
}

// 4. 멤버 추가 및 카운터 증가
transaction.set(
_groupsCollection.doc(groupId).collection('members').doc(userId),
{
'userId': userId,
'userName': userName,
'profileUrl': profileUrl,
'role': 'member',
'joinedAt': FieldValue.serverTimestamp(),
}
);

transaction.update(
_groupsCollection.doc(groupId),
{'memberCount': currentMemberCount + 1}
);

// 5. 사용자 문서에도 가입 그룹 정보 추가
transaction.update(
_usersCollection.doc(userId),
{
'joingroup': FieldValue.arrayUnion([{
'group_name': data['name'] ?? '',
'group_image': data['imageUrl'] ?? '',
}])
}
);
});
```