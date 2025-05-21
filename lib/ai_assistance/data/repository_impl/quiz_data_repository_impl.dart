// lib/ai_assistance/data/repository_impl/quiz_data_repository_impl.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../../core/result/result.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../data_source/quiz_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizDataSource _dataSource;
  final GetCurrentUserUseCase? _getCurrentUserUseCase; // 옵셔널로 주입

  QuizRepositoryImpl({
    required QuizDataSource dataSource,
    GetCurrentUserUseCase? getCurrentUserUseCase,
  }) : _dataSource = dataSource,
       _getCurrentUserUseCase = getCurrentUserUseCase;

  // 현재 사용자 ID를 가져오는 메서드
  Future<String> _getUserId() async {
    if (_getCurrentUserUseCase != null) {
      try {
        final userResult = await _getCurrentUserUseCase.execute();
        if (userResult case AsyncData(:final value)) {
          return value.id;
        }
      } catch (e) {
        debugPrint('현재 사용자 ID 가져오기 실패: $e');
      }
    }
    // 기본값 또는 익명 사용자 ID
    return 'anonymous_user';
  }

  // 퀴즈 저장 키를 생성하는 메서드 (사용자별 구분)
  Future<String> _getQuizStorageKey() async {
    final userId = await _getUserId();
    return 'daily_quiz_$userId';
  }

  // 스킬 문자열을 정규화하여 일관된 키 생성 (수정된 부분)
  String _normalizeSkillsKey(String skills) {
    // 스킬 문자열을 정규화: 모두 소문자로 변환하고, 공백 제거, 알파벳 순 정렬
    final skillsList =
        skills
            .toLowerCase()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
          ..sort(); // 순서에 관계없이 동일한 스킬셋은 동일한 키를 가지도록

    // 고유 식별자 생성
    return skillsList.join('_');
  }

  // 스킬 변경 감지를 개선한 메서드 (새로 추가)
  Future<bool> _isSkillChanged(String quizKey, String? skills) async {
    final prefs = await SharedPreferences.getInstance();
    // 현재 저장된 스킬 정보 키 가져오기
    final currentSkillKey = prefs.getString('${quizKey}_current_skills');

    // 정규화된 새 스킬 키 계산
    final newSkillKey = skills != null ? _normalizeSkillsKey(skills) : null;

    // 스킬 정보가 변경되었는지 비교
    final hasChanged = currentSkillKey != newSkillKey;

    if (hasChanged) {
      debugPrint('스킬 정보 변경 감지: $currentSkillKey → $newSkillKey');
      // 새 스킬 정보 저장
      if (newSkillKey != null) {
        await prefs.setString('${quizKey}_current_skills', newSkillKey);
      } else {
        await prefs.remove('${quizKey}_current_skills');
      }
    }

    return hasChanged;
  }

  @override
  Future<Result<Quiz>> generateDailyQuiz({String? skills}) async {
    try {
      await _clearAllQuizData();
      // 오늘 날짜 가져오기
      final today = _getTodayDateString();

      // 사용자 ID 가져오기
      final userId = await _getUserId();
      final quizKey = 'daily_quiz_$userId';

      // 스킬 정보가 있는 경우 키에 추가 (스킬별 다른 퀴즈)
      final finalKey =
          skills != null ? "${quizKey}_${skills.hashCode}" : quizKey;

      debugPrint('새 퀴즈 생성 시도 - 사용자 키: $finalKey, 스킬: $skills');

      // 새 퀴즈 생성 - API 호출 로그 추가
      try {
        // 데이터 소스를 통한 API 호출
        debugPrint('DataSource.generateQuiz 호출 시작 - 스킬: $skills');
        final quizData = await _dataSource.generateQuiz(skills: skills);
        debugPrint(
          'DataSource.generateQuiz 호출 완료 - 성공적으로 데이터 수신: ${quizData['question']}',
        );

        // 퀴즈 모델로 변환
        final quiz = Quiz(
          question: quizData['question'],
          options: List<String>.from(quizData['options']),
          correctAnswerIndex: quizData['correctAnswerIndex'],
          explanation: quizData['explanation'],
          category: quizData['category'],
          generatedDate: DateTime.now(),
        );

        // 로컬에 퀴즈 저장
        await _saveQuizToPrefs(quiz, finalKey);

        debugPrint('새 퀴즈 생성 성공: ${quiz.question}');
        return Result.success(quiz);
      } catch (apiError, st) {
        debugPrint('API를 통한 퀴즈 생성 실패: $apiError');

        // API 호출 실패 시 기본 퀴즈 생성
        final defaultQuestion = "Python에서 리스트 컴프리헨션을 올바르게 사용한 예는?";
        final defaultOptions = [
          "list = [x in range(10)]",
          "list = [x for x in range(10)]",
          "list = [for x in range(10)]",
          "list = [x if x in range(10)]",
        ];
        final defaultExplanation =
            "리스트 컴프리헨션은 [표현식 for 항목 in 반복가능객체]의 형태로 작성합니다.";

        final quiz = Quiz(
          question: defaultQuestion,
          options: defaultOptions,
          correctAnswerIndex: 1,
          explanation: defaultExplanation,
          category: skills ?? "Python",
          generatedDate: DateTime.now(),
        );

        // 로컬에 퀴즈 저장
        await _saveQuizToPrefs(quiz, finalKey);

        debugPrint('기본 Python 퀴즈 생성 완료 (API 오류로 인한 대체)');
        return Result.success(quiz);
      }
    } catch (e, st) {
      debugPrint('전체 퀴즈 생성 과정 실패: $e');
      return Result.error(
        Failure(
          FailureType.unknown,
          '퀴즈를 생성하는 데 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Quiz?>> getTodayQuiz({String? skills}) async {
    try {
      // 사용자별 퀴즈 키 가져오기
      final quizKey = await _getQuizStorageKey();

      // 스킬 정보가 있는 경우 키에 추가 (스킬별 다른 퀴즈)
      final finalKey =
          skills != null ? "${quizKey}_${skills.hashCode}" : quizKey;

      debugPrint('오늘의 퀴즈 조회 - 사용자 키: $finalKey, 스킬: $skills');

      final prefs = await SharedPreferences.getInstance();
      final storedQuizJson = prefs.getString(finalKey);

      if (storedQuizJson == null) {
        debugPrint('저장된 퀴즈 없음');
        return const Result.success(null); // 저장된 퀴즈 없음
      }

      final quizMap = jsonDecode(storedQuizJson);

      // 여기서는 기존 코드의 메서드 이름을 그대로 사용
      // 저장된 날짜와 오늘 날짜 비교 - 클래스의 실제 메서드 이름을 사용
      final storedDate = quizMap['generatedDate'] as String;
      final today = _getTodayDateString(); // 실제 메서드 이름으로 교체 필요

      if (storedDate != today) {
        debugPrint('오늘 날짜와 일치하지 않는 퀴즈');
        return const Result.success(null); // 오늘 퀴즈 아님
      }

      // 퀴즈 모델로 변환
      final quiz = Quiz(
        question: quizMap['question'] as String,
        options: List<String>.from(quizMap['options']),
        correctAnswerIndex: quizMap['correctAnswerIndex'] as int,
        explanation: quizMap['explanation'] as String,
        category: quizMap['category'] as String,
        generatedDate: DateTime.parse(quizMap['generatedDate']),
        isAnswered: quizMap['isAnswered'] ?? false,
        attemptedAnswerIndex: quizMap['attemptedAnswerIndex'] as int?,
      );

      debugPrint('저장된 퀴즈 반환 - 답변 상태: ${quiz.isAnswered}');
      return Result.success(quiz);
    } catch (e, st) {
      debugPrint('오늘의 퀴즈 로드 실패: $e');
      return Result.error(
        Failure(
          FailureType.unknown,
          '퀴즈를 불러오는 데 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Quiz>> saveQuizAnswer({
    required Quiz quiz,
    required int answerIndex,
  }) async {
    try {
      // 디버그 로그 출력
      debugPrint('saveQuizAnswer - 시작: answerIndex=$answerIndex');

      // 퀴즈 업데이트
      final updatedQuiz = quiz.copyWith(
        attemptedAnswerIndex: answerIndex,
        isAnswered: true,
      );

      debugPrint(
        'saveQuizAnswer - 업데이트된 퀴즈: isAnswered=${updatedQuiz.isAnswered}, attemptedAnswerIndex=${updatedQuiz.attemptedAnswerIndex}',
      );

      // 사용자별 퀴즈 키 가져오기
      final quizKey = await _getQuizStorageKey();

      // 현재 사용중인 스킬 정보 확인 (수정된 부분)
      final prefs = await SharedPreferences.getInstance();
      final currentSkillKey = prefs.getString('${quizKey}_current_skills');

      // 스킬 정보에 맞는 최종 키 생성
      String finalKey = quizKey;
      if (currentSkillKey != null) {
        finalKey = "${quizKey}_${currentSkillKey}";
      } else if (quiz.category.isNotEmpty) {
        // 이전 버전과의 호환성을 위한 코드
        finalKey = "${quizKey}_${_normalizeSkillsKey(quiz.category)}";
      }

      // 로컬에 저장
      await _saveQuizToPrefs(updatedQuiz, finalKey);

      debugPrint('saveQuizAnswer - SharedPreferences에 저장 완료 (키: $finalKey)');

      return Result.success(updatedQuiz);
    } catch (e, st) {
      debugPrint('퀴즈 답변 저장 실패: $e');
      return Result.error(
        Failure(
          FailureType.unknown,
          '답변을 저장하는 데 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // 오늘 날짜 문자열 가져오기 (YYYY-MM-DD 형식)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 퀴즈 데이터 구조 검증 - 메서드명 변경 (함수 호출 오류 방지)
  // 퀴즈 데이터 구조 검증 - 괄호 사용 수정
  bool _validateQuizDataFunction(Map<String, dynamic> quizData) {
    // 필수 필드 확인
    if (!quizData.containsKey('question') ||
        !quizData.containsKey('options') ||
        !quizData.containsKey('correctAnswerIndex') ||
        !quizData.containsKey('explanation') ||
        !quizData.containsKey('category')) {
      return false;
    }

    // options 타입 및 비어있는지 확인
    if (!(quizData['options'] is List) ||
        (quizData['options'] as List).isEmpty) {
      return false;
    }

    // correctAnswerIndex 타입 확인
    if (!(quizData['correctAnswerIndex'] is int)) {
      return false;
    }

    // correctAnswerIndex가 범위 내에 있는지 확인
    final correctIndex = quizData['correctAnswerIndex'] as int;
    final optionsList = quizData['options'] as List;
    if (correctIndex < 0 || correctIndex >= optionsList.length) {
      return false;
    }

    // 모든 조건 통과
    return true;
  }

  // 퀴즈를 SharedPreferences에 저장 (사용자 ID 기반)
  Future<void> _saveQuizToPrefs(Quiz quiz, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final quizMap = {
        'question': quiz.question,
        'options': quiz.options,
        'correctAnswerIndex': quiz.correctAnswerIndex,
        'explanation': quiz.explanation,
        'category': quiz.category,
        'generatedDate': _getTodayDateString(),
        'isAnswered': quiz.isAnswered,
        'attemptedAnswerIndex': quiz.attemptedAnswerIndex,
      };

      final quizJson = jsonEncode(quizMap);
      await prefs.setString(key, quizJson);

      // 디버그 로그
      debugPrint(
        '퀴즈 저장 완료 (키: $key): ${quiz.isAnswered ? "답변됨" : "답변안됨"}, 선택 인덱스: ${quiz.attemptedAnswerIndex}',
      );
    } catch (e) {
      debugPrint('퀴즈 로컬 저장 실패: $e');
      rethrow;
    }
  }

  @override
  Future<String> getQuizStorageKey() async {
    final userId = await _getUserId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'quiz_${userId}_$timestamp';
  }
}

/// 모든 퀴즈 데이터 삭제 (캐시 초기화)
Future<void> _clearAllQuizData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // 'daily_quiz_' 로 시작하는 모든 키 찾기
    final allKeys = prefs.getKeys();
    final quizKeys =
        allKeys.where((key) => key.startsWith('daily_quiz_')).toList();

    // 퀴즈 관련 모든 키 삭제
    for (final key in quizKeys) {
      await prefs.remove(key);
      debugPrint('퀴즈 데이터 삭제: $key');
    }

    debugPrint('모든 퀴즈 데이터 삭제 완료 (${quizKeys.length}개)');
  } catch (e) {
    debugPrint('퀴즈 데이터 삭제 실패: $e');
  }
}
