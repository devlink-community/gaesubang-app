// ignore_for_file: annotate_overrides
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_settings_state.freezed.dart';

/// 이미지 업로드 상태를 나타내는 enum
enum ImageUploadStatus {
  idle, // 업로드 대기 상태
  compressing, // 이미지 압축 중
  uploading, // Firebase Storage 업로드 중
  completed, // 업로드 완료
  failed, // 업로드 실패
}

@freezed
class GroupSettingsState with _$GroupSettingsState {
  const GroupSettingsState({
    this.group = const AsyncValue.loading(),
    this.members = const AsyncValue.loading(),
    this.name = '',
    this.description = '',
    this.imageUrl,
    this.hashTags = const [],
    this.limitMemberCount = 10,
    this.isEditing = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.isOwner = false,
    // 이미지 업로드 관련 새 필드들
    this.imageUploadStatus = ImageUploadStatus.idle,
    this.uploadProgress = 0.0,
    this.originalImagePath,
  });

  final AsyncValue<Group> group;
  final AsyncValue<List<GroupMember>> members;
  final String name;
  final String description;
  final String? imageUrl;
  final List<HashTag> hashTags;
  final int limitMemberCount;
  final bool isEditing;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final bool isOwner;

  // 이미지 업로드 관련 새 필드들
  final ImageUploadStatus imageUploadStatus;
  final double uploadProgress; // 0.0 ~ 1.0
  final String? originalImagePath; // 원본 이미지 경로 (로컬)

  // 헬퍼 메서드들

  /// 이미지 업로드 중인지 확인
  bool get isImageUploading =>
      imageUploadStatus == ImageUploadStatus.compressing ||
      imageUploadStatus == ImageUploadStatus.uploading;

  /// 이미지 압축 중인지 확인
  bool get isImageCompressing =>
      imageUploadStatus == ImageUploadStatus.compressing;

  /// 이미지 업로드 중인지 확인 (Firebase Storage)
  bool get isImageUploadingToStorage =>
      imageUploadStatus == ImageUploadStatus.uploading;

  /// 이미지 업로드 완료되었는지 확인
  bool get isImageUploadCompleted =>
      imageUploadStatus == ImageUploadStatus.completed;

  /// 이미지 업로드 실패했는지 확인
  bool get isImageUploadFailed => imageUploadStatus == ImageUploadStatus.failed;

  /// 현재 이미지가 로컬 파일인지 확인
  bool get hasLocalImage => originalImagePath != null;

  /// 현재 이미지가 업로드된 네트워크 이미지인지 확인
  bool get hasUploadedImage =>
      imageUrl != null &&
      imageUrl!.startsWith('http') &&
      !imageUrl!.startsWith('file://');

  /// 업로드 진행률 백분율 (0 ~ 100)
  int get uploadProgressPercent => (uploadProgress * 100).round();

  /// 이미지 업로드 상태 메시지
  String get imageUploadStatusMessage {
    switch (imageUploadStatus) {
      case ImageUploadStatus.idle:
        return '';
      case ImageUploadStatus.compressing:
        return '이미지 압축 중...';
      case ImageUploadStatus.uploading:
        return '업로드 중... ($uploadProgressPercent%)';
      case ImageUploadStatus.completed:
        return '업로드 완료!';
      case ImageUploadStatus.failed:
        return '업로드 실패';
    }
  }

  /// 이미지 관련 작업 중인지 확인 (압축, 업로드 등)
  bool get isImageProcessing => isImageUploading || isSubmitting;

  /// 편집 가능한지 확인 (소유자이면서 이미지 처리 중이 아님)
  bool get canEdit => isOwner && !isImageProcessing;

  /// 저장 가능한지 확인 (편집 중이면서 이미지 처리가 완료된 상태)
  bool get canSave =>
      isEditing &&
      !isImageProcessing &&
      name.trim().isNotEmpty &&
      description.trim().isNotEmpty;

  /// 현재 표시할 이미지 URL 또는 경로
  String? get displayImagePath {
    // 업로드된 네트워크 이미지가 있으면 우선
    if (hasUploadedImage) {
      return imageUrl;
    }
    // 로컬 이미지가 있으면 사용
    if (hasLocalImage) {
      return originalImagePath;
    }
    // 기본 imageUrl 사용
    return imageUrl;
  }
}
