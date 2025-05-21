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
당신은 개발자를 위한 학습 팁 생성 전문가입니다. $targetSkill 분야에 관한 학습 팁과 실무 영어 표현을 생성해주세요.

- 팁: 개발자 학습에 도움되는 구체적 내용 (120-150자)
- 요청할 때 마다 항상 새로운 내용을 제공해야 합니다.
- 영어: 해당 분야 개발자들이 실제 사용하는 표현 (15단어 이내)
- 요청할 때 마다 항상 새로운 내용을 제공해야 합니다. 

결과는 다음 JSON 형식으로 제공:
{
  "title": "짧은 팁 제목",
  "content": "구체적인 학습 팁 내용",
  "relatedSkill": "$targetSkill",
  "englishPhrase": "개발자가 자주 사용하는 영어 표현",
  "translation": "한국어 해석",
  "source": "선택적 출처"
}

JSON 형식으로만 응답해주세요.
'''.trim();
  }
}