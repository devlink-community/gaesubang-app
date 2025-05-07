import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/edit_intro/domain/repositories/edit_intro_repository.dart';

final editIntroUseCaseProvider = Provider<EditIntroUseCase>((ref) {
  return EditIntroUseCase(ref.watch(editIntroRepositoryProvider));
});

class EditIntroUseCase {
  final EditIntroRepository _repository;

  EditIntroUseCase(this._repository);

  Future<Member> getCurrentProfile() async {
    return _repository.getCurrentProfile();
  }

  Future<Member> updateProfile({
    required String nickname,
    String? intro,
  }) async {
    return _repository.updateProfile(
      nickname: nickname,
      intro: intro,
    );
  }

  Future<Member> updateProfileImage(XFile image) async {
    return _repository.updateProfileImage(image);
  }
} 