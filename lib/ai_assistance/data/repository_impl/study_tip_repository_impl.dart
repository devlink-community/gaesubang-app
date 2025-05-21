// lib/ai_assistance/data/repository_impl/study_tip_repository_impl.dart

import '../../../core/result/result.dart';
import '../../domain/model/study_tip.dart';
import '../../domain/repository/study_tip_repository.dart';
import '../data_source/study_tip_data_source.dart';
import '../dto/study_tip_dto.dart';
import '../mapper/study_tip_mapper.dart';

class StudyTipRepositoryImpl implements StudyTipRepository {
  final StudyTipDataSource _dataSource;

  StudyTipRepositoryImpl({required StudyTipDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Result<StudyTip>> generateStudyTip(String skillArea) async {
    try {
      // DataSource의 generateStudyTipBySkill 메서드 직접 호출
      final response = await _dataSource.generateStudyTipBySkill(skillArea);

      // DTO로 변환
      final studyTipDto = StudyTipDto.fromJson(response);

      // 모델로 변환
      return Result.success(studyTipDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}