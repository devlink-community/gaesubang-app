// lib/community/domain/model/like.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'like.freezed.dart';

@freezed
class Like with _$Like {
  const Like({required this.boardId, required this.memberId});

  @override
  final String boardId;
  @override
  final String memberId;
}
