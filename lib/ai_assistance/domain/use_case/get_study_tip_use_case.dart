// lib/ai_assistance/domain/use_case/get_study_tip_use_case.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/study_tip.dart';
import '../repository/study_tip_repository.dart';

class GetStudyTipUseCase {
  final StudyTipRepository _repository;

  GetStudyTipUseCase({required StudyTipRepository repository})
      : _repository = repository;

  Future<AsyncValue<StudyTip>> execute(String skillArea) async {
    final result = await _repository.generateStudyTip(skillArea);

    return switch (result) {
      Success(data: final data) => AsyncData(data),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}