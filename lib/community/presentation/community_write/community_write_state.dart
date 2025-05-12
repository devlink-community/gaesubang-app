// lib/community/presentation/community_write/community_write_state.dart
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_write_state.freezed.dart';

@freezed
class CommunityWriteState with _$CommunityWriteState {
  const CommunityWriteState({
    this.title = '',
    this.content = '',
    this.hashTags = const <String>[],
    this.images = const <Uint8List>[],
    this.submitting = false,
    this.errorMessage,
    this.createdPostId,
  });

  @override
  final String title;
  @override
  final String content;
  @override
  final List<String> hashTags;
  @override
  final List<Uint8List> images;
  @override
  final bool submitting;
  @override
  final String? errorMessage;
  @override
  final String? createdPostId;
}
