import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../repository/profile_setting_repository.dart';

class UpdateProfileUseCase {
  final ProfileSettingRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<AsyncValue<Member>> execute({
    required String nickname,
    String? intro,
    String? position, // position 매개변수 추가
    String? skills, // skills 매개변수 추가
  }) async {
    final result = await _repository.updateProfile(
      nickname: nickname,
      intro: intro,
      position: position, // position 전달
      skills: skills, // skills 전달
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
