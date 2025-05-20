// lib/community/domain/model/comment.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';

@freezed
class Comment with _$Comment {
  const Comment({
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByCurrentUser = false, // 추가된 필드
  });

  final String userId;
  final String userName;
  final String userProfileImage;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByCurrentUser; // 사용자가 좋아요를 눌렀는지 여부
}
