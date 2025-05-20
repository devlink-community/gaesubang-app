# 🧩 Firebase Post 도메인 모델

---

## 📁 1. 컬렉션 구조: `posts/{postId}`

| 필드명             | 타입             | 설명                                    |
|-------------------|------------------|-----------------------------------------|
| `id`              | `string`         | 게시글 ID (문서 ID와 동일)               |
| `authorId`        | `string`         | 작성자 UID                              |
| `authorNickname`  | `string`         | 작성자 닉네임 (비정규화)                 |
| `authorPosition`  | `string`         | 작성자 직책/포지션 (비정규화)            |
| `userProfileImage`| `string`         | 작성자 프로필 이미지 URL                |
| `title`           | `string`         | 게시글 제목                              |
| `content`         | `string`         | 게시글 본문 내용                         |
| `mediaUrls`       | `array`          | 첨부 이미지, 비디오 등의 URL 목록        |
| `createdAt`       | `timestamp`      | 게시글 작성 시간                         |
| `hashTags`        | `array`          | 해시태그 목록 (예: ["스터디", "정처기"]) |
| `likeCount`       | `number`         | 좋아요 수 (비정규화)                     |
| `commentCount`    | `number`         | 댓글 수 (비정규화)                       |

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
  "hashTags": ["스터디", "정처기"],
  "likeCount": 5,
  "commentCount": 3
}
```

### ✅ 예시 쿼리

```js
// 최신 게시글 조회
db.collection("posts")
  .orderBy("createdAt", "desc")
  .limit(20)
  .get();

// 해시태그로 게시글 검색
db.collection("posts")
  .where("hashTags", "array-contains", "스터디")
  .orderBy("createdAt", "desc")
  .get();

// 특정 작성자의 게시글 조회
db.collection("posts")
  .where("authorId", "==", "user_abc")
  .orderBy("createdAt", "desc")
  .get();
```

---

## 📁 2. 하위 컬렉션: `posts/{postId}/likes/{userId}`

| 필드명       | 타입       | 설명                            |
|--------------|------------|---------------------------------|
| `userId`     | `string`   | 좋아요를 누른 사용자 ID         |
| `userName`   | `string`   | 사용자 이름                     |
| `timestamp`  | `timestamp`| 좋아요를 누른 시간              |

### ✅ 예시 JSON

```json
{
  "userId": "user_456",
  "userName": "김개발",
  "timestamp": "2025-05-13T12:30:00Z"
}
```

### ✅ 예시 쿼리

```js
// 특정 게시글의 좋아요 목록 조회
db.collection("posts")
  .doc("post_001")
  .collection("likes")
  .orderBy("timestamp", "desc")
  .get();

// 특정 사용자가 좋아요를 눌렀는지 확인
db.collection("posts")
  .doc("post_001")
  .collection("likes")
  .doc("user_456")
  .get();
```

---

## 📁 3. 하위 컬렉션: `posts/{postId}/comments/{commentId}`

| 필드명            | 타입       | 설명                                |
|-------------------|------------|-------------------------------------|
| `id`              | `string`   | 댓글 ID (문서 ID와 동일)            |
| `userId`          | `string`   | 댓글 작성자 ID                      |
| `userName`        | `string`   | 댓글 작성자 이름                    |
| `userProfileImage`| `string`   | 댓글 작성자 프로필 이미지 URL       |
| `text`            | `string`   | 댓글 내용                           |
| `createdAt`       | `timestamp`| 댓글 작성 시간                      |
| `likeCount`       | `number`   | 해당 댓글의 좋아요 수 (비정규화)    |

### ✅ 예시 JSON

```json
{
  "id": "comment_123",
  "userId": "user_789",
  "userName": "박코딩",
  "userProfileImage": "https://cdn.example.com/profile2.jpg",
  "text": "저도 참여하고 싶어요!",
  "createdAt": "2025-05-13T12:45:00Z",
  "likeCount": 2
}
```

### ✅ 예시 쿼리

```js
// 게시글의 댓글 목록 조회 (최신순)
db.collection("posts")
  .doc("post_001")
  .collection("comments")
  .orderBy("createdAt", "desc")
  .get();

// 특정 사용자의 댓글 조회
db.collection("posts")
  .doc("post_001")
  .collection("comments")
  .where("userId", "==", "user_789")
  .get();
```

---

## 📁 4. 하위 컬렉션: `posts/{postId}/comments/{commentId}/likes/{userId}`

댓글에 대한 좋아요 정보를 저장하는 하위 컬렉션입니다.

| 필드명       | 타입       | 설명                            |
|--------------|------------|---------------------------------|
| `userId`     | `string`   | 좋아요를 누른 사용자 ID         |
| `userName`   | `string`   | 사용자 이름                     |
| `timestamp`  | `timestamp`| 좋아요를 누른 시간              |

### ✅ 예시 JSON

```json
{
  "userId": "user_123",
  "userName": "홍길동",
  "timestamp": "2025-05-13T13:00:00Z"
}
```

### ✅ 예시 쿼리

```js
// 댓글의 좋아요 목록 조회
db.collection("posts")
  .doc("post_001")
  .collection("comments")
  .doc("comment_123")
  .collection("likes")
  .get();
```

---

## 📦 DTO 구조 정리

### 1. PostDto

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
| `createdAt`       | `DateTime`      | ✅        | 특수처리   | 작성 시각                             |
| `hashTags`        | `List<String>`  | ✅        | -        | 해시태그 목록                         |
| `likeCount`       | `int?`           | ✅        | -        | 좋아요 수 (비정규화)                  |
| `commentCount`    | `int?`           | ✅        | -        | 댓글 수 (비정규화)                    |
| `isLikedByCurrentUser`    | `bool?`  | ✅        | `includeFromJson: false, includeToJson: false` | 현재 사용자의 좋아요 상태 (UI용)     |
| `isBookmarkedByCurrentUser`| `bool?`  | ✅        | `includeFromJson: false, includeToJson: false` | 현재 사용자의 북마크 상태 (UI용)   |

### 2. PostLikeDto

| 필드명      | 타입       | nullable | @JsonKey | 설명                         |
|-------------|------------|----------|----------|------------------------------|
| `id`        | `String`  | ✅        | -        | 좋아요 ID (문서 ID와 동일)     |
| `userId`    | `String`  | ✅        | -        | 좋아요 누른 사용자 ID         |
| `userName`  | `String`  | ✅        | -        | 사용자 이름                   |
| `timestamp` | `DateTime`| ✅        | 특수처리   | 좋아요 시간                   |

### 3. PostCommentDto

| 필드명            | 타입       | nullable | @JsonKey | 설명                             |
|-------------------|------------|----------|----------|----------------------------------|
| `id`              | `String`  | ✅        | -        | 댓글 ID (문서 ID와 동일)          |
| `userId`          | `String`  | ✅        | -        | 댓글 작성자 ID                    |
| `userName`        | `String`  | ✅        | -        | 댓글 작성자 이름                  |
| `userProfileImage`| `String`  | ✅        | -        | 댓글 작성자 프로필 이미지 URL      |
| `text`            | `String`  | ✅        | -        | 댓글 본문 내용                     |
| `createdAt`       | `DateTime`| ✅        | 특수처리   | 댓글 작성 시각                     |
| `likeCount`       | `int?`     | ✅        | -        | 좋아요 수 (비정규화)              |
| `isLikedByCurrentUser` | `bool?` | ✅      | `includeFromJson: false, includeToJson: false` | 현재 사용자의 좋아요 상태 (UI용)    |

---

## 📝 최적화 구현

### 1. N+1 문제 해결을 위한 일괄 상태 조회

게시글 목록을 조회할 때 좋아요와 북마크 상태를 일괄 조회하여 N+1 문제를 해결합니다:

```dart
// DataSource 레벨에서 일괄 조회 메소드
Future<Map<String, bool>> checkUserLikeStatus(
  List<String> postIds,
  String userId,
) async {
  // 병렬 처리로 효율성 향상
  final futures = postIds.map((postId) async {
    final doc = await _postsCollection
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .get();
    
    return MapEntry(postId, doc.exists);
  });
  
  // 모든 미래 값을 기다려서 Map으로 변환
  final entries = await Future.wait(futures);
  return Map.fromEntries(entries);
}
```

### 2. 좋아요/북마크 토글 시 트랜잭션 사용

좋아요 상태 토글과 카운터 업데이트를 원자적으로 처리합니다:

```dart
return _firestore.runTransaction<PostDto>((transaction) async {
  // 1. 현재 게시글 상태 조회
  final postDoc = await transaction.get(postRef);
  if (!postDoc.exists) {
    throw Exception('게시글을 찾을 수 없습니다');
  }
  
  // 2. 좋아요 문서 참조 및 조회
  final likeRef = postRef.collection('likes').doc(userId);
  final likeDoc = await transaction.get(likeRef);
  
  // 3. likeCount 필드 가져오기 (없으면 0으로 초기화)
  final data = postDoc.data()!;
  final currentLikeCount = data['likeCount'] as int? ?? 0;
  
  // 4. 좋아요 상태 토글
  if (likeDoc.exists) {
    // 이미 좋아요가 있으면 삭제 및 카운터 감소
    transaction.delete(likeRef);
    transaction.update(postRef, {'likeCount': currentLikeCount - 1});
  } else {
    // 좋아요가 없으면 추가 및 카운터 증가
    transaction.set(likeRef, {
      'userId': userId,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    transaction.update(postRef, {'likeCount': currentLikeCount + 1});
  }
  
  // 5. 업데이트된 게시글 정보 반환을 위한 준비
  data['id'] = postDoc.id;
  
  // 6. DTO 생성 및 필드 업데이트
  return data.toPostDto().copyWith(
    likeCount: likeDoc.exists ? currentLikeCount - 1 : currentLikeCount + 1,
    isLikedByCurrentUser: !likeDoc.exists, // 토글 결과 반영
  );
});
```

### 3. 게시글 검색 및 필터링 최적화

Firestore에서는 배열 내 부분 문자열 검색이 제한적이므로, 클라이언트 측에서 추가 필터링을 수행합니다:

```dart
// 1. 서버 측 필터링 최대한 활용
// 제목 기반 검색 (접두사 검색)
final titleResults = await _postsCollection
    .orderBy('title')
    .startAt([lowercaseQuery])
    .endAt([lowercaseQuery + '\uf8ff'])
    .limit(20)
    .get();

// 내용 기반 검색 (별도 쿼리)
final contentResults = await _postsCollection
    .orderBy('content')
    .startAt([lowercaseQuery])
    .endAt([lowercaseQuery + '\uf8ff'])
    .limit(20)
    .get();

// 검색 결과 합치기 (Set으로 변환하여 중복 제거)
final Set<DocumentSnapshot<Map<String, dynamic>>> mergedDocs = {};
mergedDocs.addAll(titleResults.docs);
mergedDocs.addAll(contentResults.docs);

// 해시태그 검색은 클라이언트 필터링으로 보완
if (mergedDocs.length < 10) {
  final allPosts = await _postsCollection
      .orderBy('createdAt', descending: true)
      .limit(50)
      .get();
      
  for (final doc in allPosts.docs) {
    if (mergedDocs.contains(doc)) continue;
    
    final data = doc.data();
    final hashTags = (data['hashTags'] as List<dynamic>? ?? [])
        .map((tag) => (tag as String).toLowerCase())
        .toList();
        
    if (hashTags.any((tag) => tag.contains(lowercaseQuery))) {
      mergedDocs.add(doc);
    }
  }
}
```

### 4. 댓글에 대한 좋아요 상태 일괄 조회

댓글 목록을 조회할 때 각 댓글의 좋아요 상태를 일괄 조회하여 효율성을 높입니다:

```dart
Future<Map<String, bool>> checkCommentsLikeStatus(
  String postId,
  List<String> commentIds,
  String userId,
) async {
  try {
    // 병렬 처리로 효율성 향상
    final futures = commentIds.map((commentId) async {
      final doc = await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId)
          .get();
          
      return MapEntry(commentId, doc.exists);
    });
    
    final entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  } catch (e) {
    print('댓글 좋아요 상태 확인 오류: $e');
    throw Exception('데이터를 불러오는데 실패했습니다');
  }
}
```

### 5. 작성자 정보 비정규화

사용자 조회를 줄이기 위해 게시글과 댓글에 작성자 정보를 비정규화합니다:

```dart
// 게시글 생성 시 작성자 정보 비정규화
final postData = {
  'authorId': authorId,
  'authorNickname': authorNickname,  // 비정규화
  'authorPosition': authorPosition,  // 비정규화
  'userProfileImage': userProfileImage,  // 비정규화
  'title': title,
  'content': content,
  // ...
};

// 댓글 생성 시 작성자 정보 비정규화
final commentData = {
  'userId': userId,
  'userName': userName,  // 비정규화
  'userProfileImage': userProfileImage,  // 비정규화
  'text': content,
  // ...
};
```

---

## 📚 관련 문서

- [main_firebase_model](firebase_model.md) - Firebase 모델 공통 가이드
- [firebase_user_model](firebase_user_model.md) - User 도메인 모델
- [firebase_group_model](firebase_group_model.md) - Group 도메인 모델