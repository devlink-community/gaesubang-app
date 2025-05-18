// lib/community/data/data_source/post_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/data/dto/comment_dto_old.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto_old.dart';
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

  // Collection 참조
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  @override
  Future<List<PostDto>> fetchPostList() async {
    try {
      final querySnapshot = await _postsCollection.get();

      return Future.wait(
        querySnapshot.docs.map((doc) async {
          final data = doc.data();
          data['id'] = doc.id;

          // member 컬렉션에서 작성자 정보 가져오기
          final memberSnapshot = await doc.reference.collection('member').get();
          if (memberSnapshot.docs.isNotEmpty) {
            data['member'] = memberSnapshot.docs.first.data();
          }

          // 좋아요 개수 가져오기
          final likesSnapshot = await doc.reference.collection('likes').get();
          final likesList =
              likesSnapshot.docs.map((likeDoc) {
                final likeData = likeDoc.data();
                return likeData;
              }).toList();
          data['like'] = likesList;

          // 댓글 개수 가져오기
          final commentsSnapshot =
              await doc.reference.collection('comments').get();
          final commentsList =
              commentsSnapshot.docs.map((commentDoc) {
                final commentData = commentDoc.data();
                return commentData;
              }).toList();
          data['comment'] = commentsList;

          return PostDto.fromJson(data);
        }).toList(),
      );
    } catch (e) {
      throw Exception('게시글 목록을 불러오는데 실패했습니다: $e');
    }
  }

  @override
  Future<PostDto> fetchPostDetail(String postId) async {
    try {
      final docSnapshot = await _postsCollection.doc(postId).get();

      if (!docSnapshot.exists) {
        throw Exception('게시글을 찾을 수 없습니다: $postId');
      }

      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;

      // member 컬렉션에서 작성자 정보 가져오기
      final memberSnapshot =
          await docSnapshot.reference.collection('member').get();
      if (memberSnapshot.docs.isNotEmpty) {
        data['member'] = memberSnapshot.docs.first.data();
      }

      // 좋아요 목록 가져오기
      final likesSnapshot =
          await docSnapshot.reference.collection('likes').get();
      final likesList =
          likesSnapshot.docs.map((likeDoc) {
            final likeData = likeDoc.data();
            return likeData;
          }).toList();
      data['like'] = likesList;

      // 댓글 목록 가져오기
      final commentsSnapshot =
          await docSnapshot.reference
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();

      final commentsList =
          commentsSnapshot.docs.map((commentDoc) {
            final commentData = commentDoc.data();
            return commentData;
          }).toList();
      data['comment'] = commentsList;

      return PostDto.fromJson(data);
    } catch (e) {
      throw Exception('게시글 상세 정보를 불러오는데 실패했습니다: $e');
    }
  }

  @override
  Future<PostDto> toggleLike(String postId) async {
    try {
      // 현재 사용자 ID (임시로 'user1' 사용)
      const currentUserId = 'user1';
      const currentUserName = '유저1';

      // 좋아요 컬렉션 참조
      final likeRef = _postsCollection
          .doc(postId)
          .collection('likes')
          .doc(currentUserId);

      // 좋아요 존재 여부 확인
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // 이미 좋아요가 있으면 삭제 (취소)
        await likeRef.delete();
      } else {
        // 좋아요가 없으면 추가
        await likeRef.set({
          'userId': currentUserId,
          'userName': currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 업데이트된 게시글 정보 반환
      return fetchPostDetail(postId);
    } catch (e) {
      throw Exception('좋아요 토글에 실패했습니다: $e');
    }
  }

  @override
  Future<PostDto> toggleBookmark(String postId) async {
    try {
      // 현재 사용자 ID (임시로 'user1' 사용)
      const currentUserId = 'user1';

      // 사용자 북마크 컬렉션 참조
      final bookmarkRef = _firestore
          .collection('users')
          .doc(currentUserId)
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
      return fetchPostDetail(postId);
    } catch (e) {
      throw Exception('북마크 토글에 실패했습니다: $e');
    }
  }

  @override
  Future<List<CommentDto>> fetchComments(String postId) async {
    try {
      final querySnapshot =
          await _postsCollection
              .doc(postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CommentDto.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('댓글 목록을 불러오는데 실패했습니다: $e');
    }
  }

  @override
  Future<List<CommentDto>> createComment({
    required String postId,
    required String memberId,
    required String content,
  }) async {
    try {
      // 댓글 컬렉션 참조
      final commentRef =
          _postsCollection.doc(postId).collection('comments').doc();

      // 사용자 정보 (임시 사용)
      const userName = "댓글유저1";
      const userProfileImage =
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8vc9ryU13FZJ9ExDPX2O5_CZxn1ms6O8xhg&s";

      // 댓글 데이터 생성
      final commentData = {
        'userId': memberId,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'text': content,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
      };

      // 댓글 추가
      await commentRef.set(commentData);

      // 업데이트된 댓글 목록 반환
      return fetchComments(postId);
    } catch (e) {
      throw Exception('댓글 작성에 실패했습니다: $e');
    }
  }

  @override
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    try {
      // 현재 사용자 ID (임시로 'user1' 사용)
      const currentUserId = 'user1';

      // 전달받은 ID로 문서 참조
      final postRef = _postsCollection.doc(postId);

      // 게시글 데이터 생성
      final postData = {
        'title': title,
        'content': content,
        'boardType': 'free',
        'createAt': FieldValue.serverTimestamp(),
        'hashTags': hashTags,
        'imageUrls': imageUris.map((uri) => uri.toString()).toList(),
        'userProfileImageUrl':
            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8vc9ryU13FZJ9ExDPX2O5_CZxn1ms6O8xhg&s",
      };

      // 게시글 추가
      await postRef.set(postData);

      // 작성자 정보 추가
      await postRef.collection('member').add({
        'email': 'user1@firebase.com',
        'nickname': '유저1',
        'uid': 'uid1',
        'description': '유저1 자기소개',
        'image':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8vc9ryU13FZJ9ExDPX2O5_CZxn1ms6O8xhg&s',
      });

      // 생성된 게시글 ID 반환
      return postId;
    } catch (e) {
      throw Exception('게시글 작성에 실패했습니다: $e');
    }
  }

  @override
  Future<List<PostDto>> searchPosts(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();

      // 전체 게시글 가져오기 (Firestore는 텍스트 검색에 제한적인 기능 제공)
      final querySnapshot = await _postsCollection.get();

      // 클라이언트 측에서 필터링
      final List<PostDto> searchResults = [];

      for (final doc in querySnapshot.docs) {
        // 기본 데이터 가져오기
        final data = doc.data();
        data['id'] = doc.id;

        // 검색 조건 확인 (제목, 내용, 해시태그)
        final title = (data['title'] as String? ?? '').toLowerCase();
        final content = (data['content'] as String? ?? '').toLowerCase();
        final hashTags =
            (data['hashTags'] as List<dynamic>? ?? [])
                .map((tag) => (tag as String).toLowerCase())
                .toList();

        // 검색 조건 확인
        if (title.contains(lowercaseQuery) ||
            content.contains(lowercaseQuery) ||
            hashTags.any((tag) => tag.contains(lowercaseQuery))) {
          // member 컬렉션에서 작성자 정보 가져오기
          final memberSnapshot = await doc.reference.collection('member').get();
          if (memberSnapshot.docs.isNotEmpty) {
            data['member'] = memberSnapshot.docs.first.data();
          }

          // 좋아요 및 댓글 목록 가져오기
          final likesSnapshot = await doc.reference.collection('likes').get();
          data['like'] = likesSnapshot.docs.map((e) => e.data()).toList();

          final commentsSnapshot =
              await doc.reference.collection('comments').get();
          data['comment'] = commentsSnapshot.docs.map((e) => e.data()).toList();

          // 결과에 추가
          searchResults.add(PostDto.fromJson(data));
        }
      }

      return searchResults;
    } catch (e) {
      throw Exception('게시글 검색에 실패했습니다: $e');
    }
  }
}
