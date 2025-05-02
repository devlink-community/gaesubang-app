// lib/community/domain/model/like.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'like.freezed.dart';

@freezed
abstract class Like with _$Like {
  const factory Like({required String boardId, required String memberId}) =
      _Like;
}
