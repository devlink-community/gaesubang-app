import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devlink_mobile_app/edit_intro/domain/usecase/get_current_profile_usecase.dart';
import 'package:devlink_mobile_app/edit_intro/domain/usecase/update_profile_usecase.dart';
import 'package:devlink_mobile_app/edit_intro/domain/usecase/update_profile_image_usecase.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/states/edit_intro_state.dart';

final editIntroProvider =
    StateNotifierProvider<EditIntroNotifier, EditIntroState>((ref) {
      return EditIntroNotifier(
        ref.watch(getCurrentProfileUseCaseProvider),
        ref.watch(updateProfileUseCaseProvider),
        ref.watch(updateProfileImageUseCaseProvider),
      );
    });

class EditIntroNotifier extends StateNotifier<EditIntroState> {
  final GetCurrentProfileUseCase _getCurrentProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UpdateProfileImageUseCase _updateProfileImageUseCase;

  EditIntroNotifier(
    this._getCurrentProfileUseCase,
    this._updateProfileUseCase,
    this._updateProfileImageUseCase,
  ) : super(const EditIntroState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final member = await _getCurrentProfileUseCase();
      state = state.copyWith(isLoading: false, isSuccess: true, member: member);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 불러올 수 없습니다.',
      );
    }
  }

  Future<void> updateProfileImage(XFile image) async {
    state = state.copyWith(
      isImageUploading: true,
      isImageUploadError: false,
      imageUploadErrorMessage: null,
    );

    try {
      final updatedMember = await _updateProfileImageUseCase(image);
      state = state.copyWith(
        isImageUploading: false,
        isImageUploadSuccess: true,
        member: updatedMember,
      );
    } catch (e) {
      state = state.copyWith(
        isImageUploading: false,
        isImageUploadError: true,
        imageUploadErrorMessage: '프로필 이미지를 업데이트할 수 없습니다.',
      );
    }
  }

  Future<bool> updateProfile({required String nickname, String? intro}) async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final updatedMember = await _updateProfileUseCase(
        nickname: nickname,
        intro: intro,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        member: updatedMember,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 수정할 수 없습니다.',
      );
      return false;
    }
  }
}
