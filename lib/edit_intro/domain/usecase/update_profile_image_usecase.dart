import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/edit_intro/domain/repositories/edit_intro_repository.dart';

final updateProfileImageUseCaseProvider = Provider<UpdateProfileImageUseCase>((ref) {
  return UpdateProfileImageUseCase(ref.watch(editIntroRepositoryProvider));
});

class UpdateProfileImageUseCase {
  final EditIntroRepository _repository;

  UpdateProfileImageUseCase(this._repository);

  Future<Member> call(XFile image) async {
    return _repository.updateProfileImage(image);
  }
} 