// lib/community/domain/model/hash_tag.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'hash_tag.freezed.dart';

@freezed
abstract class HashTag with _$HashTag {
  const factory HashTag({
    required String id,
    required String content,
  }) = _HashTag;
}
