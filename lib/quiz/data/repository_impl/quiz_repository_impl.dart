import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../core/result/result.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../data_source/quiz_dart_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizDataSource _dataSource;

  QuizRepositoryImpl({required QuizDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<Quiz>> generateDailyQuiz({String? skills}) async {
    try {
      // 오늘 날짜 가져오기
      final today = _getTodayDateString();

      // 이미 오늘 퀴즈가 있는지 확인
      final prefs = await SharedPreferences.getInstance();
      final storedQuizJson = prefs.getString('daily_quiz');

      if (storedQuizJson != null) {
        final quizMap = jsonDecode(storedQuizJson);
        final storedDate = quizMap['generatedDate'] as String;

        // 오늘 날짜와 일치하면 저장된 퀴즈 반환
        if (storedDate == today) {
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
      final prefs = await SharedPreferences.getInstance();
      final storedQuizJson = prefs.getString('daily_quiz');

      if (storedQuizJson == null) {
        return const Result.success(null); // 저장된 퀴즈 없음
      }

      final quizMap = jsonDecode(storedQuizJson);

      // 저장된 날짜와 오늘 날짜 비교
      final storedDate = quizMap['generatedDate'] as String;
      final today = _getTodayDateString();

      if (storedDate != today) {
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
      // 퀴즈 업데이트
      final updatedQuiz = quiz.copyWith(
        attemptedAnswerIndex: answerIndex,
        isAnswered: true,
      );

      // 로컬에 저장
      await _saveQuizToPrefs(updatedQuiz);

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

  // 퀴즈를 SharedPreferences에 저장
  Future<void> _saveQuizToPrefs(Quiz quiz) async {
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
      await prefs.setString('daily_quiz', quizJson);
    } catch (e) {
      debugPrint('퀴즈 로컬 저장 실패: $e');
      rethrow;
    }
  }
}
