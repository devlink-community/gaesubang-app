// lib/community/data/data_source/post_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'post_data_source.dart';

class PostFirebaseDataSource implements PostDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PostFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  @override
  Future<List<PostDto>> fetchPostList() async {
    return ApiCallDecorator.wrap('PostFirebase.fetchPostList', () async {
      try {
        // 게시글 목록 조회 (최신순 정렬)
        final querySnapshot =
            await _postsCollection.orderBy('createdAt', descending: true).get();

        // 병렬 처리로 성능 최적화
        final futures = querySnapshot.docs.map((doc) async {
          final data = doc.data();
          data['id'] = doc.id; // 문서 ID 추가

          return data.toPostDto();
        });

        final posts = await Future.wait(futures);
        return posts;
      } catch (e) {
        throw Exception(CommunityErrorMessages.postLoadFailed);
      }
    });
  }

  @override
  Future<PostDto> fetchPostDetail(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchPostDetail', () async {
      try {
        final docSnapshot = await _postsCollection.doc(postId).get();

        if (!docSnapshot.exists) {
          throw Exception(CommunityErrorMessages.postNotFound);
        }

        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        return data.toPostDto();
      } catch (e) {
        if (e.toString().contains(CommunityErrorMessages.postNotFound)) {
          rethrow;
        }
        throw Exception(CommunityErrorMessages.postLoadFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<PostDto> toggleLike(
    String postId,
    String userId,
    String userName,
  ) async {
    return ApiCallDecorator.wrap('PostFirebase.toggleLike', () async {
      try {
        // 좋아요 컬렉션 참조
        final likeRef = _postsCollection
            .doc(postId)
            .collection('likes')
            .doc(userId);

        // 좋아요 존재 여부 확인
        final likeDoc = await likeRef.get();

        if (likeDoc.exists) {
          // 이미 좋아요가 있으면 삭제 (취소)
          await likeRef.delete();
        } else {
          // 좋아요가 없으면 추가
          await likeRef.set({
            'userId': userId,
            'userName': userName,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // 업데이트된 게시글 정보 반환
        return await fetchPostDetail(postId);
      } catch (e) {
        throw Exception(CommunityErrorMessages.likeFailed);
      }
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<PostDto> toggleBookmark(String postId, String userId) async {
    return ApiCallDecorator.wrap('PostFirebase.toggleBookmark', () async {
      try {
        // 사용자 북마크 컬렉션 참조
        final bookmarkRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('bookmarks')
            .doc(postId);

        // 북마크 존재 여부 확인
        final bookmarkDoc = await bookmarkRef.get();

        if (bookmarkDoc.exists) {
          // 이미 북마크가 있으면 삭제 (취소)
          await bookmarkRef.delete();
        } else {
          // 북마크가 없으면 추가
          await bookmarkRef.set({
            'postId': postId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // 업데이트된 게시글 정보 반환
        return await fetchPostDetail(postId);
      } catch (e) {
        throw Exception(CommunityErrorMessages.bookmarkFailed);
      }
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<List<PostCommentDto>> fetchComments(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchComments', () async {
      try {
        final querySnapshot =
            await _postsCollection
                .doc(postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .get();

        final comments =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data.toPostCommentDto();
            }).toList();

        return comments;
      } catch (e) {
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
          'likeCount': 0,
        };

        // 댓글 추가
        await commentRef.add(commentData);

        // 업데이트된 댓글 목록 반환
        return await fetchComments(postId);
      } catch (e) {
        throw Exception(CommunityErrorMessages.commentCreateFailed);
      }
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<String> createPost({
    required String postId,
    required String authorId,
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

        // 게시글 데이터 생성
        final postData = {
          'authorId': authorId,
          'userProfileImage': userProfileImage,
          'title': title,
          'content': content,
          'mediaUrls': imageUris.map((uri) => uri.toString()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'hashTags': hashTags,
        };

        // 게시글 추가
        await postRef.set(postData);

        // 생성된 게시글 ID 반환
        return postId;
      } catch (e) {
        throw Exception(CommunityErrorMessages.postCreateFailed);
      }
    }, params: {'postId': postId, 'authorId': authorId});
  }

  @override
  Future<List<PostDto>> searchPosts(String query) async {
    return ApiCallDecorator.wrap('PostFirebase.searchPosts', () async {
      try {
        final lowercaseQuery = query.toLowerCase();

        // Firestore는 full-text search가 제한적이므로 클라이언트 측 필터링
        final querySnapshot = await _postsCollection.get();

        final List<PostDto> searchResults = [];

        // 각 게시글을 검사하여 검색 조건에 맞는지 확인
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;

          // 검색 조건 확인 (제목, 내용, 해시태그)
          final title = (data['title'] as String? ?? '').toLowerCase();
          final content = (data['content'] as String? ?? '').toLowerCase();
          final hashTags =
              (data['hashTags'] as List<dynamic>? ?? [])
                  .map((tag) => (tag as String).toLowerCase())
                  .toList();

          // 검색어가 포함되어 있는지 확인
          if (title.contains(lowercaseQuery) ||
              content.contains(lowercaseQuery) ||
              hashTags.any((tag) => tag.contains(lowercaseQuery))) {
            searchResults.add(data.toPostDto());
          }
        }

        return searchResults;
      } catch (e) {
        throw Exception(CommunityErrorMessages.searchFailed);
      }
    }, params: {'query': query});
  }
}
