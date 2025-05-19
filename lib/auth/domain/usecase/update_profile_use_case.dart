// lib/auth/domain/usecase/update_profile_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<AsyncValue<Member>> execute({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    // TODO: AuthRepository에 updateProfile 메서드 추가 필요
    // 현재는 getCurrentUser로 대체하여 임시 처리
    final result = await _repository.getCurrentUser();

    switch (result) {
      case Success(:final data):
        if (data == null) {
          return AsyncError(Exception('로그인된 사용자가 없습니다'), StackTrace.current);
        }

        // 임시로 로컬에서 업데이트된 정보로 Member 생성
        final updatedMember = data.copyWith(
          nickname: nickname,
          description: description ?? data.description,
          position: position ?? data.position,
          skills: skills ?? data.skills,
        );

        return AsyncData(updatedMember);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
