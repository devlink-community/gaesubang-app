// lib/community/data/data_source/post_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post_data_source.dart';

class PostFirebaseDataSource implements PostDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PostFirebaseDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  // 헬퍼 메서드들
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.authInfo('인증되지 않은 사용자 접근 시도');
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }
    AppLogger.debug('현재 사용자 ID: ${user.uid}');
    return user.uid;
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Future<List<PostDto>> fetchPostList() async {
    return ApiCallDecorator.wrap('PostFirebase.fetchPostList', () async {
      AppLogger.logStep(1, 4, 'Firebase 게시글 목록 조회 시작');
      final startTime = DateTime.now();

      try {
        // 1. 게시글 목록 조회 (최신순 정렬)
        AppLogger.logStep(2, 4, 'Firestore에서 게시글 쿼리 실행');
        final querySnapshot =
            await _postsCollection.orderBy('createdAt', descending: true).get();

        if (querySnapshot.docs.isEmpty) {
          AppLogger.info('조회된 게시글이 없음');
          return [];
        }

        AppLogger.debug('조회된 게시글 수: ${querySnapshot.docs.length}개');

        // 2. 게시글 ID 목록 추출
        final postIds = querySnapshot.docs.map((doc) => doc.id).toList();
        AppLogger.logStep(3, 4, '게시글 ID 목록 추출 완료: ${postIds.length}개');

        // 3. 좋아요/북마크 상태 일괄 조회
        AppLogger.debug('사용자 상호작용 상태 조회 시작');
        final results = await Future.wait<dynamic>([
          checkUserLikeStatus(postIds),
          checkUserBookmarkStatus(postIds),
        ]);

        final Map<String, bool> likeStatuses = results[0] as Map<String, bool>;
        final Map<String, bool> bookmarkStatuses =
            results[1] as Map<String, bool>;

        AppLogger.debug(
          '좋아요 상태: ${likeStatuses.values.where((v) => v).length}개',
        );
        AppLogger.debug(
          '북마크 상태: ${bookmarkStatuses.values.where((v) => v).length}개',
        );

        // 4. 각 게시글 정보로 DTO 생성
        AppLogger.logStep(4, 4, 'DTO 변환 및 상태 적용');
        final posts =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;

              // JSON으로부터 DTO 생성
              final postDto = PostDto.fromJson(data);

              // 현재 사용자의 좋아요/북마크 상태
              final isLikedByCurrentUser = likeStatuses[doc.id] ?? false;
              final isBookmarkedByCurrentUser =
                  bookmarkStatuses[doc.id] ?? false;

              // 필요한 필드만 업데이트하여 DTO 반환
              return postDto.copyWith(
                isLikedByCurrentUser: isLikedByCurrentUser,
                isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
              );
            }).toList();

        // 성능 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 목록 조회', duration);
        AppLogger.communityInfo('게시글 목록 조회 완료: ${posts.length}개');

        return posts;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 목록 조회 실패', duration);
        AppLogger.networkError('게시글 목록 로드 실패', error: e, stackTrace: st);
        throw Exception(CommunityErrorMessages.postLoadFailed);
      }
    });
  }

  @override
  Future<PostDto> fetchPostDetail(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchPostDetail', () async {
      AppLogger.logBox('게시글 상세 조회', '게시글 ID: $postId');
      final startTime = DateTime.now();

      try {
        AppLogger.logStep(1, 5, 'Firestore 문서 조회');
        final docSnapshot = await _postsCollection.doc(postId).get();

        if (!docSnapshot.exists) {
          AppLogger.warning('존재하지 않는 게시글: $postId');
          throw Exception(CommunityErrorMessages.postNotFound);
        }

        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        // 내부에서 현재 사용자 ID 처리
        final userId = _getCurrentUserId();

        AppLogger.logStep(2, 5, '게시글 통계 정보 수집');
        // 좋아요 수와 댓글 수 가져오기
        int likeCount = 0;
        int commentCount = 0;

        // 필드가 있고 null이 아닌 경우 해당 값 사용
        if (data.containsKey('likeCount') && data['likeCount'] != null) {
          likeCount = data['likeCount'] as int;
          AppLogger.debug('캐시된 likeCount 사용: $likeCount');
        } else {
          // 값이 없거나 null인 경우에만 실제 계산
          AppLogger.debug('likeCount 실시간 계산 중...');
          final likesSnapshot =
              await docSnapshot.reference.collection('likes').get();
          likeCount = likesSnapshot.size;
          AppLogger.debug('실시간 계산된 likeCount: $likeCount');
        }

        if (data.containsKey('commentCount') && data['commentCount'] != null) {
          commentCount = data['commentCount'] as int;
          AppLogger.debug('캐시된 commentCount 사용: $commentCount');
        } else {
          // 값이 없거나 null인 경우에만 실제 계산
          AppLogger.debug('commentCount 실시간 계산 중...');
          final commentsSnapshot =
              await docSnapshot.reference.collection('comments').get();
          commentCount = commentsSnapshot.size;
          AppLogger.debug('실시간 계산된 commentCount: $commentCount');
        }

        AppLogger.logStep(3, 5, '사용자 상호작용 상태 확인');
        // 현재 사용자의 좋아요/북마크 상태 확인
        bool isLikedByCurrentUser = false;
        bool isBookmarkedByCurrentUser = false;

        // 좋아요 상태 확인
        final userLikeDoc =
            await docSnapshot.reference.collection('likes').doc(userId).get();
        isLikedByCurrentUser = userLikeDoc.exists;
        AppLogger.debug('사용자 좋아요 상태: $isLikedByCurrentUser');

        // 북마크 상태 확인
        final userBookmarkDoc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('bookmarks')
                .doc(postId)
                .get();
        isBookmarkedByCurrentUser = userBookmarkDoc.exists;
        AppLogger.debug('사용자 북마크 상태: $isBookmarkedByCurrentUser');

        AppLogger.logStep(4, 5, 'DTO 생성 및 필드 업데이트');
        // DTO 생성 및 추가 정보 설정
        final postDto = data.toPostDto();
        final result = postDto.copyWith(
          likeCount: likeCount,
          commentCount: commentCount,
          isLikedByCurrentUser: isLikedByCurrentUser,
          isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
        );

        AppLogger.logStep(5, 5, '게시글 상세 조회 완료');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 상세 조회', duration);

        AppLogger.logState('PostDetailResult', {
          'postId': postId,
          'likeCount': likeCount,
          'commentCount': commentCount,
          'isLiked': isLikedByCurrentUser,
          'isBookmarked': isBookmarkedByCurrentUser,
        });

        return result;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 상세 조회 실패', duration);

        // ✅ 예외 구분 처리
        if (e is Exception &&
            e.toString().contains(CommunityErrorMessages.postNotFound)) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.warning('게시글 상세 비즈니스 로직 오류: $postId', error: e);
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.networkError(
            '게시글 상세 Firebase 통신 오류: $postId',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'postId': postId});
  }

  @override
  Future<PostDto> toggleLike(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.toggleLike', () async {
      AppLogger.logBox('좋아요 토글', '게시글: $postId');
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 정보 처리
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          AppLogger.authInfo('인증되지 않은 사용자의 좋아요 시도');
          throw Exception(AuthErrorMessages.noLoggedInUser);
        }

        final currentUserId = currentUser.uid;
        final currentUserName = currentUser.displayName ?? '';

        AppLogger.debug('좋아요 토글 사용자: $currentUserId ($currentUserName)');

        // 게시글 문서 참조
        final postRef = _postsCollection.doc(postId);

        AppLogger.logStep(1, 3, 'Firebase 트랜잭션 시작');
        // 트랜잭션 사용하여 좋아요 카운터와 문서를 원자적으로 업데이트
        final result = await _firestore.runTransaction<PostDto>((
          transaction,
        ) async {
          AppLogger.debug('트랜잭션 내부: 현재 상태 조회');

          // 현재 게시글 상태 조회
          final postDoc = await transaction.get(postRef);
          if (!postDoc.exists) {
            AppLogger.warning('트랜잭션 중 게시글 없음: $postId');
            throw Exception(CommunityErrorMessages.postNotFound);
          }

          // 좋아요 문서 참조 및 조회
          final likeRef = postRef.collection('likes').doc(currentUserId);
          final likeDoc = await transaction.get(likeRef);

          // likeCount 필드 가져오기 (없으면 0으로 초기화)
          final data = postDoc.data()!;
          final currentLikeCount = data['likeCount'] as int? ?? 0;

          AppLogger.debug(
            '현재 좋아요 수: $currentLikeCount, 사용자 좋아요 존재: ${likeDoc.exists}',
          );

          if (likeDoc.exists) {
            // 이미 좋아요가 있으면 삭제 및 카운터 감소
            AppLogger.debug('좋아요 제거 처리');
            transaction.delete(likeRef);
            transaction.update(postRef, {'likeCount': currentLikeCount - 1});
          } else {
            // 좋아요가 없으면 추가 및 카운터 증가
            AppLogger.debug('좋아요 추가 처리');
            transaction.set(likeRef, {
              'userId': currentUserId,
              'userName': currentUserName,
              'timestamp': FieldValue.serverTimestamp(),
            });
            transaction.update(postRef, {'likeCount': currentLikeCount + 1});
          }

          // 업데이트된 게시글 정보 반환을 위한 준비
          data['id'] = postDoc.id;

          // DTO 생성 및 필드 업데이트
          final updatedDto = data.toPostDto().copyWith(
            likeCount:
                likeDoc.exists ? currentLikeCount - 1 : currentLikeCount + 1,
            isLikedByCurrentUser: !likeDoc.exists, // 토글 결과 반영
          );

          AppLogger.debug('트랜잭션 완료 - 새 좋아요 수: ${updatedDto.likeCount}');
          return updatedDto;
        });

        AppLogger.logStep(2, 3, '트랜잭션 성공');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 좋아요 토글', duration);

        // ✅ nullable 값 처리
        final action = (result.isLikedByCurrentUser ?? false) ? '추가' : '제거';
        AppLogger.communityInfo(
          '좋아요 $action 완료: $postId (총 ${result.likeCount ?? 0}개)',
        );

        AppLogger.logStep(3, 3, '좋아요 토글 완료');
        return result;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 좋아요 토글 실패', duration);
        AppLogger.networkError('좋아요 토글 실패: $postId', error: e, stackTrace: st);
        throw Exception(CommunityErrorMessages.likeFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<PostDto> toggleBookmark(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.toggleBookmark', () async {
      AppLogger.logBox('북마크 토글', '게시글: $postId');
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 ID 처리
        final currentUserId = _getCurrentUserId();
        AppLogger.debug('북마크 토글 사용자: $currentUserId');

        // 사용자 북마크 컬렉션 및 게시글 참조
        final userRef = _firestore.collection('users').doc(currentUserId);
        final bookmarkRef = userRef.collection('bookmarks').doc(postId);
        final postRef = _postsCollection.doc(postId);

        AppLogger.logStep(1, 3, 'Firebase 트랜잭션 시작');
        // 트랜잭션 사용하여 북마크 상태 원자적으로 업데이트
        final result = await _firestore.runTransaction<PostDto>((
          transaction,
        ) async {
          AppLogger.debug('트랜잭션 내부: 현재 상태 조회');

          // 현재 게시글 및 북마크 상태 조회
          final postDoc = await transaction.get(postRef);
          final bookmarkDoc = await transaction.get(bookmarkRef);

          if (!postDoc.exists) {
            AppLogger.warning('트랜잭션 중 게시글 없음: $postId');
            throw Exception(CommunityErrorMessages.postNotFound);
          }

          // 게시글 데이터 준비
          final data = postDoc.data()!;
          data['id'] = postDoc.id;

          AppLogger.debug('현재 북마크 상태: ${bookmarkDoc.exists}');

          // 북마크 상태 토글
          if (bookmarkDoc.exists) {
            // 이미 북마크가 있으면 삭제 (취소)
            AppLogger.debug('북마크 제거 처리');
            transaction.delete(bookmarkRef);
          } else {
            // 북마크가 없으면 추가
            AppLogger.debug('북마크 추가 처리');
            transaction.set(bookmarkRef, {
              'postId': postId,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }

          // 현재 좋아요 수와 댓글 수 유지 (이미 데이터에 있을 수 있음)
          final likeCount = data['likeCount'] as int? ?? 0;
          final commentCount = data['commentCount'] as int? ?? 0;

          // DTO 생성 및 필드 업데이트 (북마크 상태만 토글)
          final updatedDto = data.toPostDto().copyWith(
            likeCount: likeCount,
            commentCount: commentCount,
            isBookmarkedByCurrentUser: !bookmarkDoc.exists, // 토글 결과 반영
          );

          AppLogger.debug(
            '트랜잭션 완료 - 북마크 상태: ${updatedDto.isBookmarkedByCurrentUser}',
          );
          return updatedDto;
        });

        AppLogger.logStep(2, 3, '트랜잭션 성공');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 북마크 토글', duration);

        // ✅ nullable 값 처리
        final action =
            (result.isBookmarkedByCurrentUser ?? false) ? '추가' : '제거';
        AppLogger.communityInfo('북마크 $action 완료: $postId');

        AppLogger.logStep(3, 3, '북마크 토글 완료');
        return result;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 북마크 토글 실패', duration);
        AppLogger.networkError('북마크 토글 실패: $postId', error: e, stackTrace: st);
        throw Exception(CommunityErrorMessages.bookmarkFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostCommentDto>> fetchComments(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.fetchComments', () async {
      AppLogger.logBox('댓글 목록 조회', '게시글: $postId');
      final startTime = DateTime.now();

      try {
        AppLogger.logStep(1, 5, '댓글 목록 Firestore 쿼리');
        // 1. 댓글 목록 조회 (최신순 정렬)
        final querySnapshot =
            await _postsCollection
                .doc(postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .get();

        if (querySnapshot.docs.isEmpty) {
          AppLogger.info('댓글이 없음: $postId');
          return [];
        }

        AppLogger.debug('조회된 댓글 수: ${querySnapshot.docs.length}개');

        AppLogger.logStep(2, 5, '댓글 ID 목록 추출');
        // 2. 댓글 ID 목록 추출
        final commentIds = querySnapshot.docs.map((doc) => doc.id).toList();

        AppLogger.logStep(3, 5, '댓글 좋아요 상태 조회');
        // 3. 좋아요 상태 일괄 조회
        final likeStatusesFuture = checkCommentsLikeStatus(postId, commentIds);

        AppLogger.logStep(4, 5, '댓글 DTO 변환 및 카운트 처리');
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
              AppLogger.debug('댓글 ${doc.id} likeCount 실시간 계산');
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

        AppLogger.logStep(5, 5, '좋아요 상태 적용 및 최종 결과 생성');
        // 6. 좋아요 상태 적용
        final finalComments =
            commentDtos.map((dto) {
              final commentId = dto.id ?? '';
              final isLiked = likeStatuses[commentId] ?? false;
              return dto.copyWith(isLikedByCurrentUser: isLiked);
            }).toList();

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 댓글 목록 조회', duration);

        // ✅ nullable 값 처리
        final likedCommentsCount =
            finalComments
                .where((c) => (c.isLikedByCurrentUser ?? false))
                .length;
        AppLogger.communityInfo(
          '댓글 목록 조회 완료: $postId (${finalComments.length}개, $likedCommentsCount개 좋아요)',
        );

        return finalComments;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 댓글 목록 조회 실패', duration);
        AppLogger.networkError(
          '댓글 목록 로드 실패: $postId',
          error: e,
          stackTrace: st,
        );
        throw Exception(CommunityErrorMessages.commentLoadFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String content,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.createComment', () async {
      final contentPreview = _truncateText(content, 30);
      AppLogger.logBox('댓글 작성', '게시글: $postId, 내용: "$contentPreview"');
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 정보 처리
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          AppLogger.authInfo('인증되지 않은 사용자의 댓글 작성 시도');
          throw Exception(AuthErrorMessages.noLoggedInUser);
        }

        final currentUserId = currentUser.uid;
        final currentUserName = currentUser.displayName ?? '';
        final currentUserProfileImage = currentUser.photoURL ?? '';

        AppLogger.debug('댓글 작성자: $currentUserId ($currentUserName)');

        // 게시글 및 댓글 컬렉션 참조
        final postRef = _postsCollection.doc(postId);
        final commentRef = postRef.collection('comments');

        // 새 댓글 ID 미리 생성
        final newCommentId = commentRef.doc().id;
        AppLogger.debug('새 댓글 ID 생성: $newCommentId');

        AppLogger.logStep(1, 3, 'Firebase 트랜잭션 시작');
        // 트랜잭션 사용하여 댓글 추가와 commentCount 증가를 원자적으로 처리
        await _firestore.runTransaction((transaction) async {
          AppLogger.debug('트랜잭션 내부: 게시글 상태 확인');

          // 1. 현재 게시글 상태 확인
          final postDoc = await transaction.get(postRef);
          if (!postDoc.exists) {
            AppLogger.warning('트랜잭션 중 게시글 없음: $postId');
            throw Exception(CommunityErrorMessages.postNotFound);
          }

          // 2. 현재 댓글 수 가져오기 (null이면 0으로 초기화)
          final data = postDoc.data()!;
          final currentCommentCount = data['commentCount'] as int? ?? 0;
          AppLogger.debug('현재 댓글 수: $currentCommentCount');

          // 3. 댓글 데이터 생성
          final commentData = {
            'userId': currentUserId,
            'userName': currentUserName,
            'userProfileImage': currentUserProfileImage,
            'text': content,
            'createdAt': FieldValue.serverTimestamp(),
            'likeCount': 0,
          };

          AppLogger.debug('댓글 데이터 생성 완료');

          // 4. 트랜잭션에 댓글 추가 및 카운터 증가 작업 포함
          transaction.set(commentRef.doc(newCommentId), commentData);
          transaction.update(postRef, {
            'commentCount': currentCommentCount + 1,
          });

          AppLogger.debug('트랜잭션 작업 등록 완료');
        });

        AppLogger.logStep(2, 3, '트랜잭션 성공');

        AppLogger.logStep(3, 3, '업데이트된 댓글 목록 조회');
        // 5. 업데이트된 댓글 목록 반환
        final result = await fetchComments(postId);

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 댓글 작성', duration);
        AppLogger.communityInfo('댓글 작성 완료: $postId (총 ${result.length}개)');

        return result;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 댓글 작성 실패', duration);
        AppLogger.networkError('댓글 작성 실패: $postId', error: e, stackTrace: st);
        throw Exception(CommunityErrorMessages.commentCreateFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<PostCommentDto> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.toggleCommentLike',
      () async {
        AppLogger.logBox('댓글 좋아요 토글', '게시글: $postId, 댓글: $commentId');
        final startTime = DateTime.now();

        try {
          // 내부에서 현재 사용자 정보 처리
          final currentUser = _auth.currentUser;
          if (currentUser == null) {
            AppLogger.authInfo('인증되지 않은 사용자의 댓글 좋아요 시도');
            throw Exception(AuthErrorMessages.noLoggedInUser);
          }

          final currentUserId = currentUser.uid;
          final currentUserName = currentUser.displayName ?? '';

          AppLogger.debug('댓글 좋아요 토글 사용자: $currentUserId ($currentUserName)');

          // 댓글 및 좋아요 참조
          final commentRef = _postsCollection
              .doc(postId)
              .collection('comments')
              .doc(commentId);
          final likeRef = commentRef.collection('likes').doc(currentUserId);

          AppLogger.logStep(1, 3, 'Firebase 트랜잭션 시작');
          // 트랜잭션 사용하여 좋아요 토글 및 카운터 원자적으로 업데이트
          final result = await _firestore.runTransaction<PostCommentDto>((
            transaction,
          ) async {
            AppLogger.debug('트랜잭션 내부: 현재 상태 조회');

            // 현재 댓글 및 좋아요 상태 조회
            final commentDoc = await transaction.get(commentRef);
            final likeDoc = await transaction.get(likeRef);

            if (!commentDoc.exists) {
              AppLogger.warning('트랜잭션 중 댓글 없음: $commentId');
              throw Exception(CommunityErrorMessages.commentLoadFailed);
            }

            // 댓글 데이터 준비
            final commentData = commentDoc.data()!;
            commentData['id'] = commentDoc.id;

            // likeCount 필드 가져오기 (없으면 0으로 초기화)
            final currentLikeCount = commentData['likeCount'] as int? ?? 0;

            AppLogger.debug(
              '현재 댓글 좋아요 수: $currentLikeCount, 사용자 좋아요 존재: ${likeDoc.exists}',
            );

            // 좋아요 상태 토글
            if (likeDoc.exists) {
              // 이미 좋아요가 있으면 삭제 및 카운터 감소
              AppLogger.debug('댓글 좋아요 제거 처리');
              transaction.delete(likeRef);
              transaction.update(commentRef, {
                'likeCount': currentLikeCount > 0 ? currentLikeCount - 1 : 0,
              });
            } else {
              // 좋아요가 없으면 추가 및 카운터 증가
              AppLogger.debug('댓글 좋아요 추가 처리');
              transaction.set(likeRef, {
                'userId': currentUserId,
                'userName': currentUserName,
                'timestamp': FieldValue.serverTimestamp(),
              });
              transaction.update(commentRef, {
                'likeCount': currentLikeCount + 1,
              });
            }

            // DTO 생성 및 필드 업데이트
            final updatedDto = commentData.toPostCommentDto().copyWith(
              likeCount:
                  likeDoc.exists ? currentLikeCount - 1 : currentLikeCount + 1,
              isLikedByCurrentUser: !likeDoc.exists, // 토글 결과 반영
            );

            AppLogger.debug('트랜잭션 완료 - 새 댓글 좋아요 수: ${updatedDto.likeCount}');
            return updatedDto;
          });

          AppLogger.logStep(2, 3, '트랜잭션 성공');
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('Firebase 댓글 좋아요 토글', duration);

          // ✅ nullable 값 처리
          final action = (result.isLikedByCurrentUser ?? false) ? '추가' : '취소';
          AppLogger.communityInfo(
            '댓글 좋아요 $action 완료: $commentId (총 ${result.likeCount ?? 0}개)',
          );

          AppLogger.logStep(3, 3, '댓글 좋아요 토글 완료');
          return result;
        } catch (e, st) {
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('Firebase 댓글 좋아요 토글 실패', duration);
          AppLogger.networkError(
            '댓글 좋아요 토글 실패: $postId/$commentId',
            error: e,
            stackTrace: st,
          );
          throw Exception(CommunityErrorMessages.likeFailed);
        }
      },
      params: {'postId': postId, 'commentId': commentId},
    );
  }

  @override
  Future<Map<String, bool>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.checkCommentsLikeStatus',
      () async {
        AppLogger.debug('댓글 좋아요 상태 일괄 조회: $postId (${commentIds.length}개)');
        final startTime = DateTime.now();

        try {
          // 내부에서 현재 사용자 ID 처리
          final userId = _getCurrentUserId();

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
          final result = Map.fromEntries(entries);

          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('Firebase 댓글 좋아요 상태 조회', duration);

          final likedCount = result.values.where((liked) => liked).length;
          AppLogger.debug(
            '댓글 좋아요 상태 조회 완료: $postId ($likedCount/${commentIds.length}개 좋아요)',
          );

          return result;
        } catch (e, st) {
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('Firebase 댓글 좋아요 상태 조회 실패', duration);
          AppLogger.networkError(
            '댓글 좋아요 상태 확인 실패: $postId',
            error: e,
            stackTrace: st,
          );
          throw Exception(CommunityErrorMessages.dataLoadFailed);
        }
      },
      params: {'postId': postId, 'commentCount': commentIds.length},
    );
  }

  @override
  Future<List<PostDto>> searchPosts(String query) async {
    return ApiCallDecorator.wrap('PostFirebase.searchPosts', () async {
      AppLogger.logBox('게시글 검색', '검색어: "$query"');
      final startTime = DateTime.now();

      try {
        if (query.trim().isEmpty) {
          AppLogger.warning('빈 검색어로 검색 시도');
          return [];
        }

        final lowercaseQuery = query.toLowerCase();
        final List<PostDto> searchResults = [];

        AppLogger.logStep(1, 4, '서버 측 필터링 시작');
        // 1. 서버 측 필터링 최대한 활용 (부분 일치 검색은 제한적)
        // 제목 기반 검색 (접두사 검색만 가능)
        final titleResults =
            await _postsCollection
                .orderBy('title')
                .startAt([lowercaseQuery])
                .endAt(['$lowercaseQuery\uf8ff'])
                .limit(20)
                .get();

        // 내용 기반 검색 (별도 쿼리)
        final contentResults =
            await _postsCollection
                .orderBy('content')
                .startAt([lowercaseQuery])
                .endAt(['$lowercaseQuery\uf8ff'])
                .limit(20)
                .get();

        AppLogger.debug('제목 검색 결과: ${titleResults.docs.length}개');
        AppLogger.debug('내용 검색 결과: ${contentResults.docs.length}개');

        AppLogger.logStep(2, 4, '검색 결과 합치기 및 해시태그 검색');
        // 해시태그 검색은 배열 필드에 대한 부분 일치가 불가능하므로 클라이언트 필터링 필요
        // 검색 결과 합치기 (Set으로 변환하여 중복 제거)
        final Set<DocumentSnapshot<Map<String, dynamic>>> mergedDocs = {};
        mergedDocs.addAll(titleResults.docs);
        mergedDocs.addAll(contentResults.docs);

        // 검색 결과가 충분하지 않으면 추가로 모든 게시글 검색 (해시태그 검색용)
        if (mergedDocs.length < 10) {
          AppLogger.debug('해시태그 검색을 위한 추가 쿼리 실행');
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
          AppLogger.info('검색 결과 없음: "$query"');
          return [];
        }

        AppLogger.debug('최종 검색 결과: ${mergedDocs.length}개');

        AppLogger.logStep(3, 4, '사용자 상호작용 상태 일괄 조회');
        // 2. 검색 결과에 대한 문서 ID 추출
        final postIds = mergedDocs.map((doc) => doc.id).toList();

        // 3. 좋아요 상태 및 북마크 상태 일괄 조회 (N+1 문제 해결)
        // 좋아요 상태 일괄 조회
        final likeStatuses = await checkUserLikeStatus(postIds);

        // 북마크 상태 일괄 조회
        final bookmarkStatuses = await checkUserBookmarkStatus(postIds);

        AppLogger.logStep(4, 4, '검색 결과 DTO 변환 및 정렬');
        // 4. 좋아요 수 및 댓글 수 일괄 가져오기 (병렬 처리)
        final countFutures = mergedDocs.map((doc) async {
          final docId = doc.id;
          final data = doc.data() ?? {}; // null 방지
          data['id'] = docId;

          // 최적화: 비정규화된 카운터 필드 값이 null인 경우에만 실제 계산
          int likeCount = 0;
          int commentCount = 0;

          // 필드가 존재하고 null이 아닌 경우에는 해당 값 사용
          if (data.containsKey('likeCount') && data['likeCount'] != null) {
            likeCount = (data['likeCount'] as int);
          } else {
            // 값이 없거나 null인 경우에만 실제 계산 (성능 최적화)
            final likesSnapshot = await doc.reference.collection('likes').get();
            likeCount = likesSnapshot.size;
          }

          if (data.containsKey('commentCount') &&
              data['commentCount'] != null) {
            commentCount = (data['commentCount'] as int);
          } else {
            // 값이 없거나 null인 경우에만 실제 계산 (성능 최적화)
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

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 검색', duration);
        AppLogger.searchInfo(query, searchResults.length);

        return searchResults;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 검색 실패', duration);
        AppLogger.networkError('게시글 검색 실패: "$query"', error: e, stackTrace: st);
        throw Exception(CommunityErrorMessages.searchFailed);
      }
    }, params: {'query': query});
  }

  @override
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.createPost', () async {
      final titlePreview = _truncateText(title, 30);
      AppLogger.logBox(
        '게시글 작성',
        '제목: "$titlePreview" | '
            '내용: ${content.length}자 | '
            '태그: ${hashTags.length}개 | '
            '이미지: ${imageUris.length}개',
      );
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 정보 처리
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          AppLogger.authInfo('인증되지 않은 사용자의 게시글 작성 시도');
          throw Exception(AuthErrorMessages.noLoggedInUser);
        }

        final currentUserId = currentUser.uid;
        final currentUserNickname = currentUser.displayName ?? '';
        final currentUserProfileImage = currentUser.photoURL ?? '';

        AppLogger.debug('게시글 작성자: $currentUserId ($currentUserNickname)');

        // 전달받은 ID로 문서 참조
        final postRef = _postsCollection.doc(postId);

        AppLogger.logStep(1, 2, '게시글 데이터 생성');
        // 게시글 데이터 생성 (현재 사용자 정보 사용)
        final postData = {
          'authorId': currentUserId,
          'authorNickname': currentUserNickname,
          'authorPosition': '', // Firebase Auth에는 position이 없으므로 빈 문자열
          'userProfileImage': currentUserProfileImage,
          'title': title,
          'content': content,
          'mediaUrls': imageUris.map((uri) => uri.toString()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'hashTags': hashTags,
          'likeCount': 0, // 좋아요 수 초기화
          'commentCount': 0, // 댓글 수 초기화
        };

        AppLogger.logStep(2, 2, 'Firestore에 게시글 저장');
        // 게시글 추가
        await postRef.set(postData);

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 작성', duration);
        AppLogger.logBanner('새 게시글 생성 완료! 🎉');
        AppLogger.communityInfo('게시글 생성 성공: $postId');

        // 생성된 게시글 ID 반환
        return postId;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 작성 실패', duration);
        AppLogger.networkError('게시글 생성 실패: $postId', error: e, stackTrace: st);
        throw Exception(CommunityErrorMessages.postCreateFailed);
      }
    }, params: {'postId': postId});
  }

  // 새로 추가되는 메서드 - 좋아요 상태 일괄 조회
  @override
  Future<Map<String, bool>> checkUserLikeStatus(List<String> postIds) async {
    return ApiCallDecorator.wrap('PostFirebase.checkUserLikeStatus', () async {
      AppLogger.debug('좋아요 상태 일괄 조회: ${postIds.length}개');
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 ID 처리
        final userId = _getCurrentUserId();

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
        final result = Map.fromEntries(entries);

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 좋아요 상태 일괄 조회', duration);

        final likedCount = result.values.where((liked) => liked).length;
        AppLogger.debug('좋아요 상태 일괄 조회 완료: $likedCount/${postIds.length}개 좋아요');

        return result;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 좋아요 상태 일괄 조회 실패', duration);
        AppLogger.networkError('좋아요 상태 일괄 조회 실패', error: e, stackTrace: st);
        // 오류 발생 시 모든 게시글에 대해 false 반환
        return {for (final id in postIds) id: false};
      }
    }, params: {'postIds': postIds.length});
  }

  // 새로 추가되는 메서드 - 북마크 상태 일괄 조회
  @override
  Future<Map<String, bool>> checkUserBookmarkStatus(
    List<String> postIds,
  ) async {
    return ApiCallDecorator.wrap(
      'PostFirebase.checkUserBookmarkStatus',
      () async {
        AppLogger.debug('북마크 상태 일괄 조회: ${postIds.length}개');
        final startTime = DateTime.now();

        try {
          // 내부에서 현재 사용자 ID 처리
          final userId = _getCurrentUserId();

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
          final result = Map.fromEntries(entries);

          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('Firebase 북마크 상태 일괄 조회', duration);

          final bookmarkedCount =
              result.values.where((bookmarked) => bookmarked).length;
          AppLogger.debug(
            '북마크 상태 일괄 조회 완료: $bookmarkedCount/${postIds.length}개 북마크',
          );

          return result;
        } catch (e, st) {
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('Firebase 북마크 상태 일괄 조회 실패', duration);
          AppLogger.networkError('북마크 상태 일괄 조회 실패', error: e, stackTrace: st);
          // 오류 발생 시 모든 게시글에 대해 false 반환
          return {for (final id in postIds) id: false};
        }
      },
      params: {'postIds': postIds.length},
    );
  }

  @override
  Future<String> updatePost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('PostFirebase.updatePost', () async {
      final titlePreview = _truncateText(title, 30);
      AppLogger.logBox(
        '게시글 수정',
        '게시글: $postId | '
            '제목: "$titlePreview" | '
            '내용: ${content.length}자 | '
            '태그: ${hashTags.length}개 | '
            '이미지: ${imageUris.length}개',
      );
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 정보 처리
        final currentUserId = _getCurrentUserId();

        // 게시글 참조
        final postRef = _postsCollection.doc(postId);

        AppLogger.logStep(1, 3, '게시글 존재 및 권한 확인');
        // 게시글 존재 확인
        final doc = await postRef.get();
        if (!doc.exists) {
          AppLogger.warning('수정하려는 게시글이 존재하지 않음: $postId');
          throw Exception(CommunityErrorMessages.postNotFound);
        }

        // 권한 확인 (작성자만 수정 가능)
        final data = doc.data()!;
        if (data['authorId'] != currentUserId) {
          AppLogger.warning(
            '게시글 수정 권한 없음: $postId (작성자: ${data['authorId']}, 요청자: $currentUserId)',
          );
          throw Exception(CommunityErrorMessages.noPermissionEdit);
        }

        AppLogger.logStep(2, 3, '업데이트 데이터 준비');
        // 업데이트할 데이터 준비
        final Map<String, dynamic> updateData = {
          'title': title,
          'content': content,
          'hashTags': hashTags,
          'mediaUrls': imageUris.map((uri) => uri.toString()).toList(),
          // authorNickname, authorPosition, userProfileImage는 현재 사용자 기준으로 업데이트되지 않음
          // 작성 시점의 정보를 유지
        };

        AppLogger.logStep(3, 3, 'Firestore 게시글 업데이트');
        // 게시글 업데이트
        await postRef.update(updateData);

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 수정', duration);
        AppLogger.logBanner('게시글 수정 완료! ✨');
        AppLogger.communityInfo('게시글 수정 성공: $postId');

        return postId;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 수정 실패', duration);

        // ✅ 예외 구분 처리
        if (e is Exception &&
            (e.toString().contains(CommunityErrorMessages.postNotFound) ||
                e.toString().contains(
                  CommunityErrorMessages.noPermissionEdit,
                ))) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.warning('게시글 수정 비즈니스 로직 오류: $postId', error: e);
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.networkError(
            '게시글 수정 Firebase 통신 오류: $postId',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'postId': postId});
  }

  @override
  Future<bool> deletePost(String postId) async {
    return ApiCallDecorator.wrap('PostFirebase.deletePost', () async {
      AppLogger.logBox('게시글 삭제', '게시글 ID: $postId');
      final startTime = DateTime.now();

      try {
        // 내부에서 현재 사용자 ID 처리
        final currentUserId = _getCurrentUserId();

        // 게시글 참조
        final postRef = _postsCollection.doc(postId);

        AppLogger.logStep(1, 4, '게시글 존재 및 권한 확인');
        // 게시글 존재 및 권한 확인
        final doc = await postRef.get();
        if (!doc.exists) {
          AppLogger.warning('삭제하려는 게시글이 존재하지 않음: $postId');
          throw Exception(CommunityErrorMessages.postNotFound);
        }

        // 권한 확인 (작성자만 삭제 가능)
        final data = doc.data()!;
        if (data['authorId'] != currentUserId) {
          AppLogger.warning(
            '게시글 삭제 권한 없음: $postId (작성자: ${data['authorId']}, 요청자: $currentUserId)',
          );
          throw Exception(CommunityErrorMessages.noPermissionDelete);
        }

        AppLogger.logStep(2, 4, '댓글 및 좋아요 데이터 삭제');
        // 단계별로 삭제 (트랜잭션 없이)
        // 1. 댓글 컬렉션 내 문서들 삭제
        final commentsSnapshot = await postRef.collection('comments').get();
        AppLogger.debug('삭제할 댓글 수: ${commentsSnapshot.docs.length}개');

        for (final commentDoc in commentsSnapshot.docs) {
          // 댓글 내 좋아요 컬렉션도 삭제
          final likesSnapshot =
              await commentDoc.reference.collection('likes').get();
          AppLogger.debug(
            '댓글 ${commentDoc.id}의 좋아요 수: ${likesSnapshot.docs.length}개',
          );

          for (final likeDoc in likesSnapshot.docs) {
            await likeDoc.reference.delete();
          }
          await commentDoc.reference.delete();
        }

        AppLogger.logStep(3, 4, '게시글 좋아요 데이터 삭제');
        // 2. 좋아요 컬렉션 내 문서들 삭제
        final likesSnapshot = await postRef.collection('likes').get();
        AppLogger.debug('삭제할 게시글 좋아요 수: ${likesSnapshot.docs.length}개');

        for (final likeDoc in likesSnapshot.docs) {
          await likeDoc.reference.delete();
        }

        AppLogger.logStep(4, 4, '게시글 문서 삭제');
        // 3. 게시글 문서 자체 삭제
        await postRef.delete();

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 삭제', duration);
        AppLogger.logBanner('게시글 삭제 완료! 🗑️');
        AppLogger.communityInfo('게시글 삭제 성공: $postId');

        return true;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('Firebase 게시글 삭제 실패', duration);

        // ✅ 예외 구분 처리
        if (e is Exception &&
            (e.toString().contains(CommunityErrorMessages.postNotFound) ||
                e.toString().contains(
                  CommunityErrorMessages.noPermissionDelete,
                ))) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.warning('게시글 삭제 비즈니스 로직 오류: $postId', error: e);
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.networkError(
            '게시글 삭제 Firebase 통신 오류: $postId',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'postId': postId});
  }
}
