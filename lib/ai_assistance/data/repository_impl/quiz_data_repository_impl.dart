import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/result/result.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../data_source/quiz_data_source.dart';
import '../dto/quiz_dto.dart';
import '../mapper/quiz_mapper.dart';

class QuizRepositoryImpl implements QuizRepository {
  final VertexAiDataSource _dataSource;
  final Random _random = Random();

  // 기술별 키워드 맵 - 관련성 검사에 사용
  final Map<String, List<String>> _skillKeywords = {
    'flutter': [
      'flutter',
      'dart',
      'widget',
      'stateful',
      'stateless',
      'build',
      'material',
      'cupertino',
      'scaffold',
      'navigator',
      'route',
    ],
    'javascript': [
      'javascript',
      'js',
      'promise',
      'async',
      'await',
      'function',
      'var',
      'let',
      'const',
      'es6',
      'dom',
    ],
    'python': [
      'python',
      'def',
      'list',
      'dict',
      'tuple',
      'pep8',
      'django',
      'flask',
      'numpy',
      'pandas',
    ],
    'react': [
      'react',
      'jsx',
      'component',
      'hook',
      'usestate',
      'useeffect',
      'props',
      'redux',
    ],
    'html': [
      'html',
      'tag',
      'element',
      'doctype',
      'head',
      'body',
      'div',
      'span',
      'semantic',
      'attribute',
    ],
    'css': [
      'css',
      'selector',
      'style',
      'flexbox',
      'grid',
      'media',
      'query',
      'property',
      'value',
      'animation',
    ],
    'sql': [
      'sql',
      'database',
      'query',
      'select',
      'insert',
      'update',
      'delete',
      'join',
      'table',
      'column',
    ],
    'java': [
      'java',
      'class',
      'object',
      'interface',
      'extends',
      'implements',
      'override',
      'public',
      'private',
    ],
    'kotlin': [
      'kotlin',
      'val',
      'var',
      'fun',
      'class',
      'coroutine',
      'extension',
      'null',
      'safety',
    ],
    'swift': [
      'swift',
      'optional',
      'struct',
      'enum',
      'protocol',
      'extension',
      'guard',
      'let',
      'var',
    ],
    'go': [
      'go',
      'golang',
      'goroutine',
      'channel',
      'struct',
      'interface',
      'error',
      'slice',
      'map',
      'pointer',
    ],
    'rust': [
      'rust',
      'ownership',
      'borrowing',
      'lifetime',
      'trait',
      'struct',
      'enum',
      'match',
      'result',
      'option',
    ],
    'c#': [
      'c#',
      'csharp',
      '.net',
      'class',
      'async',
      'await',
      'linq',
      'wpf',
      'xaml',
      'delegate',
    ],
    'typescript': [
      'typescript',
      'ts',
      'interface',
      'type',
      'enum',
      'generic',
      'union',
      'intersection',
      'utility',
      'any',
    ],
    'vue': [
      'vue',
      'component',
      'template',
      'directive',
      'v-if',
      'v-for',
      'v-model',
      'vuex',
      'lifecycle',
      'prop',
    ],
    'angular': [
      'angular',
      'component',
      'directive',
      'service',
      'dependency',
      'injection',
      'module',
      'pipe',
      'observable',
    ],
    'node': [
      'node',
      'nodejs',
      'express',
      'npm',
      'package',
      'module',
      'require',
      'import',
      'middleware',
      'route',
    ],
    'php': [
      'php',
      'array',
      'function',
      'class',
      'echo',
      'print',
      'laravel',
      'symfony',
      'composer',
      'namespace',
    ],
    'ruby': [
      'ruby',
      'rails',
      'gem',
      'block',
      'module',
      'class',
      'method',
      'hash',
      'symbol',
      'irb',
    ],
    'c++': [
      'c++',
      'class',
      'template',
      'stl',
      'vector',
      'pointer',
      'reference',
      'inheritance',
      'polymorphism',
    ],
    'blockchain': [
      'blockchain',
      'bitcoin',
      'ethereum',
      'smart',
      'contract',
      'token',
      'wallet',
      'hash',
      'block',
      'transaction',
    ],
    'machine learning': [
      'ml',
      'machine',
      'learning',
      'algorithm',
      'model',
      'training',
      'classification',
      'regression',
      'neural',
      'network',
    ],
    'ai': [
      'artificial',
      'intelligence',
      'ml',
      'deep',
      'learning',
      'neural',
      'network',
      'nlp',
      'computer',
      'vision',
    ],
  };

  QuizRepositoryImpl({required VertexAiDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<Quiz>> generateQuiz(String skillArea) async {
    try {
      // 스킬 영역 정제
      final cleanedSkill = _sanitizeSkillArea(skillArea);
      debugPrint('QuizRepositoryImpl - 정제된 스킬: $cleanedSkill');

      // API 호출 실패 횟수 (재시도 용)
      int retryCount = 0;

      // 최대 5번까지 시도
      while (retryCount < 5) {
        try {
          debugPrint('AI 퀴즈 생성 시도 ${retryCount + 1}/5');

          // 프롬프트 생성 및 API la
          final prompt = _buildPrompt(cleanedSkill, retryCount);
          final response = await _dataSource.generateQuizWithPrompt(prompt);

          // DTO로 변환
          final quizDto = QuizDto.fromJson(response);

          // 검증: 필수 필드 확인
          if (quizDto.question == null ||
              quizDto.options == null ||
              quizDto.options!.isEmpty ||
              quizDto.explanation == null) {
            debugPrint('생성된 퀴즈가 불완전합니다. 재시도합니다.');
            retryCount++;
            continue;
          }

          // correctOptionIndex 확인 및 수정
          final correctIndex = _validateCorrectOptionIndex(
            quizDto.correctOptionIndex ?? 0,
            quizDto.options?.length ?? 4,
          );

          // 관련성 검사
          final normalizedSkill = cleanedSkill.toLowerCase();
          final normalizedQuestion = quizDto.question!.toLowerCase();

          // 기본 관련성 확인 - 스킬명이 질문에 포함됨
          bool isRelevant = normalizedQuestion.contains(normalizedSkill);

          // 관련 키워드 검사
          if (!isRelevant && _skillKeywords.containsKey(normalizedSkill)) {
            final keywords = _skillKeywords[normalizedSkill]!;
            isRelevant = keywords.any(
              (keyword) => normalizedQuestion.contains(keyword),
            );
          }

          // 관련성 없는 경우 재시도
          if (!isRelevant) {
            debugPrint('생성된 퀴즈가 $cleanedSkill 기술과 관련이 없습니다. 재시도합니다.');
            retryCount++;
            continue;
          }

          // 추가 검증 - 비정상적인 답변 옵션 체크
          bool hasInvalidOptions =
              quizDto.options?.any(
                (option) =>
                    option == null || option.isEmpty || option.length < 2,
              ) ??
              false;

          if (hasInvalidOptions) {
            debugPrint('생성된 퀴즈에 비정상적인 옵션이 있습니다. 재시도합니다.');
            retryCount++;
            continue;
          }

          // 보정된 DTO 생성
          final updatedDto = quizDto.copyWith(
            correctOptionIndex: correctIndex,
            // 스킬명의 첫 글자를 대문자로 변경
            skillArea:
                cleanedSkill.substring(0, 1).toUpperCase() +
                cleanedSkill.substring(1),
          );

          // 모델로 변환
          final result = updatedDto.toModel();
          debugPrint(
            '퀴즈 생성 완료: ${result.question.substring(0, min(30, result.question.length))}...',
          );

          return Result.success(result);
        } catch (innerError) {
          debugPrint('퀴즈 생성 중 오류 발생 (시도 ${retryCount + 1}/5): $innerError');
          retryCount++;
        }
      }

      // 모든 시도가 실패한 경우 맞춤형 퀴즈 생성
      debugPrint('AI 퀴즈 생성 모두 실패. 최후의 시도를 합니다.');

      // 최후의 시도 - 이미 정의된 문자열을 기반으로 퀴즈 생성
      final fallbackQuiz = _generateFallbackQuiz(cleanedSkill);
      return Result.success(fallbackQuiz);
    } catch (e, st) {
      debugPrint('QuizRepositoryImpl - 퀴즈 생성 실패: $e');
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  String _buildPrompt(String skillArea, int retryCount) {
    final targetSkill = skillArea.isEmpty ? 'Flutter' : skillArea;
    final cleanSkill = _cleanSkillArea(targetSkill);
    final uniqueId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(10000);

    // 재시도 횟수에 따라 프롬프트 강화
    final emphasisLevel =
        retryCount > 2
            ? "!!!"
            : retryCount > 0
            ? "!!"
            : "!";

    // 프롬프트 개선
    return '''
당신은 프로그래밍 퀴즈 전문가입니다. $emphasisLevel 다음 조건을 정확히 따라 '${cleanSkill}'에 관한 프로그래밍 퀴즈를 생성해주세요. $emphasisLevel

중요한 규칙 $emphasisLevel:
1. 퀴즈는 반드시 '${cleanSkill}' 기술에 대한 것이어야 합니다. $emphasisLevel
2. 다른 프로그래밍 언어나, 한국어 문법, 일반 상식 등 관련 없는 주제의 퀴즈를 만들지 마세요.
3. 답변 옵션은 합리적이고 기술적으로 관련 있어야 합니다.
4. 질문에 '${cleanSkill}'라는 단어를 명시적으로 포함시키세요.

예시 형식:
```json
{
  "question": "${cleanSkill}에서 [기술적 질문]",
  "options": [
    "[정답]",
    "[오답1]",
    "[오답2]",
    "[오답3]"
  ],
  "correctOptionIndex": 0,
  "explanation": "[정답에 대한 자세한 설명]",
  "relatedSkill": "${cleanSkill}"
}
퀴즈 ID: ${uniqueId} (재시도: ${retryCount + 1})
$emphasisLevel 반드시 JSON 형식만 응답해주세요. 다른 텍스트는 포함하지 마세요. $emphasisLevel
''';
  }

  // 매우 기본적인 폴백 퀴즈 생성 (최후의 수단)
  Quiz _generateFallbackQuiz(String skillName) {
    final capitalizedSkill =
        skillName.substring(0, 1).toUpperCase() + skillName.substring(1);
    return Quiz(
      question: "$capitalizedSkill의 주요 특징은 무엇인가요?",
      options: [
        "$capitalizedSkill은 높은 생산성을 제공합니다.",
        "$capitalizedSkill은 주로 모바일 앱 개발에만 사용됩니다.",
        "$capitalizedSkill은 객체 지향 프로그래밍을 지원하지 않습니다.",
        "$capitalizedSkill은 오직 Windows에서만 동작합니다.",
      ],
      explanation:
          "$capitalizedSkill은 다양한 환경에서 사용할 수 있으며, 높은 생산성을 제공하는 것이 주요 특징입니다.",
      correctOptionIndex: 0,
      relatedSkill: capitalizedSkill,
    );
  }

  // 스킬 영역에서 JSON 형식 등 불필요한 요소 제거
  String _sanitizeSkillArea(String skillArea) {
    // JSON 형식이 포함된 경우
    if (skillArea.contains('"') ||
        skillArea.contains(':') ||
        skillArea.contains('{') ||
        skillArea.contains('}')) {
      // 단순한 문자열만 추출
      final regex = RegExp(r'"([^"]+)"');
      final match = regex.firstMatch(skillArea);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? 'Flutter';
      }
      // JSON 형식이 있지만 추출할 수 없는 경우
      return 'Flutter';
    }

    // 타임스탬프 제거
    final cleanSkill = _cleanSkillArea(skillArea);

    // 유효한 스킬 단어인지 확인 (글자 수 제한)
    if (cleanSkill.length > 30 || cleanSkill.length < 2) {
      return 'Flutter';
    }

    return cleanSkill;
  }

  // 스킬 영역에서 타임스탬프 제거
  String _cleanSkillArea(String skillArea) {
    // 타임스탬프가 포함된 경우 (형식: "스킬-12345678901234") 처리
    final timestampSeparatorIndex = skillArea.lastIndexOf('-');
    if (timestampSeparatorIndex > 0) {
      final possibleTimestamp = skillArea.substring(
        timestampSeparatorIndex + 1,
      );
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        return skillArea.substring(0, timestampSeparatorIndex);
      }
    }
    return skillArea;
  }

  // correctOptionIndex 값 검증 및 수정
  int _validateCorrectOptionIndex(int index, int optionsLength) {
    if (optionsLength <= 0) return 0;
    // 범위 확인 (0 <= index < optionsLength)
    if (index < 0 || index >= optionsLength) {
      debugPrint(
        '유효하지 않은 correctOptionIndex 감지: $index, 옵션 개수: $optionsLength',
      );
      return _random.nextInt(optionsLength); // 랜덤한 유효 인덱스 반환
    }

    return index;
  }
}
