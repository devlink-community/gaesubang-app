---

# 🧩 User

---

## 📁 1. Firestore 컬렉션 구조: `users/{userId}`

| 필드명                     | 타입           | 설명                                 |
|--------------------------|----------------|--------------------------------------|
| `email`                  | `string`       | 로그인용 이메일                       |
| `nickname`               | `string`       | 닉네임 또는 표시 이름                  |
| `uid`                    | `string`       | Firebase Auth UID                   |
| `image`                  | `string`       | 프로필 이미지 URL                    |
| `agreedTermId`           | `string`       | 동의한 약관 버전 ID                   |
| `description`            | `string`       | 자기소개                             |
| `isServiceTermsAgreed`   | `bool`         | 서비스 이용약관 동의 여부             |
| `isPrivacyPolicyAgreed`  | `bool`         | 개인정보 수집 이용 동의 여부          |
| `isMarketingAgreed`      | `bool`         | 마케팅 수신 동의 여부                 |
| `agreedAt`               | `timestamp`    | 약관 동의 시간                        |
| `joingroup`              | `List<Map>`    | 가입된 그룹 목록 (이름 + 이미지)      |

### ✅ 예시 JSON

```json
{
  "email": "test@example.com",
  "nickname": "개발돌이",
  "uid": "firebase-uid-123",
  "image": "https://cdn.example.com/profile.jpg",
  "agreedTermId": "v2.3",
  "description": "Flutter 개발자입니다",
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

| 필드명       | 타입                     | 설명                                   |
|--------------|--------------------------|----------------------------------------|
| `userId`   | `string`                 | 활동을 수행한 사용자 ID         |
| `type`       | `string`                 | `"start"`, `"pause"`, `"resume"`, `"end"` 중 하나 |
| `timestamp`  | `timestamp`              | 활동 발생 시간 (ISO 8601)              |
| `metadata`   | `Map<String, dynamic>`   | 부가 데이터 (기기, 설명 등)             |

### ✅ 예시 JSON

```json
{
  "userId": "user123",
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

## 📦 DTO 구조 정리

### 1. UserDto

| 필드명                   | 타입                   | nullable | 설명                                  |
|------------------------|------------------------|----------|---------------------------------------|
| `email`                | `String`              | ✅        | 사용자 이메일                         |
| `nickname`             | `String`              | ✅        | 사용자 닉네임                         |
| `uid`                  | `String`              | ✅        | Firebase UID                          |
| `image`                | `String`              | ✅        | 프로필 이미지 URL                     |
| `agreedTermId`         | `String`              | ✅        | 약관 버전 ID                          |
| `description`          | `String`              | ✅        | 자기소개                              |
| `isServiceTermsAgreed` | `bool`                | ✅        | 서비스 이용약관 동의 여부              |
| `isPrivacyPolicyAgreed`| `bool`                | ✅        | 개인정보처리방침 동의 여부             |
| `isMarketingAgreed`    | `bool`                | ✅        | 마케팅 동의 여부                       |
| `agreedAt`             | `DateTime`            | ✅        | 동의한 시점                            |
| `joingroup`            | `List<JoinedGroupDto>`| ✅        | 가입한 그룹 목록                       |

---

### 2. JoinedGroupDto

| 필드명         | 타입      | nullable | 설명                    |
|----------------|-----------|----------|-------------------------|
| `groupName`    | `String` | ✅        | 그룹 이름               |
| `groupImage`   | `String` | ✅        | 그룹 대표 이미지 URL     |

---

### 3. TimerActivityDto

| 필드명     | 타입                     | nullable | 설명                                            |
|------------|--------------------------|----------|-------------------------------------------------|
| `memberId` | `String`                | ✅        | 활동을 수행한 사용자 or 멤버 ID                |
| `type`     | `String`                | ✅        | `"start"`, `"pause"`, `"resume"`, `"end"` 중 하나 |
| `timestamp`| `DateTime`              | ✅        | 활동 발생 시간                                   |
| `metadata` | `Map<String, dynamic>`  | ✅        | 부가 정보 (기기, 설명 등)                         |

---

---

# 🧩 Group

---

## 📁 1. 컬렉션: `groups/{groupId}`

| 필드명            | 타입            | 설명                                  |
|------------------|-----------------|---------------------------------------|
| `name`           | `string`        | 그룹 이름                              |
| `description`    | `string`        | 그룹 설명                              |
| `imageUrl`       | `string`        | 그룹 대표 이미지 URL                   |
| `createdAt`      | `timestamp`     | 그룹 생성 시간                          |
| `createdBy`      | `string`        | 생성자 ID                              |
| `maxMemberCount` | `int`           | 최대 멤버 수                            |
| `hashTags`       | `List<string>`  | 해시태그 리스트 (예: ["#스터디", "#공부"]) |

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

---

## 📁 2. 하위 컬렉션: `groups/{groupId}/members/{userId}`

| 필드명       | 타입      | 설명                                       |
|--------------|-----------|--------------------------------------------|
| `userId`     | `string`  | 사용자 ID                                  |
| `userName`   | `string`  | 사용자 닉네임 또는 이름                        |
| `profileUrl` | `string`  | 프로필 이미지 URL                           |
| `role`       | `string`  | 역할 (admin, moderator, member) 중 하나         |
| `joinedAt`   | `timestamp` | 그룹 가입 시간                              |

### ✅ 예시 JSON

```json
{
  "userId": "user_123",
  "userName": "홍길동",
  "profileUrl": "https://cdn.example.com/profile.jpg",
  "role": "member",
  "joinedAt": "2025-05-12T15:00:00Z",
}
```

---

## 📁 3. 하위 컬렉션: `groups/{groupId}/timerActivities/{activityId}`

| 필드명      | 타입                   | 설명                                             |
|-------------|------------------------|--------------------------------------------------|
| `memberId`  | `string`               | 타이머를 수행한 멤버 ID                             |
| `type`      | `string`               | `"start"`, `"pause"`, `"resume"`, `"end"` 중 하나 |
| `timestamp` | `timestamp`            | 발생 시각 (ISO 8601)                               |
| `metadata`  | `Map<String, dynamic>` | 선택적 메타 정보 (예: 태그, 디바이스 정보 등)        |

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

---

## 📦 DTO 구조 정리

### 1. GroupDto

| 필드명            | 타입            | nullable | 설명                           |
|------------------|-----------------|----------|--------------------------------|
| `name`           | `String`        | ✅        | 그룹 이름                        |
| `description`    | `String`        | ✅        | 그룹 설명                        |
| `imageUrl`       | `String`        | ✅        | 이미지 URL                       |
| `createdAt`      | `DateTime`      | ✅        | 생성 시각                        |
| `createdBy`      | `String`        | ✅        | 생성자 ID                        |
| `maxMemberCount` | `int`           | ✅        | 최대 멤버 수                     |
| `hashTags`       | `List<String>`  | ✅        | 해시태그 목록                     |

---

### 2. GroupMemberDto

| 필드명       | 타입      | nullable | 설명                         |
|--------------|-----------|----------|------------------------------|
| `userId`     | `String` | ✅        | 사용자 ID                     |
| `userName`   | `String` | ✅        | 닉네임                         |
| `profileUrl` | `String` | ✅        | 프로필 이미지 URL              |
| `role`       | `String` | ✅        | 역할: admin/moderator/member |
| `joinedAt`   | `DateTime` | ✅        | 가입 시각                      |
| `isActive`   | `bool`   | ✅        | 현재 활동 여부                 |

---

### 3. GroupTimerActivityDto

| 필드명      | 타입                     | nullable | 설명                                      |
|-------------|--------------------------|----------|-------------------------------------------|
| `memberId`  | `String`                | ✅        | 활동한 멤버 ID                             |
| `type`      | `String`                | ✅        | 활동 타입                                  |
| `timestamp` | `DateTime`              | ✅        | 활동 발생 시각                              |
| `metadata`  | `Map<String, dynamic>`  | ✅        | 선택적 메타데이터 (이유, 디바이스 등)         |

---

---

# 🧩 POST

---

## 📁 1. 컬렉션: `posts/{postId}`

| 필드명             | 타입             | 설명                                  |
|-------------------|------------------|---------------------------------------|
| `id`              | `string`         | 게시글 ID                              |
| `authorId`        | `string`         | 작성자 UID                             |
| `userProfileImage`| `string`         | 작성자 프로필 이미지 URL               |
| `title`           | `string`         | 게시글 제목                             |
| `content`         | `string`         | 게시글 본문 내용                         |
| `mediaUrls`       | `List<string>`   | 첨부 이미지, 비디오 등의 URL 목록         |
| `createdAt`       | `timestamp`      | 게시글 작성 시간                         |
| `hashTags`        | `List<string>`   | 해시태그 목록 (예: ["#스터디", "#공부"]) |

### ✅ 예시 JSON

```json
{
  "id": "post_001",
  "authorId": "user_abc",
  "userProfileImage": "https://cdn.example.com/profile.jpg",
  "title": "함께 공부해요",
  "content": "오늘도 열심히 타이머 돌려봅시다.",
  "mediaUrls": ["https://cdn.example.com/img1.png"],
  "createdAt": "2025-05-13T12:00:00Z",
  "hashTags": ["#스터디", "#정처기"]
}
```

---

## 📁 2. 하위 컬렉션: `posts/{postId}/likes/{userId}`

| 필드명       | 타입       | 설명                            |
|--------------|------------|---------------------------------|
| `userId`     | `string`   | 좋아요를 누른 사용자 ID           |
| `userName`   | `string`   | 사용자 이름                       |
| `timestamp`  | `timestamp`| 좋아요를 누른 시간                 |

---

## 📁 3. 하위 컬렉션: `posts/{postId}/comments/{commentId}`

| 필드명            | 타입       | 설명                                |
|-------------------|------------|-------------------------------------|
| `userId`          | `string`   | 댓글 작성자 ID                       |
| `userName`        | `string`   | 댓글 작성자 이름                     |
| `userProfileImage`| `string`   | 댓글 작성자 프로필 이미지 URL         |
| `text`            | `string`   | 댓글 내용                            |
| `createdAt`       | `timestamp`| 댓글 작성 시간                        |
| `likeCount`       | `int`      | 해당 댓글의 좋아요 수                  |

---

## 📦 DTO 구조 정리

### 1. PostDto

| 필드명             | 타입             | nullable | 설명                                  |
|-------------------|------------------|----------|---------------------------------------|
| `id`              | `String`        | ✅        | 게시글 ID                             |
| `authorId`        | `String`        | ✅        | 작성자 ID                              |
| `userProfileImage`| `String`        | ✅        | 프로필 이미지 URL                     |
| `title`           | `String`        | ✅        | 제목                                  |
| `content`         | `String`        | ✅        | 내용                                  |
| `mediaUrls`       | `List<String>`  | ✅        | 첨부 이미지/비디오 URL 목록           |
| `createdAt`       | `DateTime`      | ✅        | 작성 시각                              |
| `hashTags`        | `List<String>`  | ✅        | 해시태그 목록                          |

---

### 2. PostLikeDto

| 필드명      | 타입       | nullable | 설명                         |
|-------------|------------|----------|------------------------------|
| `userId`    | `String`  | ✅        | 좋아요 누른 사용자 ID         |
| `userName`  | `String`  | ✅        | 사용자 이름                   |
| `timestamp` | `DateTime`| ✅        | 좋아요 시간                   |

---

### 3. PostCommentDto

| 필드명            | 타입       | nullable | 설명                             |
|-------------------|------------|----------|----------------------------------|
| `userId`          | `String`  | ✅        | 댓글 작성자 ID                    |
| `userName`        | `String`  | ✅        | 댓글 작성자 이름                  |
| `userProfileImage`| `String`  | ✅        | 댓글 작성자 프로필 이미지 URL      |
| `text`            | `String`  | ✅        | 댓글 본문 내용                     |
| `createdAt`       | `DateTime`| ✅        | 댓글 작성 시각                     |
| `likeCount`       | `int`     | ✅        | 좋아요 수                          |

---