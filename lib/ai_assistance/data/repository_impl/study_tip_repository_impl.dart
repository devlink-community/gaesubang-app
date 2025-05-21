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
      final prompt = _buildPrompt(skillArea);
      final response = await _dataSource.generateStudyTipWithPrompt(prompt);

      // DTO로 변환
      final studyTipDto = StudyTipDto.fromJson(response);

      // 모델로 변환
      return Result.success(studyTipDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  String _buildPrompt(String skillArea) {
    final targetSkill = skillArea.isEmpty ? '프로그래밍 기초' : skillArea;

    return '''
    당신은 개발자를 위한 학습 팁 생성 전문가입니다. 다음 기술 분야에 관한 유익한 학습 팁과 영어 한 마디를 생성해주세요: $targetSkill

    팁은 실제 개발자가 해당 기술을 효과적으로 학습하는데 도움이 되는 구체적인 내용이어야 합니다.
    영어 한 마디는 해당 기술 분야에서 자주 사용되는 영어 문장이나 용어와 그 한국어 해석을 포함해야 합니다.

    결과는 반드시 다음 JSON 형식으로 제공해야 합니다:
    {
      "title": "짧은 팁 제목",
      "content": "구체적인 학습 팁 내용 (100자 이상 300자 이하)",
      "relatedSkill": "$targetSkill",
      "englishPhrase": "기술 분야 관련 영어 문장이나 용어",
      "translation": "한국어 해석",
      "source": "선택적 출처 (책, 웹사이트 등)"
    }

    직접적인 설명 없이 JSON 형식으로만 응답해주세요.
    ''';
  }
}