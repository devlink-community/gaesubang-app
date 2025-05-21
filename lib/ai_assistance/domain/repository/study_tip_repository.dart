// lib/ai_assistance/domain/repository/study_tip_repository.dart

import '../../../core/result/result.dart';
import '../model/study_tip.dart';

abstract interface class StudyTipRepository {
  Future<Result<StudyTip>> generateStudyTip(String skillArea);
}