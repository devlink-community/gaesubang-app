// lib/community/data/data_source/post_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';

import 'post_data_source.dart';

class PostFirebaseDataSource implements PostDataSource {
  final FirebaseFirestore _firestore;

  PostFirebaseDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  // 기존 fetchPostList 메서드 수정 - commentCount 추가
  @override
  Future<List<PostDto>> fetchPostList({String? currentUserId}) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchPostList', () async {
      try {
        // 1. 게시글 목록 조회 (최신순 정렬)
        final querySnapshot =
            await _postsCollection.orderBy('createdAt', descending: true).get();

        if (querySnapshot.docs.isEmpty) {
          return [];
        }

        // 2. 게시글 ID 목록 추출
        final postIds = querySnapshot.docs.map((doc) => doc.id).toList();

        // 3. 현재 사용자가 로그인한 경우 좋아요/북마크 상태 일괄 조회
        Map<String, bool> likeStatuses = {};
        Map<String, bool> bookmarkStatuses = {};

        if (currentUserId != null && currentUserId.isNotEmpty) {
          // 좋아요 상태와 북마크 상태 병렬 조회
          final results = await Future.wait<dynamic>([
            checkUserLikeStatus(postIds, currentUserId),
            checkUserBookmarkStatus(postIds, currentUserId),
          ]);

          likeStatuses = results[0] as Map<String, bool>;
          bookmarkStatuses = results[1] as Map<String, bool>;
        }

        // 4. 각 게시글 정보로 DTO 생성
        final posts =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;

              // JSON으로부터 DTO 생성
              final postDto = PostDto.fromJson(data);

              // 비정규화된 카운터 값 가져오기 (DTO에 이미 포함되어 있을 수 있음)
              int? likeCount = postDto.likeCount;
              int? commentCount = postDto.commentCount;

              // 현재 사용자의 좋아요/북마크 상태
              final isLikedByCurrentUser = likeStatuses[doc.id] ?? false;
              final isBookmarkedByCurrentUser =
                  bookmarkStatuses[doc.id] ?? false;

              // 필요한 필드만 업데이트하여 DTO 반환
              return postDto.copyWith(
                likeCount: likeCount,
                commentCount: commentCount,
                isLikedByCurrentUser: isLikedByCurrentUser,
                isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
              );
            }).toList();

        return posts;
      } catch (e) {
        print('게시글 목록 로드 오류: $e');
        throw Exception(CommunityErrorMessages.postLoadFailed);
      }
    });
  }

  // 기존 fetchPostDetail 메서드 수정 - commentCount 추가
  @override
  Future<PostDto> fetchPostDetail(
    String postId, {
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchPostDetail', () async {
      try {
        final docSnapshot = await _postsCollection.doc(postId).get();

        if (!docSnapshot.exists) {
          throw Exception(CommunityErrorMessages.postNotFound);
        }

        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        // 현재 로그인한 사용자 ID (없으면 빈 문자열)
        final userId = currentUserId ?? '';

        // 좋아요 수 계산
        final likesSnapshot =
            await docSnapshot.reference.collection('likes').get();
        final likeCount = likesSnapshot.size;

        // 댓글 수 계산 (추가)
        final commentsSnapshot =
            await docSnapshot.reference.collection('comments').get();
        final commentCount = commentsSnapshot.size;

        // 현재 사용자의 좋아요/북마크 상태 확인
        bool isLikedByCurrentUser = false;
        bool isBookmarkedByCurrentUser = false;

        if (userId.isNotEmpty) {
          // 좋아요 상태 확인
          final userLikeDoc =
              await docSnapshot.reference
                  .collection('likes')
                  .doc(currentUserId)
                  .get();
          isLikedByCurrentUser = userLikeDoc.exists;

          // 북마크 상태 확인
          final userBookmarkDoc =
              await _firestore
                  .collection('users')
                  .doc(currentUserId)
                  .collection('bookmarks')
                  .doc(postId)
                  .get();
          isBookmarkedByCurrentUser = userBookmarkDoc.exists;
        }

        // DTO 생성 및 추가 정보 설정
        final postDto = data.toPostDto();
        return postDto.copyWith(
          likeCount: likeCount,
          commentCount: commentCount, // 댓글 수 추가
          isLikedByCurrentUser: isLikedByCurrentUser,
          isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
        );
      } catch (e) {
        if (e.toString().contains(CommunityErrorMessages.postNotFound)) {
          rethrow;
        }
        print('게시글 상태 로드 오류: $e');
        throw Exception(CommunityErrorMessages.postLoadFailed);
      }
    }, params: {'postId': postId});
  }

  // toggleLike 메서드 - 트랜잭션 활용하여 개선
  @override
  Future<PostDto> toggleLike(
    String postId,
    String userId,
    String userName,
  ) async {
    return ApiCallDecorator.wrap('PostFirebase.toggleLike', () async {
      try {
        // 게시글 문서 참조
        final postRef = _postsCollection.doc(postId);

        // 트랜잭션 사용하여 좋아요 카운터와 문서를 원자적으로 업데이트
        return _firestore.runTransaction<PostDto>((transaction) async {
          // 현재 게시글 상태 조회
          final postDoc = await transaction.get(postRef);
          if (!postDoc.exists) {
            throw Exception(CommunityErrorMessages.postNotFound);
          }

          // 좋아요 문서 참조 및 조회
          final likeRef = postRef.collection('likes').doc(userId);
          final likeDoc = await transaction.get(likeRef);

          // likeCount 필드 가져오기 (없으면 0으로 초기화)
          final data = postDoc.data()!;
          final currentLikeCount = data['likeCount'] as int? ?? 0;

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

          // 업데이트된 게시글 정보 반환을 위한 준비
          // 트랜잭션 내에서는 업데이트된 데이터를 바로 읽을 수 없으므로
          // 수동으로 반환할 DTO를 구성

          // 기존 데이터에 id 추가
          data['id'] = postDoc.id;

          // DTO 생성 및 필드 업데이트
          return data.toPostDto().copyWith(
            likeCount:
                likeDoc.exists ? currentLikeCount - 1 : currentLikeCount + 1,
            isLikedByCurrentUser: !likeDoc.exists, // 토글 결과 반영
          );
        });
      } catch (e) {
        print('좋아요 토글 오류: $e');
        throw Exception(CommunityErrorMessages.likeFailed);
      }
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<PostDto> toggleBookmark(String postId, String userId) async {
    return ApiCallDecorator.wrap('PostFirebase.toggleBookmark', () async {
      try {
        // 사용자 북마크 컬렉션 및 게시글 참조
        final userRef = _firestore.collection('users').doc(userId);
        final bookmarkRef = userRef.collection('bookmarks').doc(postId);
        final postRef = _postsCollection.doc(postId);

        // 트랜잭션 사용하여 북마크 상태 원자적으로 업데이트
        return _firestore.runTransaction<PostDto>((transaction) async {
          // 현재 게시글 및 북마크 상태 조회
          final postDoc = await transaction.get(postRef);
          final bookmarkDoc = await transaction.get(bookmarkRef);

          if (!postDoc.exists) {
            throw Exception(CommunityErrorMessages.postNotFound);
          }

          // 게시글 데이터 준비
          final data = postDoc.data()!;
          data['id'] = postDoc.id;

          // 북마크 상태 토글
          if (bookmarkDoc.exists) {
            // 이미 북마크가 있으면 삭제 (취소)
            transaction.delete(bookmarkRef);
          } else {
            // 북마크가 없으면 추가
            transaction.set(bookmarkRef, {
              'postId': postId,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }

          // 현재 좋아요 수와 댓글 수 유지 (이미 데이터에 있을 수 있음)
          final likeCount = data['likeCount'] as int? ?? 0;
          final commentCount = data['commentCount'] as int? ?? 0;

          // DTO 생성 및 필드 업데이트 (북마크 상태만 토글)
          return data.toPostDto().copyWith(
            likeCount: likeCount,
            commentCount: commentCount,
            isBookmarkedByCurrentUser: !bookmarkDoc.exists, // 토글 결과 반영
          );
        });
      } catch (e) {
        print('북마크 토글 오류: $e');
        throw Exception(CommunityErrorMessages.bookmarkFailed);
      }
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<List<PostCommentDto>> fetchComments(
    String postId, {
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchComments', () async {
      try {
        // 1. 댓글 목록 조회 (최신순 정렬)
        final querySnapshot =
            await _postsCollection
                .doc(postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .get();

        if (querySnapshot.docs.isEmpty) {
          return [];
        }

        // 2. 댓글 ID 목록 추출
        final commentIds = querySnapshot.docs.map((doc) => doc.id).toList();

        // 3. 현재 사용자가 로그인한 경우 좋아요 상태 일괄 조회
        final userId = currentUserId ?? '';
        final likeStatusesFuture =
            userId.isNotEmpty
                ? checkCommentsLikeStatus(postId, commentIds, userId)
                : Future.value(<String, bool>{});

        // 4. 병렬 처리로 각 댓글의 처리를 수행
        final commentsFuture = Future.wait(
          querySnapshot.docs.map((doc) async {
            final data = doc.data();
            data['id'] = doc.id;

            // DTO로 변환
            final commentDto = PostCommentDto.fromJson(data);

            // likeCount가 없는 경우를 위한 처리
            int? likeCount = commentDto.likeCount;
            if (likeCount == null) {
              // 필요한 경우에만 추가 쿼리 (성능 최적화)
              final likesSnapshot =
                  await doc.reference.collection('likes').get();
              likeCount = likesSnapshot.size;
            }

            return commentDto.copyWith(likeCount: likeCount);
          }),
        );

        // 5. 모든 비동기 작업 완료 대기 (타입 명시)
        final results = await Future.wait<dynamic>([
          likeStatusesFuture,
          commentsFuture,
        ]);

        final Map<String, bool> likeStatuses = results[0] as Map<String, bool>;
        final List<PostCommentDto> commentDtos =
            results[1] as List<PostCommentDto>;

        // 6. 좋아요 상태 적용
        final finalComments =
            commentDtos.map((dto) {
              final commentId = dto.id ?? '';
              final isLiked = likeStatuses[commentId] ?? false;
              return dto.copyWith(isLikedByCurrentUser: isLiked);
            }).toList();

        return finalComments;
      } catch (e) {
        print('댓글 목록 로드 오류: $e');
        throw Exception(CommunityErrorMessages.commentLoadFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String userProfileImage,
    required String content,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.createComment', () async {
      try {
        // 댓글 컬렉션 참조
        final commentRef = _postsCollection.doc(postId).collection('comments');

        // 댓글 데이터 생성
        final commentData = {
          'userId': userId,
          'userName': userName,
          'userProfileImage': userProfileImage,
          'text': content,
          'createdAt': FieldValue.serverTimestamp(),
          'likeCount': 0, // 초기 좋아요 수
        };

        // 댓글 추가
        await commentRef.add(commentData);

        // 업데이트된 댓글 목록 반환
        return await fetchComments(postId);
      } catch (e) {
        print('댓글 작성 오류: $e');
        throw Exception(CommunityErrorMessages.commentCreateFailed);
      }
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<PostCommentDto> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
    String userName,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.toggleCommentLike',
      () async {
        try {
          // 댓글 및 좋아요 참조
          final commentRef = _postsCollection
              .doc(postId)
              .collection('comments')
              .doc(commentId);
          final likeRef = commentRef.collection('likes').doc(userId);

          // 트랜잭션 사용하여 좋아요 토글 및 카운터 원자적으로 업데이트
          return _firestore.runTransaction<PostCommentDto>((transaction) async {
            // 현재 댓글 및 좋아요 상태 조회
            final commentDoc = await transaction.get(commentRef);
            final likeDoc = await transaction.get(likeRef);

            if (!commentDoc.exists) {
              throw Exception(CommunityErrorMessages.commentLoadFailed);
            }

            // 댓글 데이터 준비
            final commentData = commentDoc.data()!;
            commentData['id'] = commentDoc.id;

            // likeCount 필드 가져오기 (없으면 0으로 초기화)
            final currentLikeCount = commentData['likeCount'] as int? ?? 0;

            // 좋아요 상태 토글
            if (likeDoc.exists) {
              // 이미 좋아요가 있으면 삭제 및 카운터 감소
              transaction.delete(likeRef);
              transaction.update(commentRef, {
                'likeCount': currentLikeCount > 0 ? currentLikeCount - 1 : 0,
              });
            } else {
              // 좋아요가 없으면 추가 및 카운터 증가
              transaction.set(likeRef, {
                'userId': userId,
                'userName': userName,
                'timestamp': FieldValue.serverTimestamp(),
              });
              transaction.update(commentRef, {
                'likeCount': currentLikeCount + 1,
              });
            }

            // DTO 생성 및 필드 업데이트
            return commentData.toPostCommentDto().copyWith(
              likeCount:
                  likeDoc.exists ? currentLikeCount - 1 : currentLikeCount + 1,
              isLikedByCurrentUser: !likeDoc.exists, // 토글 결과 반영
            );
          });
        } catch (e) {
          print('댓글 좋아요 토글 오류: $e');
          throw Exception(CommunityErrorMessages.likeFailed);
        }
      },
      params: {'postId': postId, 'commentId': commentId, 'userId': userId},
    );
  }

  @override
  Future<Map<String, bool>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.checkCommentsLikeStatus',
      () async {
        try {
          // 각 댓글의 좋아요 상태 확인 (병렬 처리)
          final futures = commentIds.map((commentId) async {
            final likeDoc =
                await _postsCollection
                    .doc(postId)
                    .collection('comments')
                    .doc(commentId)
                    .collection('likes')
                    .doc(userId)
                    .get();

            return MapEntry(commentId, likeDoc.exists);
          });

          final entries = await Future.wait(futures);
          return Map.fromEntries(entries);
        } catch (e) {
          print('댓글 좋아요 상태 확인 오류: $e');
          throw Exception(CommunityErrorMessages.dataLoadFailed);
        }
      },
      params: {
        'postId': postId,
        'commentCount': commentIds.length,
        'userId': userId,
      },
    );
  }

  @override
  Future<List<PostDto>> searchPosts(
    String query, {
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.searchPosts', () async {
      try {
        if (query.trim().isEmpty) {
          return [];
        }

        final lowercaseQuery = query.toLowerCase();
        final List<PostDto> searchResults = [];

        // 1. 서버 측 필터링 최대한 활용 (부분 일치 검색은 제한적)
        // 제목 기반 검색 (접두사 검색만 가능)
        final titleResults =
            await _postsCollection
                .orderBy('title')
                .startAt([lowercaseQuery])
                .endAt([lowercaseQuery + '\uf8ff'])
                .limit(20)
                .get();

        // 내용 기반 검색 (별도 쿼리)
        final contentResults =
            await _postsCollection
                .orderBy('content')
                .startAt([lowercaseQuery])
                .endAt([lowercaseQuery + '\uf8ff'])
                .limit(20)
                .get();

        // 해시태그 검색은 배열 필드에 대한 부분 일치가 불가능하므로 클라이언트 필터링 필요
        // 검색 결과 합치기 (Set으로 변환하여 중복 제거)
        final Set<DocumentSnapshot<Map<String, dynamic>>> mergedDocs = {};
        mergedDocs.addAll(titleResults.docs);
        mergedDocs.addAll(contentResults.docs);

        // 검색 결과가 충분하지 않으면 추가로 모든 게시글 검색 (해시태그 검색용)
        if (mergedDocs.length < 10) {
          final allPosts =
              await _postsCollection
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .get();

          // 해시태그 검색
          for (final doc in allPosts.docs) {
            if (mergedDocs.contains(doc)) continue;

            final data = doc.data();
            final hashTags =
                (data['hashTags'] as List<dynamic>? ?? [])
                    .map((tag) => (tag as String).toLowerCase())
                    .toList();

            if (hashTags.any((tag) => tag.contains(lowercaseQuery))) {
              mergedDocs.add(doc);
            }
          }
        }

        // 검색 결과가 없으면 빈 리스트 반환
        if (mergedDocs.isEmpty) {
          return [];
        }

        // 2. 검색 결과에 대한 문서 ID 추출
        final postIds = mergedDocs.map((doc) => doc.id).toList();

        // 3. 좋아요 상태 및 북마크 상태 일괄 조회 (N+1 문제 해결)
        Map<String, bool> likeStatuses = {};
        Map<String, bool> bookmarkStatuses = {};

        // 로그인한 사용자인 경우에만 상태 확인
        final userId = currentUserId ?? '';
        if (userId.isNotEmpty) {
          // 좋아요 상태 일괄 조회
          likeStatuses = await checkUserLikeStatus(postIds, userId);

          // 북마크 상태 일괄 조회
          bookmarkStatuses = await checkUserBookmarkStatus(postIds, userId);
        }

        // 4. 좋아요 수 및 댓글 수 일괄 가져오기 (병렬 처리)
        final countFutures = mergedDocs.map((doc) async {
          final docId = doc.id;
          final data = doc.data() ?? {}; // null 방지
          data['id'] = docId;

          // 최적화: 비정규화된 카운터 필드가 있으면 직접 사용
          // null 체크 추가
          int likeCount = 0;
          int commentCount = 0;

          // 안전하게 값 가져오기
          if (data.containsKey('likeCount') && data['likeCount'] != null) {
            likeCount = (data['likeCount'] as int);
          }

          if (data.containsKey('commentCount') &&
              data['commentCount'] != null) {
            commentCount = (data['commentCount'] as int);
          }

          // 비정규화된 카운터가 없는 경우에만 실제 계산 (성능 최적화)
          if (likeCount == 0) {
            final likesSnapshot = await doc.reference.collection('likes').get();
            likeCount = likesSnapshot.size;
          }

          if (commentCount == 0) {
            final commentsSnapshot =
                await doc.reference.collection('comments').get();
            commentCount = commentsSnapshot.size;
          }

          // DTO 생성 및 추가 정보 설정
          final postDto = data.toPostDto();
          return postDto.copyWith(
            likeCount: likeCount,
            commentCount: commentCount,
            isLikedByCurrentUser: likeStatuses[docId] ?? false,
            isBookmarkedByCurrentUser: bookmarkStatuses[docId] ?? false,
          );
        });

        // 모든 게시글 정보 병렬 로드 완료 대기
        searchResults.addAll(await Future.wait(countFutures));

        // 5. 최신순으로 정렬하여 결과 반환
        searchResults.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );

        return searchResults;
      } catch (e) {
        print('게시글 검색 오류: $e');
        throw Exception(CommunityErrorMessages.searchFailed);
      }
    }, params: {'query': query});
  }

  @override
  Future<String> createPost({
    required String postId,
    required String authorId,
    required String authorNickname,
    required String authorPosition,
    required String userProfileImage,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.createPost', () async {
      try {
        // 전달받은 ID로 문서 참조
        final postRef = _postsCollection.doc(postId);

        // 게시글 데이터 생성 (작성자 정보 추가)
        final postData = {
          'authorId': authorId,
          'authorNickname': authorNickname, // 작성자 닉네임
          'authorPosition': authorPosition, // 작성자 직책/포지션
          'userProfileImage': userProfileImage,
          'title': title,
          'content': content,
          'mediaUrls': imageUris.map((uri) => uri.toString()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'hashTags': hashTags,
          'likeCount': 0, // 좋아요 수 초기화
          'commentCount': 0, // 댓글 수 초기화
        };

        // 게시글 추가
        await postRef.set(postData);

        // 생성된 게시글 ID 반환
        return postId;
      } catch (e) {
        print('게시글 생성 오류: $e');
        throw Exception(CommunityErrorMessages.postCreateFailed);
      }
    }, params: {'postId': postId, 'authorId': authorId});
  }

  // 새로 추가되는 메서드 - 좋아요 상태 일괄 조회
  @override
  Future<Map<String, bool>> checkUserLikeStatus(
    List<String> postIds,
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.checkUserLikeStatus',
      () async {
        try {
          // 병렬 처리로 효율성 향상
          final futures = postIds.map((postId) async {
            final doc =
                await _postsCollection
                    .doc(postId)
                    .collection('likes')
                    .doc(userId)
                    .get();

            // postId를 키로, 좋아요 여부를 값으로 저장
            return MapEntry(postId, doc.exists);
          });

          // 모든 미래 값을 기다려서 Map으로 변환
          final entries = await Future.wait(futures);
          return Map.fromEntries(entries);
        } catch (e) {
          print('좋아요 상태 일괄 조회 오류: $e');
          // 오류 발생 시 모든 게시글에 대해 false 반환
          return {for (final id in postIds) id: false};
        }
      },
      params: {'postIds': postIds.length, 'userId': userId},
    );
  }

  // 새로 추가되는 메서드 - 북마크 상태 일괄 조회
  @override
  Future<Map<String, bool>> checkUserBookmarkStatus(
    List<String> postIds,
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.checkUserBookmarkStatus',
      () async {
        try {
          // 병렬 처리로 효율성 향상
          final futures = postIds.map((postId) async {
            final doc =
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('bookmarks')
                    .doc(postId)
                    .get();

            // postId를 키로, 북마크 여부를 값으로 저장
            return MapEntry(postId, doc.exists);
          });

          // 모든 미래 값을 기다려서 Map으로 변환
          final entries = await Future.wait(futures);
          return Map.fromEntries(entries);
        } catch (e) {
          print('북마크 상태 일괄 조회 오류: $e');
          // 오류 발생 시 모든 게시글에 대해 false 반환
          return {for (final id in postIds) id: false};
        }
      },
      params: {'postIds': postIds.length, 'userId': userId},
    );
  }
}
