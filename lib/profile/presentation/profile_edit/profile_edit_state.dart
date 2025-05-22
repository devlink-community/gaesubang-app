import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'profile_edit_state.freezed.dart';

@freezed
class ProfileEditState with _$ProfileEditState {
  const ProfileEditState({
    /// 프로필 정보 상태 (로딩/성공/실패)
    this.profileState = const AsyncLoading(),

    /// 프로필 저장 상태 (로딩/성공/실패)
    this.saveState = const AsyncData(null),

    /// 닉네임 중복 확인 상태
    this.nicknameCheckState = const AsyncData(null),

    /// 현재 편집 중인 프로필 정보 (로컬 상태)
    this.editingProfile,

    /// 폼 검증 에러 메시지들
    this.validationErrors = const {},

    /// 이미지 업로드 상태 - 명시적 관리
    this.isImageUploading = false,

    /// 에러 발생 시 복원할 원본 프로필 (불변 참조)
    this.originalProfile,
  });

  /// 프로필 로드 상태
  final AsyncValue<Member> profileState;

  /// 저장 작업 상태 (null = 저장 안함, true = 저장 성공)
  final AsyncValue<bool?> saveState;

  /// 닉네임 중복 확인 상태 (null = 확인 안함, true = 사용 가능, false = 중복)
  final AsyncValue<bool?> nicknameCheckState;

  /// 편집 중인 프로필 정보
  final Member? editingProfile;

  /// 폼 필드별 검증 에러 메시지
  final Map<String, String> validationErrors;

  /// 이미지 업로드 진행 상태
  final bool isImageUploading;

  /// 원본 프로필 (에러 발생 시 복원용)
  final Member? originalProfile;

  /// 편의 getter들
  bool get isLoading => profileState.isLoading;
  bool get isSaving => saveState.isLoading;
  bool get isCheckingNickname => nicknameCheckState.isLoading;
  bool get hasValidationErrors => validationErrors.isNotEmpty;
  String? get saveError =>
      saveState.hasError ? saveState.error.toString() : null;

  /// 편집된 내용이 있는지 확인
  bool get hasChanges {
    if (originalProfile == null || editingProfile == null) return false;

    return originalProfile!.nickname != editingProfile!.nickname ||
        originalProfile!.description != editingProfile!.description ||
        originalProfile!.position != editingProfile!.position ||
        originalProfile!.skills != editingProfile!.skills ||
        originalProfile!.image != editingProfile!.image;
  }

  /// 닉네임이 변경되었는지 확인
  bool get isNicknameChanged {
    if (originalProfile == null || editingProfile == null) return false;
    return originalProfile!.nickname != editingProfile!.nickname;
  }
}
