# 🧩 POST

---

## 📁 1. 컬렉션: `posts/{postId}`

| 필드명             | 타입             | 설명                                    |
|-------------------|------------------|-----------------------------------------|
| `id`              | `string`         | 게시글 ID (문서 ID와 동일)               |
| `authorId`        | `string`         | 작성자 UID                              |
| `authorNickname`  | `string`         | 작성자 닉네임 (비정규화)                 |
| `authorPosition`  | `string`         | 작성자 직책/포지션 (비정규화)             |
| `userProfileImage`| `string`         | 작성자 프로필 이미지 URL                |
| `title`           | `string`         | 게시글 제목                              |
| `content`         | `string`         | 게시글 본문 내용                         |
| `mediaUrls`       | `array`          | 첨부 이미지, 비디오 등의 URL 목록        |
| `createdAt`       | `timestamp`      | 게시글 작성 시간                         |
| `hashTags`        | `array`          | 해시태그 목록 (예: ["#스터디", "#공부"]) |

### ✅ 예시 JSON

```json
{
  "id": "post_001",
  "authorId": "user_abc",
  "authorNickname": "개발자123",
  "authorPosition": "프론트엔드 개발자",
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

### ✅ 예시 JSON

```json
{
  "userId": "user_456",
  "userName": "김개발",
  "timestamp": "2025-05-13T12:30:00Z"
}
```

---

## 📁 3. 하위 컬렉션: `posts/{postId}/comments/{commentId}`

| 필드명            | 타입       | 설명                                |
|-------------------|------------|-------------------------------------|
| `userId`          | `string`   | 댓글 작성자 ID                       |
| `userName`        | `string`   | 댓글 작성자 이름                     |
| `userProfileImage`| `string`   | 댓글 작성자 프로필 이미지 URL         |
| `text`            | `string`   | 댓글 내용                            |
| `createdAt`       | `timestamp`| 댓글 작성 시간                        |
| `likeCount`       | `number`   | 해당 댓글의 좋아요 수                  |

### ✅ 예시 JSON

```json
{
  "userId": "user_789",
  "userName": "박코딩",
  "userProfileImage": "https://cdn.example.com/profile2.jpg",
  "text": "저도 참여하고 싶어요!",
  "createdAt": "2025-05-13T12:45:00Z",
  "likeCount": 2
}
```

---

## 📦 DTO 구조 정리

### 1. PostDto (독립 문서 - ID 필요)

| 필드명             | 타입             | nullable | @JsonKey | 설명                                  |
|-------------------|------------------|----------|----------|---------------------------------------|
| `id`              | `String`        | ✅        | -        | 게시글 ID (문서 ID와 동일)             |
| `authorId`        | `String`        | ✅        | -        | 작성자 ID                              |
| `authorNickname`  | `String`        | ✅        | -        | 작성자 닉네임 (비정규화)               |
| `authorPosition`  | `String`        | ✅        | -        | 작성자 직책/포지션 (비정규화)          |
| `userProfileImage`| `String`        | ✅        | -        | 프로필 이미지 URL                     |
| `title`           | `String`        | ✅        | -        | 제목                                  |
| `content`         | `String`        | ✅        | -        | 내용                                  |
| `mediaUrls`       | `List<String>`  | ✅        | -        | 첨부 이미지/비디오 URL 목록           |
| `createdAt`       | `DateTime`      | ✅        | -        | 작성 시각                              |
| `hashTags`        | `List<String>`  | ✅        | -        | 해시태그 목록                          |

---

### 2. PostLikeDto (독립 문서 - ID 필요)

| 필드명      | 타입       | nullable | @JsonKey | 설명                         |
|-------------|------------|----------|----------|------------------------------|
| `id`        | `String`  | ✅        | -        | 좋아요 ID (문서 ID와 동일)     |
| `userId`    | `String`  | ✅        | -        | 좋아요 누른 사용자 ID         |
| `userName`  | `String`  | ✅        | -        | 사용자 이름                   |
| `timestamp` | `DateTime`| ✅        | -        | 좋아요 시간                   |

---

### 3. PostCommentDto (독립 문서 - ID 필요)

| 필드명            | 타입       | nullable | @JsonKey | 설명                             |
|-------------------|------------|----------|----------|----------------------------------|
| `id`              | `String`  | ✅        | -        | 댓글 ID (문서 ID와 동일)          |
| `userId`          | `String`  | ✅        | -        | 댓글 작성자 ID                    |
| `userName`        | `String`  | ✅        | -        | 댓글 작성자 이름                  |
| `userProfileImage`| `String`  | ✅        | -        | 댓글 작성자 프로필 이미지 URL      |
| `text`            | `String`  | ✅        | -        | 댓글 본문 내용                     |
| `createdAt`       | `DateTime`| ✅        | -        | 댓글 작성 시각                     |
| `likeCount`       | `int`     | ✅        | -        | 좋아요 수                          |