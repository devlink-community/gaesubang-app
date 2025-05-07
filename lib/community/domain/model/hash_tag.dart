// lib/community/domain/model/hash_tag.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'hash_tag.freezed.dart';

@freezed
class HashTag with _$HashTag {
  const HashTag({required this.id, required this.content});

  @override
  final String id;
  @override
  final String content;
}
