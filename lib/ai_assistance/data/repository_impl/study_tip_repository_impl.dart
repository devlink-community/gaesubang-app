// lib/ai_assistance/data/repository_impl/study_tip_repository_impl.dart

import '../../../core/result/result.dart';
import '../../domain/model/study_tip.dart';
import '../../domain/repository/study_tip_repository.dart';
import '../../module/quiz_prompt.dart';
import '../data_source/study_tip_data_source.dart';
import '../dto/study_tip_dto.dart';
import '../mapper/study_tip_mapper.dart';

class StudyTipRepositoryImpl implements StudyTipRepository {
  final StudyTipDataSource _dataSource;
  final PromptService _promptService;

  StudyTipRepositoryImpl({
    required StudyTipDataSource dataSource,
    required PromptService promptService,
  }) : _dataSource = dataSource,
       _promptService = promptService;

  @override
  Future<Result<StudyTip>> generateStudyTip(String skillArea) async {
    try {
      // PromptService를 사용하여 프롬프트 생성
      final prompt = _promptService.createStudyTipPrompt(skillArea);

      // 데이터소스를 통한 API 호출
      final response = await _dataSource.generateStudyTipWithPrompt(prompt);

      // DTO로 변환
      final studyTipDto = StudyTipDto.fromJson(response);

      // 모델로 변환
      return Result.success(studyTipDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
