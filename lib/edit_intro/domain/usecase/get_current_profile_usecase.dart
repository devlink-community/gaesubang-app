import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/edit_intro/domain/repositories/edit_intro_repository.dart';

final getCurrentProfileUseCaseProvider = Provider<GetCurrentProfileUseCase>((ref) {
  return GetCurrentProfileUseCase(ref.watch(editIntroRepositoryProvider));
});

class GetCurrentProfileUseCase {
  final EditIntroRepository _repository;

  GetCurrentProfileUseCase(this._repository);

  Future<Member> call() async {
    return _repository.getCurrentProfile();
  }
} 