import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_event.freezed.dart';

/// 앱 내 글로벌 이벤트 정의
@freezed
sealed class AppEvent with _$AppEvent {
  // 프로필 관련 이벤트
  const factory AppEvent.profileUpdated() = ProfileUpdated;

  // 커뮤니티 관련 이벤트
  const factory AppEvent.postCreated(String postId) = PostCreated;
  const factory AppEvent.postUpdated(String postId) = PostUpdated;
  const factory AppEvent.postDeleted(String postId) = PostDeleted;
  const factory AppEvent.postLiked(String postId) = PostLiked;
  const factory AppEvent.postBookmarked(String postId) = PostBookmarked;
  const factory AppEvent.commentAdded(String postId, String commentId) =
      CommentAdded;
  const factory AppEvent.commentLiked(String postId, String commentId) =
      CommentLiked;
}
