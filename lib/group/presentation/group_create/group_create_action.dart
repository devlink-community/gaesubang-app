// lib/group/presentation/group_create/group_create_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_create_action.freezed.dart';

@freezed
sealed class GroupCreateAction with _$GroupCreateAction {
  /// 그룹 이름 변경
  const factory GroupCreateAction.nameChanged(String name) = NameChanged;

  /// 그룹 설명 변경
  const factory GroupCreateAction.descriptionChanged(String description) =
      DescriptionChanged;

  /// 최대 멤버 수 변경
  const factory GroupCreateAction.limitMemberCountChanged(int count) =
      LimitMemberCountChanged;

  /// 해시태그 추가
  const factory GroupCreateAction.hashTagAdded(String tag) = HashTagAdded;

  /// 해시태그 제거
  const factory GroupCreateAction.hashTagRemoved(String tag) = HashTagRemoved;

  /// 그룹 이미지 URL 변경
  const factory GroupCreateAction.imageUrlChanged(String? imageUrl) =
      ImageUrlChanged;

  /// 일시정지 제한시간 변경 (분 단위)
  const factory GroupCreateAction.pauseTimeLimitChanged(int minutes) =
      PauseTimeLimitChanged;

  /// 멤버 초대
  const factory GroupCreateAction.memberInvited(String userId) = MemberInvited;

  /// 멤버 초대 취소
  const factory GroupCreateAction.memberRemoved(String userId) = MemberRemoved;

  /// 그룹 생성 제출
  const factory GroupCreateAction.submit() = Submit;

  /// 그룹 생성 취소
  const factory GroupCreateAction.cancel() = Cancel;

  /// 이미지 선택
  const factory GroupCreateAction.selectImage() = SelectImage;

  /// 에러 메시지 초기화
  const factory GroupCreateAction.clearError() = ClearError;

  /// 성공 메시지 초기화
  const factory GroupCreateAction.clearSuccess() = ClearSuccess;

  /// 폼 초기화
  const factory GroupCreateAction.resetForm() = ResetForm;

  /// 실시간 유효성 검사 트리거
  const factory GroupCreateAction.validateForm() = ValidateForm;

  // 🆕 추가: 이미지 업로드 관련 액션들

  /// 이미지 업로드 에러만 초기화
  const factory GroupCreateAction.clearImageUploadError() =
      ClearImageUploadError;

  /// 이미지 업로드 상태 초기화
  const factory GroupCreateAction.resetImageUploadState() =
      ResetImageUploadState;
}
