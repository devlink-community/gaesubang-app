# 🧩 Firebase 데이터 모델 설계 가이드

---

## 📋 개요

이 문서는 Firebase Firestore를 활용한 데이터 모델 설계와 DTO 구조에 대한 가이드를 제공합니다.
앱에서 사용하는 핵심 도메인들의 데이터 구조와 최적화 방법을 설명합니다.

---

## 🗂️ 도메인별 문서

각 도메인별 상세 모델 문서는 다음 링크를 참조하세요:

- [User 도메인 모델](firebase_user_model.md) - 사용자, 인증 관련 모델
- [Group 도메인 모델](firebase_group_model.md) - 그룹, 멤버 관련 모델
- [Post 도메인 모델](firebase_post_model.md) - 게시글, 댓글, 좋아요 관련 모델

---

## 🔧 공통 최적화 패턴

### 1. Firebase Timestamp 변환

Firebase Timestamp와 Dart DateTime 사이의 변환은 다음과 같이 처리합니다:

```dart
// lib/core/utils/firebase_timestamp_converter.dart
@JsonKey(
  fromJson: FirebaseTimestampConverter.timestampFromJson,
  toJson: FirebaseTimestampConverter.timestampToJson,
)
final DateTime? timestamp;
```

### 2. N+1 문제 해결 패턴

목록 조회 시 각 항목마다 추가 정보를 조회하는 N+1 문제를 방지하기 위해 다음과 같은 일괄 조회 패턴을 사용합니다:

```dart
// 일괄 조회 예시
Future<Map<String, bool>> checkUserLikeStatus(List<String> itemIds, String userId) async {
  // 병렬 처리로 효율성 향상
  final futures = itemIds.map((itemId) async {
    final doc = await collection.doc(itemId).collection('likes').doc(userId).get();
    return MapEntry(itemId, doc.exists);
  });

  // 모든 미래 값을 기다려서 Map으로 변환
  final entries = await Future.wait(futures);
  return Map.fromEntries(entries);
}
```

### 3. UI 전용 필드 처리

Firebase에 저장되지 않고 UI 표시용으로만 사용되는 필드는 다음과 같이 처리합니다:

```dart
// UI 전용 필드 - Firestore에는 저장하지 않음
@JsonKey(includeFromJson: false, includeToJson: false)
final bool? isLikedByCurrentUser;
```

### 4. 트랜잭션을 활용한 원자적 업데이트

카운터 업데이트와 같은 작업은 트랜잭션을 사용하여 원자적으로 처리합니다:

```dart
return _firestore.runTransaction<ResultDto>((transaction) async {
  // 1. 현재 상태 조회
  final docSnapshot = await transaction.get(docRef);
  
  // 2. 상태 확인 및 업데이트 전 처리
  final data = docSnapshot.data()!;
  final currentCount = data['count'] as int? ?? 0;
  
  // 3. 상태에 따른 트랜잭션 작업 추가
  if (shouldIncrease) {
    transaction.update(docRef, {'count': currentCount + 1});
    // 다른 필요한 문서 업데이트...
  } else {
    transaction.update(docRef, {'count': currentCount - 1});
    // 다른 필요한 문서 업데이트...
  }
  
  // 4. 업데이트된 결과 반환
  return ResultDto(...);
});
```

### 5. 비정규화를 통한 쿼리 최적화

자주 사용되는 정보는 비정규화하여 중복 쿼리를 방지합니다:

```dart
// 작성자 정보를 게시글에 비정규화
final postData = {
  'authorId': userId,
  'authorNickname': userName,  // 비정규화된 필드
  'authorPosition': position,  // 비정규화된 필드
  'userProfileImage': profileUrl,  // 비정규화된 필드
  'content': content,
  // ...
};
```

---

## 📚 관련 문서

- [dto.md](dto.md) - DTO 설계 가이드
- [mapper.md](mapper.md) - Mapper 패턴 설계 가이드
- [repository.md](repository.md) - Repository 설계 가이드
- [datasource.md](datasource.md) - DataSource 설계 가이드