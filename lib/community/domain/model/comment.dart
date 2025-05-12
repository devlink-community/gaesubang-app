// lib/community/domain/model/comment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment.freezed.dart';

@freezed
class Comment with _$Comment {
  const Comment({
    required this.boardId,
    required this.memberId,
    required this.createdAt,
    required this.content,
  });

  @override
  final String boardId;
  @override
  final String memberId;
  @override
  final DateTime createdAt;
  @override
  final String content;
}
