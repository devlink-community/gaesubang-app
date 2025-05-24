import 'dart:io';

import 'package:devlink_mobile_app/auth/domain/usecase/core/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/profile/update_profile_image_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/profile/update_profile_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_action.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_state.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_refresh_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_edit_notifier.g.dart';

@riverpod
class ProfileEditNotifier extends _$ProfileEditNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final UpdateProfileUseCase _updateProfileUseCase;
  late final UpdateProfileImageUseCase _updateProfileImageUseCase;
  late final CheckNicknameAvailabilityUseCase _checkNicknameUseCase;

  @override
  ProfileEditState build() {
    AppLogger.ui('ProfileEditNotifier 초기화 시작');

    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
    _updateProfileImageUseCase = ref.watch(updateProfileImageUseCaseProvider);
    _checkNicknameUseCase = ref.watch(checkNicknameAvailabilityUseCaseProvider);

    AppLogger.logState('프로필 편집 UseCase 초기화', {
      'get_current_user': 'initialized',
      'update_profile': 'initialized',
      'update_profile_image': 'initialized',
      'check_nickname': 'initialized',
    });

    AppLogger.ui('ProfileEditNotifier 초기화 완료');
    return const ProfileEditState();
  }

  Future<void> onAction(ProfileEditAction action) async {
    AppLogger.debug('프로필 편집 액션 처리: ${action.runtimeType}');

    switch (action) {
      case LoadProfile():
        await _loadProfile();
        break;

      case OnChangeNickname(:final nickname):
        AppLogger.debug('닉네임 입력 변경: ${nickname.length}자');
        _updateEditingProfile(
          (profile) => profile.copyWith(nickname: nickname),
        );
        _clearFieldError('nickname');
        break;

      case OnChangeDescription(:final description):
        AppLogger.debug('설명 입력 변경: ${description.length}자');
        _updateEditingProfile(
          (profile) => profile.copyWith(description: description),
        );
        break;

      case OnChangePosition(:final position):
        AppLogger.debug('직책 입력 변경: $position');
        _updateEditingProfile(
          (profile) => profile.copyWith(position: position),
        );
        break;

      case OnChangeSkills(:final skills):
        AppLogger.debug('스킬 입력 변경: ${skills.length}자');
        _updateEditingProfile((profile) => profile.copyWith(skills: skills));
        break;

      case CheckNicknameAvailability(:final nickname):
        AppLogger.ui(
          '수동 닉네임 중복 확인 요청: ${PrivacyMaskUtil.maskNickname(nickname)}',
        );
        await _performNicknameAvailabilityCheck();
        break;

      case PickImage():
        AppLogger.ui('이미지 선택 요청');
        await _pickImage();
        break;

      case OnChangeImage(:final imageFile):
        AppLogger.ui('이미지 변경 요청');
        await _updateProfileImage(imageFile);
        break;

      case ValidateForm():
        AppLogger.debug('폼 유효성 검증 요청');
        _validateForm();
        break;

      case SaveProfile():
        AppLogger.logBanner('프로필 저장 요청');
        await _saveProfile();
        break;

      case ClearErrors():
        AppLogger.debug('에러 초기화 요청');
        _clearErrors();
        break;
    }
  }

  /// 프로필 로드 - 중복 요청 방지 적용
  Future<void> _loadProfile() async {
    AppLogger.logBanner('프로필 편집 데이터 로드 시작');
    final startTime = DateTime.now();

    // 중복 요청 방지를 위한 요청 ID 생성
    final currentRequestId = DateTime.now().microsecondsSinceEpoch;
    AppLogger.logState('프로필 편집 로드 요청', {
      'request_id': currentRequestId,
      'load_type': 'profile_edit',
    });

    AppLogger.logStep(1, 3, '로딩 상태 설정 및 요청 ID 저장');
    state = state.copyWith(
      profileState: const AsyncLoading(),
      activeLoadRequestId: currentRequestId,
    );

    try {
      AppLogger.logStep(2, 3, '현재 사용자 정보 조회');
      final result = await _getCurrentUserUseCase.execute();

      // 다른 요청이 이미 시작됐다면 무시
      if (state.activeLoadRequestId != currentRequestId) {
        AppLogger.warning(
          '다른 프로필 편집 로드 요청이 진행 중이므로 현재 요청 무시',
          error:
              'RequestID: $currentRequestId vs Current: ${state.activeLoadRequestId}',
        );
        return;
      }

      AppLogger.logStep(3, 3, '프로필 편집 데이터 처리');
      if (result case AsyncData(:final value)) {
        AppLogger.ui('프로필 편집 데이터 로드 성공');
        AppLogger.logState('로드된 프로필 편집 정보', {
          'user_id': PrivacyMaskUtil.maskUserId(value.uid),
          'nickname': PrivacyMaskUtil.maskNickname(value.nickname),
          'description_length': value.description.length,
          'position': value.position,
          'skills_length': value.skills?.length ?? 0,
          'has_image': value.image.isNotEmpty,
        });

        state = state.copyWith(
          profileState: AsyncData(value),
          editingProfile: value,
          originalProfile: value, // 원본 참조 저장
          activeLoadRequestId: null, // 요청 완료 후 ID 초기화
        );

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('프로필 편집 데이터 로드', duration);
        AppLogger.logBox(
          '프로필 편집 로드 완료',
          '사용자: ${PrivacyMaskUtil.maskNickname(value.nickname)}\n소요시간: ${duration.inMilliseconds}ms',
        );
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        AppLogger.error(
          '프로필 편집 데이터 로드 실패',
          error: error,
          stackTrace: stackTrace,
        );
        state = state.copyWith(
          profileState: AsyncError(error, stackTrace),
          activeLoadRequestId: null, // 에러 발생 후 ID 초기화
        );
      }
    } catch (e, st) {
      AppLogger.error('프로필 편집 데이터 로드 중 예외 발생', error: e, stackTrace: st);
      // 요청 ID가 여전히 유효한지 확인
      if (state.activeLoadRequestId == currentRequestId) {
        state = state.copyWith(
          profileState: AsyncError(e, st),
          activeLoadRequestId: null,
        );
      }
    }
  }

  /// 편집 중인 프로필 업데이트
  void _updateEditingProfile(Function(dynamic) updater) {
    final currentProfile = state.editingProfile;
    if (currentProfile != null) {
      final updatedProfile = updater(currentProfile);
      state = state.copyWith(editingProfile: updatedProfile);
      AppLogger.debug('편집 중인 프로필 업데이트됨');
    }
  }

  /// 특정 필드 에러 제거
  void _clearFieldError(String field) {
    final updatedErrors = Map<String, String>.from(state.validationErrors);
    updatedErrors.remove(field);
    state = state.copyWith(validationErrors: updatedErrors);
    AppLogger.debug('필드 에러 제거: $field');
  }

  /// 모든 에러 초기화
  void _clearErrors() {
    state = state.copyWith(
      validationErrors: {},
      saveState: const AsyncData(null),
      nicknameCheckState: const AsyncData(null),
    );
    AppLogger.debug('모든 에러 초기화 완료');
  }

  /// 닉네임 중복 확인
  Future<void> _performNicknameAvailabilityCheck() async {
    AppLogger.logStep(1, 4, '닉네임 중복 확인 시작');
    final startTime = DateTime.now();

    final nickname = state.editingProfile?.nickname ?? '';
    AppLogger.logState('닉네임 중복 확인 요청', {
      'nickname': PrivacyMaskUtil.maskNickname(nickname),
      'nickname_length': nickname.length,
    });

    // 원본 닉네임과 같으면 중복 확인하지 않음
    if (state.originalProfile?.nickname == nickname) {
      AppLogger.logStep(2, 4, '기존 닉네임과 동일 - 중복 확인 생략');
      state = state.copyWith(nicknameCheckState: const AsyncData(true));
      AppLogger.debug('기존 닉네임과 동일하므로 중복 확인 생략');
      return;
    }

    AppLogger.logStep(3, 4, '닉네임 중복 확인 API 호출');
    state = state.copyWith(nicknameCheckState: const AsyncLoading());

    try {
      final result = await _checkNicknameUseCase.execute(nickname);

      AppLogger.logStep(4, 4, '닉네임 중복 확인 결과 처리');
      if (result case AsyncData(:final value)) {
        state = state.copyWith(nicknameCheckState: AsyncData(value));

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('닉네임 중복 확인', duration);

        AppLogger.logState('닉네임 중복 확인 결과', {
          'nickname': PrivacyMaskUtil.maskNickname(nickname),
          'is_available': value,
          'duration_ms': duration.inMilliseconds,
        });

        // 닉네임이 중복이면 에러 메시지 추가
        if (!value) {
          final updatedErrors = Map<String, String>.from(
            state.validationErrors,
          );
          updatedErrors['nickname'] = '이미 사용 중인 닉네임입니다';
          state = state.copyWith(validationErrors: updatedErrors);
          AppLogger.warning('닉네임 중복 확인: 이미 사용 중');
        } else {
          AppLogger.ui('닉네임 중복 확인: 사용 가능');
        }
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        AppLogger.error('닉네임 중복 확인 실패', error: error, stackTrace: stackTrace);
        state = state.copyWith(
          nicknameCheckState: AsyncError(error, stackTrace),
        );
      }
    } catch (e, st) {
      AppLogger.error('닉네임 중복 확인 중 예외 발생', error: e, stackTrace: st);
      state = state.copyWith(nicknameCheckState: AsyncError(e, st));
    }
  }

  /// 이미지 선택
  Future<void> _pickImage() async {
    AppLogger.debug('이미지 선택 시작');
    final startTime = DateTime.now();

    try {
      final ImagePicker picker = ImagePicker();

      AppLogger.logState('이미지 선택 설정', {
        'max_width': 1024,
        'max_height': 1024,
        'image_quality': 80,
        'source': 'gallery',
      });

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('이미지 선택', duration);

      if (image != null) {
        AppLogger.ui('이미지 선택 완료');
        AppLogger.logState('선택된 이미지 정보', {
          'path_length': image.path.length,
          'has_path': image.path.isNotEmpty,
          'selection_time_ms': duration.inMilliseconds,
        });

        await _updateProfileImage(File(image.path));
      } else {
        AppLogger.debug('이미지 선택 취소됨');
      }
    } catch (e, st) {
      AppLogger.error('이미지 선택 실패', error: e, stackTrace: st);
    }
  }

  /// 프로필 이미지 업데이트 - 중복 요청 방지 적용
  Future<void> _updateProfileImage(File imageFile) async {
    AppLogger.logBanner('프로필 이미지 업데이트 시작');
    final startTime = DateTime.now();

    final currentProfile = state.editingProfile;
    if (currentProfile == null) {
      AppLogger.error('편집 중인 프로필이 없어 이미지 업데이트 불가');
      return;
    }

    // 중복 요청 방지를 위한 요청 ID 생성
    final currentRequestId = DateTime.now().microsecondsSinceEpoch;
    AppLogger.logState('프로필 이미지 업데이트 요청', {
      'request_id': currentRequestId,
      'image_path_length': imageFile.path.length,
      'file_exists': await imageFile.exists(),
    });

    try {
      AppLogger.logStep(1, 4, '즉시 로컬 이미지 반영 및 업로드 상태 설정');
      // 1. 업로드 시작 상태로 변경 + 즉시 로컬 이미지 반영
      final updatedProfile = currentProfile.copyWith(image: imageFile.path);
      state = state.copyWith(
        editingProfile: updatedProfile,
        isImageUploading: true, // 명시적 업로드 상태 설정
        activeImageUploadRequestId: currentRequestId,
      );
      AppLogger.ui('로컬 이미지 즉시 반영 완료 - 업로드 시작');

      AppLogger.logStep(2, 4, '백그라운드 이미지 업로드 진행');
      // 2. 백그라운드에서 실제 이미지 업로드 진행
      final result = await _updateProfileImageUseCase.execute(imageFile.path);

      // 다른 이미지 업로드 요청이 시작됐다면 무시
      if (state.activeImageUploadRequestId != currentRequestId) {
        AppLogger.warning(
          '다른 이미지 업로드 요청이 진행 중이므로 현재 요청 무시',
          error:
              'RequestID: $currentRequestId vs Current: ${state.activeImageUploadRequestId}',
        );
        return;
      }

      AppLogger.logStep(3, 4, '이미지 업로드 결과 처리');
      if (result case AsyncData(:final value)) {
        // 업로드 성공 - 서버 이미지 URL로 업데이트
        state = state.copyWith(
          profileState: AsyncData(value),
          editingProfile: value,
          originalProfile: value, // 새로운 원본으로 업데이트
          isImageUploading: false, // 업로드 완료
          activeImageUploadRequestId: null, // 요청 완료 후 ID 초기화
        );

        AppLogger.logStep(4, 4, '프로필 갱신 상태 마크');
        // 프로필 갱신 상태 마크
        ref.read(profileRefreshStateProvider.notifier).markForRefresh();

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('프로필 이미지 업데이트', duration);
        AppLogger.logBox(
          '프로필 이미지 업데이트 성공',
          '사용자: ${PrivacyMaskUtil.maskNickname(value.nickname)}\n소요시간: ${duration.inSeconds}초',
        );
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        AppLogger.error('이미지 업로드 실패', error: error, stackTrace: stackTrace);

        // 실패 시 원본 이미지로 되돌리기 (originalProfile 사용)
        final originalProfile = state.originalProfile;
        if (originalProfile != null) {
          state = state.copyWith(
            editingProfile: originalProfile.copyWith(
              // 다른 편집 내용은 유지하되, 이미지만 원본으로 복원
              nickname: state.editingProfile!.nickname,
              description: state.editingProfile!.description,
              position: state.editingProfile!.position,
              skills: state.editingProfile!.skills,
            ),
            isImageUploading: false,
            activeImageUploadRequestId: null,
            saveState: AsyncError(error, stackTrace),
          );
          AppLogger.warning('이미지 업로드 실패로 원본 이미지로 복원');
        }
      }
    } catch (e, st) {
      AppLogger.error('이미지 업데이트 예외', error: e, stackTrace: st);

      // 요청 ID가 여전히 유효한지 확인
      if (state.activeImageUploadRequestId == currentRequestId) {
        // 예외 발생 시 원본 이미지로 되돌리기
        final originalProfile = state.originalProfile;
        if (originalProfile != null) {
          state = state.copyWith(
            editingProfile: originalProfile.copyWith(
              // 다른 편집 내용은 유지하되, 이미지만 원본으로 복원
              nickname: state.editingProfile!.nickname,
              description: state.editingProfile!.description,
              position: state.editingProfile!.position,
              skills: state.editingProfile!.skills,
            ),
            isImageUploading: false,
            activeImageUploadRequestId: null,
            saveState: AsyncError(e, st),
          );
          AppLogger.warning('이미지 업데이트 예외로 원본 이미지로 복원');
        }
      }
    }
  }

  /// 폼 검증
  void _validateForm() {
    AppLogger.logStep(1, 3, '폼 검증 시작');

    final profile = state.editingProfile;
    if (profile == null) {
      AppLogger.error('프로필이 null이므로 검증 불가');
      return;
    }

    AppLogger.logStep(2, 3, '필드별 유효성 검증');
    final Map<String, String> errors = {};

    // 닉네임 검증
    final nicknameError = AuthValidator.validateNickname(profile.nickname);
    if (nicknameError != null) {
      errors['nickname'] = nicknameError;
    }

    // 닉네임 중복 확인 여부 검증 (원본과 비교)
    if (state.isNicknameChanged) {
      // 닉네임이 변경된 경우에만 중복 확인 필요
      if (state.nicknameCheckState case AsyncData(:final value)) {
        final isAvailable = value;
        if (isAvailable == false) {
          errors['nickname'] = '이미 사용 중인 닉네임입니다';
        }
      } else {
        // 중복 확인을 아직 하지 않은 경우
        errors['nickname'] = '닉네임 중복 확인이 필요합니다';
      }
    }

    AppLogger.logStep(3, 3, '폼 검증 결과 처리');
    state = state.copyWith(validationErrors: errors);

    if (errors.isNotEmpty) {
      AppLogger.warning('폼 검증 실패');
      AppLogger.logState('검증 실패 필드', {
        'error_count': errors.length,
        'error_fields': errors.keys.toList(),
      });
    } else {
      AppLogger.ui('폼 검증 통과');
    }
  }

  /// 프로필 저장 - 중복 요청 방지 적용
  Future<void> _saveProfile() async {
    AppLogger.logBanner('프로필 저장 시작');
    final startTime = DateTime.now();

    final profile = state.editingProfile;
    if (profile == null) {
      AppLogger.error('프로필이 null이므로 저장 불가');
      return;
    }

    // 이미지 업로드 중이면 저장 불가
    if (state.isImageUploading) {
      AppLogger.warning('이미지 업로드 중이므로 저장 불가');
      state = state.copyWith(
        saveState: AsyncError(
          '이미지 업로드가 완료될 때까지 기다려주세요',
          StackTrace.current,
        ),
      );
      return;
    }

    AppLogger.logStep(1, 5, '저장 전 폼 검증');
    // 저장 전 폼 검증
    _validateForm();
    if (state.hasValidationErrors) {
      AppLogger.warning('폼 검증 실패로 저장 중단');
      return;
    }

    // 중복 요청 방지를 위한 요청 ID 생성
    final currentRequestId = DateTime.now().microsecondsSinceEpoch;
    AppLogger.logState('프로필 저장 요청', {
      'request_id': currentRequestId,
      'nickname': PrivacyMaskUtil.maskNickname(profile.nickname),
      'description_length': profile.description.length,
      'position': profile.position,
      'skills_length': profile.skills?.length ?? 0,
    });

    AppLogger.logStep(2, 5, '저장 상태 설정');
    state = state.copyWith(
      saveState: const AsyncLoading(),
      activeSaveRequestId: currentRequestId,
    );

    try {
      AppLogger.logStep(3, 5, '프로필 업데이트 API 호출');
      final result = await _updateProfileUseCase.execute(
        nickname: profile.nickname,
        description: profile.description,
        position: profile.position,
        skills: profile.skills,
      );

      // 다른 저장 요청이 시작됐다면 무시
      if (state.activeSaveRequestId != currentRequestId) {
        AppLogger.warning(
          '다른 프로필 저장 요청이 진행 중이므로 현재 요청 무시',
          error:
              'RequestID: $currentRequestId vs Current: ${state.activeSaveRequestId}',
        );
        return;
      }

      AppLogger.logStep(4, 5, '프로필 저장 결과 처리');
      if (result case AsyncData(:final value)) {
        state = state.copyWith(
          saveState: const AsyncData(true),
          profileState: AsyncData(value),
          editingProfile: value,
          originalProfile: value, // 새로운 원본으로 업데이트
          activeSaveRequestId: null, // 요청 완료 후 ID 초기화
        );

        AppLogger.logStep(5, 5, '프로필 갱신 상태 마크');
        // 프로필 저장 성공 시 프로필 갱신 상태 마크
        ref.read(profileRefreshStateProvider.notifier).markForRefresh();

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('프로필 저장', duration);
        AppLogger.logBox(
          '프로필 저장 성공',
          '사용자: ${PrivacyMaskUtil.maskNickname(value.nickname)}\n소요시간: ${duration.inSeconds}초',
        );
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        state = state.copyWith(
          saveState: AsyncError(error, stackTrace),
          activeSaveRequestId: null,
        );
        AppLogger.error('프로필 저장 실패', error: error, stackTrace: stackTrace);
      }
    } catch (e, st) {
      // 요청 ID가 여전히 유효한지 확인
      if (state.activeSaveRequestId == currentRequestId) {
        state = state.copyWith(
          saveState: AsyncError(e, st),
          activeSaveRequestId: null,
        );
      }
      AppLogger.error('프로필 저장 예외', error: e, stackTrace: st);
    }
  }

  /// 편의 메서드: 프로필 로드 (외부에서 호출 가능)
  Future<void> loadProfile() async {
    await onAction(const ProfileEditAction.loadProfile());
  }
}
