import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/edit_intro/domain/repositories/edit_intro_repository.dart';

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(editIntroRepositoryProvider));
});

class UpdateProfileUseCase {
  final EditIntroRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Member> call({
    required String nickname,
    String? intro,
  }) async {
    return _repository.updateProfile(
      nickname: nickname,
      intro: intro,
    );
  }
} 