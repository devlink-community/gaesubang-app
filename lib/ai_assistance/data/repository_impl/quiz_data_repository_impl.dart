import '../../../core/result/result.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../data_source/quiz_data_source.dart';
import '../dto/quiz_dto.dart';
import '../mapper/quiz_mapper.dart';

class QuizRepositoryImpl implements QuizRepository {
  final VertexAiDataSource _dataSource;

  QuizRepositoryImpl({required VertexAiDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<Quiz>> generateQuiz(String skillArea) async {
    try {
      final prompt = _buildPrompt(skillArea);
      final response = await _dataSource.generateQuizWithPrompt(prompt);

      // DTO로 변환
      final quizDto = QuizDto.fromJson(response);

      // 모델로 변환
      return Result.success(quizDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  String _buildPrompt(String skillArea) {
    final targetSkill = skillArea.isEmpty ? '컴퓨터 기초' : skillArea;

    return '''
당신은 프로그래밍 퀴즈 전문가입니다. 다음 지식 영역에 관한 간단한 객관식 퀴즈 문제를 생성해주세요: $targetSkill

- 문제는 초급 수준으로, 해당 영역을 배우는 사람이 풀 수 있는 난이도여야 합니다.
- 4개의 객관식 보기를 제공해주세요.
- 정답과 짧은 설명도 함께 제공해주세요.

결과는 반드시 다음 JSON 형식으로 제공해야 합니다:
{
  "question": "문제 내용",
  "options": ["보기1", "보기2", "보기3", "보기4"],
  "answer": "정답(보기 중 하나와 정확히 일치해야 함)",
  "explanation": "간략한 설명",
  "skillArea": "$targetSkill"
}

직접적인 설명 없이 JSON 형식으로만 응답해주세요.
''';
  }
}
