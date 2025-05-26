import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/result/result.dart';
import '../../../core/utils/app_logger.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../../module/quiz_prompt.dart';
import '../data_source/quiz_data_source.dart';
import '../dto/quiz_dto.dart';
import '../mapper/quiz_mapper.dart';

class QuizRepositoryImpl implements QuizRepository {
  final FirebaseAiDataSource _dataSource;
  final PromptService _promptService;
  final Random _random = Random();

  // 프로그래밍 기술별 키워드 맵 - 관련성 검사에 사용
  final Map<String, List<String>> _programmingSkillKeywords = {
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

  QuizRepositoryImpl({
    required FirebaseAiDataSource dataSource,
    required PromptService promptService,
  }) : _dataSource = dataSource,
       _promptService = promptService;

  @override
  Future<Result<Quiz>> generateQuiz(String skillArea) async {
    final startTime = DateTime.now();

    AppLogger.info(
      'Quiz 생성 시작: $skillArea',
      tag: 'QuizRepository',
    );

    try {
      // 스킬 영역 정제 - PromptService 사용
      final cleanedSkill = _promptService.cleanSkillArea(skillArea);

      AppLogger.info(
        'QuizRepositoryImpl - 정제된 스킬: $cleanedSkill',
        tag: 'QuizRepository',
      );

      // API 호출 실패 횟수 (재시도 용)
      int retryCount = 0;

      // 최대 5번까지 시도
      while (retryCount < 5) {
        try {
          AppLogger.info(
            'Firebase AI 퀴즈 생성 시도 ${retryCount + 1}/5',
            tag: 'QuizGeneration',
          );

          // PromptService를 사용하여 프롬프트 생성
          final prompt = _promptService.createQuizPrompt(cleanedSkill);
          final response = await _dataSource.generateQuizWithPrompt(prompt);

          // DTO로 변환
          final quizDto = QuizDto.fromJson(response);

          // 검증: 필수 필드 확인
          if (quizDto.question == null ||
              quizDto.options == null ||
              quizDto.options!.isEmpty ||
              quizDto.explanation == null) {
            AppLogger.warning(
              '생성된 퀴즈가 불완전합니다. 재시도합니다.',
              tag: 'QuizValidation',
            );

            AppLogger.logState('불완전한 퀴즈 데이터', {
              'question': quizDto.question != null ? '존재' : 'null',
              'options': '${quizDto.options?.length ?? 0}개',
              'explanation': quizDto.explanation != null ? '존재' : 'null',
            });

            retryCount++;
            continue;
          }

          // correctOptionIndex 확인 및 수정
          final correctIndex = _validateCorrectOptionIndex(
            quizDto.correctOptionIndex ?? 0,
            quizDto.options?.length ?? 4,
          );

          // 관련성 검사 (개선된 버전)
          bool isRelevant = _isQuizRelevant(
            cleanedSkill,
            quizDto.question!,
            quizDto.options!,
          );

          // 관련성 없는 경우 재시도
          if (!isRelevant) {
            AppLogger.warning(
              '생성된 퀴즈가 $cleanedSkill 주제와 관련이 없습니다. 재시도합니다.',
              tag: 'QuizValidation',
            );

            AppLogger.logState('관련성 검사 결과', {
              'skill': cleanedSkill,
              'question': quizDto.question!.substring(
                0,
                min(50, quizDto.question!.length),
              ),
              'topicType': _detectTopicType(cleanedSkill.toLowerCase()),
            });

            retryCount++;
            continue;
          }

          // 추가 검증 - 비정상적인 답변 옵션 체크
          bool hasInvalidOptions =
              quizDto.options?.any(
                (option) => option.isEmpty || option.length < 2,
              ) ??
              false;

          if (hasInvalidOptions) {
            AppLogger.warning(
              '생성된 퀴즈에 비정상적인 옵션이 있습니다. 재시도합니다.',
              tag: 'QuizValidation',
            );

            AppLogger.logState('비정상적인 옵션 감지', {
              'options': quizDto.options?.map((o) => o.length ?? 0).toList(),
            });

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

          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('퀴즈 생성 완료', duration);

          AppLogger.info(
            '퀴즈 생성 완료: ${result.question.substring(0, min(30, result.question.length))}...',
            tag: 'QuizRepository',
          );

          return Result.success(result);
        } catch (innerError) {
          AppLogger.error(
            '퀴즈 생성 중 오류 발생 (시도 ${retryCount + 1}/5)',
            tag: 'QuizGeneration',
            error: innerError,
          );
          retryCount++;
        }
      }

      // 모든 시도가 실패한 경우 맞춤형 퀴즈 생성
      AppLogger.warning(
        'Firebase AI 퀴즈 생성 모두 실패. 최후의 시도를 합니다.',
        tag: 'QuizGeneration',
      );

      // 최후의 시도 - 폴백 퀴즈 생성
      final fallbackQuiz = _generateFallbackQuiz(cleanedSkill);

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('폴백 퀴즈 생성 완료', duration);

      return Result.success(fallbackQuiz);
    } catch (e, st) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('퀴즈 생성 실패', duration);

      AppLogger.error(
        'QuizRepositoryImpl - 퀴즈 생성 실패',
        tag: 'QuizRepository',
        error: e,
        stackTrace: st,
      );

      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  // 관련성 검사 (모든 주제 지원)
  bool _isQuizRelevant(String skill, String question, List<String> options) {
    final normalizedSkill = skill.toLowerCase().trim();
    final normalizedQuestion = question.toLowerCase();
    final optionsText = options.join(' ').toLowerCase();
    final allText = '$normalizedQuestion $optionsText';

    // 1. 주제 유형 감지
    final topicType = _detectTopicType(normalizedSkill);

    AppLogger.debug(
      '주제 유형 감지: $skill → $topicType',
      tag: 'QuizValidation',
    );

    if (topicType == '프로그래밍') {
      return _validateProgrammingQuiz(normalizedSkill, allText);
    } else {
      return _validateGeneralTopicQuiz(normalizedSkill, allText);
    }
  }

  // 주제 유형 감지
  String _detectTopicType(String skill) {
    final programmingKeywords = [
      'java',
      'python',
      'javascript',
      'react',
      'flutter',
      'dart',
      'kotlin',
      'swift',
      'c++',
      'c#',
      'php',
      'ruby',
      'go',
      'rust',
      'typescript',
      'html',
      'css',
      'sql',
      'nosql',
      'mongodb',
      'mysql',
      'postgresql',
      'node',
      'express',
      'spring',
      'django',
      'laravel',
      'vue',
      'angular',
      'android',
      'ios',
      'unity',
      'docker',
      'kubernetes',
      'aws',
      'gcp',
      'git',
      'github',
      'api',
      'rest',
      'graphql',
      'json',
      'xml',
      'blockchain',
      'machine learning',
      'ai',
      'ml',
      'deep learning',
      '프로그래밍',
      '개발',
      '코딩',
      '알고리즘',
      '자료구조',
      '데이터베이스',
      'framework',
      'library',
      '프레임워크',
      '라이브러리',
      '웹개발',
      '앱개발',
      '소프트웨어',
      '컴퓨터',
      '시스템',
      '네트워크',
      '보안',
      '클라우드',
    ];

    // 빈 값이거나 기본값인 경우
    if (skill.isEmpty || skill == '프로그래밍 기초' || skill == '컴퓨터 기초') {
      return '프로그래밍';
    }

    for (String keyword in programmingKeywords) {
      if (skill.contains(keyword.toLowerCase())) {
        return '프로그래밍';
      }
    }

    return '일반';
  }

  // 프로그래밍 퀴즈 검증
  bool _validateProgrammingQuiz(String skill, String allText) {
    // 1. 스킬명이 직접 포함되어 있는지
    if (allText.contains(skill)) {
      AppLogger.debug(
        '프로그래밍: 스킬명 직접 매칭 → $skill',
        tag: 'QuizValidation',
      );
      return true;
    }

    // 2. 기존 키워드 매핑 사용
    if (_programmingSkillKeywords.containsKey(skill)) {
      final keywords = _programmingSkillKeywords[skill]!;
      bool hasKeywords = keywords.any(
        (keyword) => allText.contains(keyword.toLowerCase()),
      );

      if (hasKeywords) {
        AppLogger.debug(
          '프로그래밍: 특정 키워드 매칭 → $skill',
          tag: 'QuizValidation',
        );
        return true;
      }
    }

    // 3. 일반적인 프로그래밍 키워드 확인
    final generalProgrammingTerms = [
      'function',
      'method',
      'class',
      'object',
      'variable',
      'array',
      'loop',
      'condition',
      'algorithm',
      'syntax',
      'compile',
      'debug',
      'library',
      'framework',
      'api',
      'database',
      'server',
      'client',
      '함수',
      '메서드',
      '클래스',
      '객체',
      '변수',
      '배열',
      '반복문',
      '조건문',
      '라이브러리',
      '프레임워크',
      '데이터베이스',
      '서버',
      '클라이언트',
    ];

    bool hasGeneralTerms = generalProgrammingTerms.any(
      (term) => allText.contains(term.toLowerCase()),
    );

    if (hasGeneralTerms) {
      AppLogger.debug(
        '프로그래밍: 일반 프로그래밍 용어 매칭 → $skill',
        tag: 'QuizValidation',
      );
      return true;
    }

    AppLogger.debug(
      '프로그래밍: 관련성 없음 → $skill',
      tag: 'QuizValidation',
    );
    return false;
  }

  // 일반 주제 퀴즈 검증 (관대한 접근)
  bool _validateGeneralTopicQuiz(String skill, String allText) {
    // 1. 프로그래밍 키워드가 포함되어 있으면 일반 주제가 아님
    final unwantedProgrammingKeywords = [
      'api',
      'database',
      'server',
      'client',
      'programming',
      'software',
      'computer',
      'algorithm',
      'function',
      'method',
      'class',
      'framework',
      'html',
      'css',
      'javascript',
      'python',
      'java',
      'code',
      'coding',
      'github',
      'git',
      'npm',
      'pip',
      'maven',
      'gradle',
      'docker',
      '프로그래밍',
      '알고리즘',
      '데이터베이스',
      '서버',
      '클라이언트',
      '코드',
      '소프트웨어',
      '개발',
      '웹개발',
      '앱개발',
      '시스템',
      '네트워크',
      '프레임워크',
      '라이브러리',
    ];

    bool hasProgrammingKeywords = unwantedProgrammingKeywords.any(
      (keyword) => allText.contains(keyword.toLowerCase()),
    );

    if (hasProgrammingKeywords) {
      AppLogger.debug(
        '일반 주제: 프로그래밍 키워드 감지로 제외 → $skill',
        tag: 'QuizValidation',
      );
      return false;
    }

    // 2. 스킬명이 직접 포함되어 있는지
    if (allText.contains(skill)) {
      AppLogger.debug(
        '일반 주제: 스킬명 직접 매칭 → $skill',
        tag: 'QuizValidation',
      );
      return true;
    }

    // 3. 알려진 주제들의 키워드 확인 (기본적인 것들만)
    final topicKeywords = _getKnownTopicKeywords(skill);
    if (topicKeywords.isNotEmpty) {
      bool hasTopicKeywords = topicKeywords.any(
        (keyword) => allText.contains(keyword.toLowerCase()),
      );

      if (hasTopicKeywords) {
        AppLogger.debug(
          '일반 주제: 알려진 키워드 매칭 → $skill',
          tag: 'QuizValidation',
        );
        return true;
      }
    }

    // 4. 일반적인 실생활 질문 패턴 확인
    final lifeQuestionPatterns = [
      '방법',
      '효과',
      '특징',
      '원리',
      '종류',
      '활용',
      '장점',
      '단점',
      '주의사항',
      '팁',
      '비법',
      '요령',
      '기술',
      '노하우',
      '가장',
      '최고',
      '최적',
      '효율적',
      '효과적',
      '중요한',
      '핵심',
      '실생활',
      '일상',
      '생활',
      '도움',
      '개선',
      '향상',
      '방지',
      '예방',
      '치료',
      '관리',
      '유지',
      'method',
      'effect',
      'benefit',
      'advantage',
      'tip',
      'way',
      'best',
      'daily',
      'life',
      'practical',
      'effective',
      'important',
      'key',
    ];

    bool hasLifePattern = lifeQuestionPatterns.any(
      (pattern) => allText.contains(pattern.toLowerCase()),
    );

    if (hasLifePattern) {
      AppLogger.debug(
        '일반 주제: 실생활 패턴 매칭 → $skill',
        tag: 'QuizValidation',
      );
      return true;
    }

    // 5. 질문 형태 확인 (기본적인 퀴즈 형태)
    final questionWords = ['무엇', '어떤', '언제', '어디', '왜', '어느', '몇'];
    bool hasQuestionWord = questionWords.any((word) => allText.contains(word));
    bool hasQuestionMark = allText.contains('?');

    if (hasQuestionWord || hasQuestionMark) {
      AppLogger.debug(
        '일반 주제: 질문 형태 확인으로 통과 → $skill',
        tag: 'QuizValidation',
      );
      return true;
    }

    AppLogger.debug(
      '일반 주제: 관련성 확인 불가 → $skill',
      tag: 'QuizValidation',
    );

    // 관대한 접근: 프로그래밍이 아닌 모든 주제는 기본적으로 허용
    // (AI가 이미 해당 주제로 퀴즈를 생성했다면 관련성이 있다고 판단)
    return true;
  }

  // 알려진 주제 키워드 (최소한만 유지)
  List<String> _getKnownTopicKeywords(String skill) {
    final basicKeywordMap = {
      '잠자기': ['수면', '잠', '꿈', '멜라토닌', 'rem', 'nrem', '각성', '취침'],
      '운동': ['운동', '근력', '체력', '건강', '피트니스', '트레이닝', '스포츠'],
      '요리': ['요리', '음식', '조리', '레시피', '식재료', '요리법'],
      '독서': ['독서', '책', '읽기', '도서', '문학'],
      '여행': ['여행', '관광', '휴가', '여행지', '관광지'],
      '건강': ['건강', '질병', '의료', '병원', '치료'],
      '학습': ['학습', '공부', '교육', '암기', '시험'],
      '음악': ['음악', '악기', '노래', '멜로디', '리듬'],
      '영화': ['영화', '시네마', '배우', '감독', '영상'],
      '게임': ['게임', '플레이', '캐릭터', '스테이지'],
      '스포츠': ['스포츠', '경기', '선수', '팀', '운동'],
      '패션': ['패션', '옷', '스타일', '의류', '코디'],
      '미용': ['미용', '화장품', '스킨케어', '관리'],
      '그림': ['그림', '미술', '작품', '페인팅', '드로잉'],
      '사진': ['사진', '촬영', '카메라', '렌즈'],
      '춤': ['춤', '댄스', '안무', '리듬'],
      '바둑': ['바둑', '기석', '수읽기', '정석'],
      '체스': ['체스', '말', '킹', '퀸', '체크메이트'],
    };

    return basicKeywordMap[skill] ?? [];
  }

  // 개선된 폴백 퀴즈 생성 (주제별 맞춤)
  Quiz _generateFallbackQuiz(String skillName) {
    AppLogger.info(
      '폴백 퀴즈 생성: $skillName',
      tag: 'QuizFallback',
    );

    final capitalizedSkill =
        skillName.substring(0, 1).toUpperCase() + skillName.substring(1);

    final topicType = _detectTopicType(skillName.toLowerCase());

    if (topicType == '프로그래밍') {
      return _generateProgrammingFallbackQuiz(capitalizedSkill);
    } else {
      return _generateGeneralFallbackQuiz(capitalizedSkill);
    }
  }

  // 프로그래밍 폴백 퀴즈
  Quiz _generateProgrammingFallbackQuiz(String skill) {
    final fallbackQuiz = Quiz(
      question: "$skill의 주요 특징은 무엇인가요?",
      options: [
        "$skill은 높은 생산성을 제공합니다.",
        "$skill은 주로 모바일 앱 개발에만 사용됩니다.",
        "$skill은 객체 지향 프로그래밍을 지원하지 않습니다.",
        "$skill은 오직 Windows에서만 동작합니다.",
      ],
      explanation: "$skill은 다양한 환경에서 사용할 수 있으며, 높은 생산성을 제공하는 것이 주요 특징입니다.",
      correctOptionIndex: 0,
      relatedSkill: skill,
    );

    AppLogger.info(
      '프로그래밍 폴백 퀴즈 생성 완료: ${fallbackQuiz.question}',
      tag: 'QuizFallback',
    );

    return fallbackQuiz;
  }

  // 일반 주제 폴백 퀴즈
  Quiz _generateGeneralFallbackQuiz(String skill) {
    final fallbackQuiz = Quiz(
      question: "$skill에 대한 기본 지식으로 옳은 것은?",
      options: [
        "$skill은 적절한 방법과 꾸준한 연습이 중요합니다.",
        "$skill은 특별한 재능이 있어야만 할 수 있습니다.",
        "$skill은 나이가 어릴 때만 배울 수 있습니다.",
        "$skill은 남성에게만 적합한 활동입니다.",
      ],
      explanation: "$skill은 누구나 적절한 방법으로 꾸준히 연습하면 향상시킬 수 있는 분야입니다.",
      correctOptionIndex: 0,
      relatedSkill: skill,
    );

    AppLogger.info(
      '일반 주제 폴백 퀴즈 생성 완료: ${fallbackQuiz.question}',
      tag: 'QuizFallback',
    );

    return fallbackQuiz;
  }

  // correctOptionIndex 값 검증 및 수정
  int _validateCorrectOptionIndex(int index, int optionsLength) {
    if (optionsLength <= 0) {
      AppLogger.warning(
        '옵션 개수가 0 이하입니다: $optionsLength',
        tag: 'QuizValidation',
      );
      return 0;
    }

    // 범위 확인 (0 <= index < optionsLength)
    if (index < 0 || index >= optionsLength) {
      final validIndex = _random.nextInt(optionsLength);

      AppLogger.warning(
        '유효하지 않은 correctOptionIndex 감지: $index, 옵션 개수: $optionsLength → $validIndex로 수정',
        tag: 'QuizValidation',
      );

      return validIndex; // 랜덤한 유효 인덱스 반환
    }

    AppLogger.debug(
      'correctOptionIndex 검증 통과: $index (옵션 개수: $optionsLength)',
      tag: 'QuizValidation',
    );

    return index;
  }
}
