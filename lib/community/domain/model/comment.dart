// lib/community/domain/model/comment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment.freezed.dart';

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required String boardId,
    required String memberId,
    required DateTime createdAt,
    required String content,
  }) = _Comment;
}
