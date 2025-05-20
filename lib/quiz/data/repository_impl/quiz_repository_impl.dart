import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../core/result/result.dart';
import '../../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../data_source/quiz_dart_source.dart';

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

  @override
  Future<Result<Quiz>> generateDailyQuiz({String? skills}) async {
    try {
      // 오늘 날짜 가져오기
      final today = _getTodayDateString();

      // 사용자별 퀴즈 키 가져오기
      final quizKey = await _getQuizStorageKey();
      debugPrint('퀴즈 생성 - 사용자 키: $quizKey');

      // 이미 오늘 퀴즈가 있는지 확인
      final prefs = await SharedPreferences.getInstance();
      final storedQuizJson = prefs.getString(quizKey);

      if (storedQuizJson != null) {
        final quizMap = jsonDecode(storedQuizJson);
        final storedDate = quizMap['generatedDate'] as String;

        // 오늘 날짜와 일치하면 저장된 퀴즈 반환
        if (storedDate == today) {
          debugPrint('이미 저장된 오늘의 퀴즈 반환');
          return Result.success(
            Quiz(
              question: quizMap['question'],
              options: List<String>.from(quizMap['options']),
              correctAnswerIndex: quizMap['correctAnswerIndex'],
              explanation: quizMap['explanation'],
              category: quizMap['category'],
              generatedDate: DateTime.parse(quizMap['generatedDate']),
              isAnswered: quizMap['isAnswered'] ?? false,
              attemptedAnswerIndex: quizMap['attemptedAnswerIndex'],
            ),
          );
        }
      }

      // 새 퀴즈 생성
      debugPrint('새 퀴즈 생성');
      final quizData = await _dataSource.generateQuiz(skills: skills);

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
      await _saveQuizToPrefs(quiz);

      return Result.success(quiz);
    } catch (e, st) {
      debugPrint('퀴즈 생성 실패: $e');
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
  Future<Result<Quiz?>> getTodayQuiz() async {
    try {
      // 사용자별 퀴즈 키 가져오기
      final quizKey = await _getQuizStorageKey();
      debugPrint('오늘의 퀴즈 조회 - 사용자 키: $quizKey');

      final prefs = await SharedPreferences.getInstance();
      final storedQuizJson = prefs.getString(quizKey);

      if (storedQuizJson == null) {
        debugPrint('저장된 퀴즈 없음');
        return const Result.success(null); // 저장된 퀴즈 없음
      }

      final quizMap = jsonDecode(storedQuizJson);

      // 저장된 날짜와 오늘 날짜 비교
      final storedDate = quizMap['generatedDate'] as String;
      final today = _getTodayDateString();

      if (storedDate != today) {
        debugPrint('오늘 날짜와 일치하지 않는 퀴즈');
        return const Result.success(null); // 오늘 퀴즈 아님
      }

      // 퀴즈 모델로 변환
      final quiz = Quiz(
        question: quizMap['question'],
        options: List<String>.from(quizMap['options']),
        correctAnswerIndex: quizMap['correctAnswerIndex'],
        explanation: quizMap['explanation'],
        category: quizMap['category'],
        generatedDate: DateTime.parse(quizMap['generatedDate']),
        isAnswered: quizMap['isAnswered'] ?? false,
        attemptedAnswerIndex: quizMap['attemptedAnswerIndex'],
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

      // 로컬에 저장
      await _saveQuizToPrefs(updatedQuiz);

      debugPrint('saveQuizAnswer - SharedPreferences에 저장 완료');

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

  // 퀴즈를 SharedPreferences에 저장 (사용자 ID 기반)
  Future<void> _saveQuizToPrefs(Quiz quiz) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 사용자별 키 생성
      final quizKey = await _getQuizStorageKey();

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
      await prefs.setString(quizKey, quizJson);

      // 디버그 로그
      debugPrint(
        '퀴즈 저장 완료 (키: $quizKey): ${quiz.isAnswered ? "답변됨" : "답변안됨"}, 선택 인덱스: ${quiz.attemptedAnswerIndex}',
      );
    } catch (e) {
      debugPrint('퀴즈 로컬 저장 실패: $e');
      rethrow;
    }
  }
}
