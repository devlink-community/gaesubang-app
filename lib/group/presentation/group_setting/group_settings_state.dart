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
    // 이미지 업로드 관련 필드들
    this.imageUploadStatus = ImageUploadStatus.idle,
    this.uploadProgress = 0.0,
    this.originalImagePath,
    // 🔧 새로 추가: 멤버 페이지네이션 관련 필드들
    this.currentMemberPage = 0,
    this.memberPageSize = 10,
    this.hasMoreMembers = true,
    this.isLoadingMoreMembers = false,
    this.paginatedMembers = const [],
    this.memberLoadError,
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

  // 이미지 업로드 관련 필드들
  final ImageUploadStatus imageUploadStatus;
  final double uploadProgress; // 0.0 ~ 1.0
  final String? originalImagePath; // 원본 이미지 경로 (로컬)

  // 🔧 새로 추가: 멤버 페이지네이션 관련 필드들
  final int currentMemberPage; // 현재 페이지 (0부터 시작)
  final int memberPageSize; // 페이지당 멤버 수
  final bool hasMoreMembers; // 더 로드할 멤버가 있는지
  final bool isLoadingMoreMembers; // 추가 멤버 로딩 중인지
  final List<GroupMember> paginatedMembers; // 페이지네이션된 멤버 목록
  final String? memberLoadError; // 멤버 로딩 전용 에러 메시지

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

  // 🔧 새로 추가: 멤버 페이지네이션 관련 헬퍼 메서드들

  /// 더 많은 멤버를 로드할 수 있는지 확인
  bool get canLoadMoreMembers => hasMoreMembers && !isLoadingMoreMembers;

  /// 멤버 목록이 로딩 중인지 확인 (초기 로딩 또는 추가 로딩)
  bool get isMemberLoading => members.isLoading || isLoadingMoreMembers;

  /// 표시할 총 멤버 수
  int get totalDisplayedMembers => paginatedMembers.length;

  /// 다음 페이지 번호
  int get nextMemberPage => currentMemberPage + 1;

  /// 멤버 목록에 에러가 있는지 확인
  bool get hasMemberError => memberLoadError != null || members.hasError;

  /// 사용자 친화적인 멤버 에러 메시지 반환
  String? get friendlyMemberErrorMessage {
    if (memberLoadError != null) {
      return memberLoadError;
    }
    if (members.hasError) {
      return _getFriendlyErrorMessage(members.error);
    }
    return null;
  }

  /// 에러 객체를 사용자 친화적인 메시지로 변환
  String _getFriendlyErrorMessage(Object? error) {
    if (error == null) return '알 수 없는 오류가 발생했습니다';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return '인터넷 연결을 확인해주세요';
    }

    if (errorString.contains('timeout')) {
      return '요청 시간이 초과되었습니다. 다시 시도해주세요';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('permission')) {
      return '권한이 없습니다. 다시 로그인해주세요';
    }

    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('503')) {
      return '서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해주세요';
    }

    return '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
  }
}