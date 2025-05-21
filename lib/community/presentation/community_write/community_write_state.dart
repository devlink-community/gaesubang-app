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
    this.updatedPostId, // 수정된 게시글 ID
    this.isEditMode = false, // 수정 모드 여부
    this.originalPostId, // 수정 중인 원본 게시글 ID
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
  @override
  final String? updatedPostId;
  @override
  final bool isEditMode;
  @override
  final String? originalPostId;
}
