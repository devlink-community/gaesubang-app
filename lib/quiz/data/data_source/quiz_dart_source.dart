import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../module/vertax_client.dart';

abstract interface class QuizDataSource {
  Future<Map<String, dynamic>> generateQuiz({String? skills});
}

class VertexAIQuizDataSourceImpl implements QuizDataSource {
  final VertexAIClient _vertexAIClient = VertexAIClient();

  @override
  Future<Map<String, dynamic>> generateQuiz({String? skills}) async {
    try {
      // VertexAI 클라이언트 초기화 확인
      await _vertexAIClient.initialize();

      // 스킬 파싱 - skills가 문자열로 제공되면 리스트로 변환
      List<String> skillList = [];
      if (skills != null && skills.isNotEmpty) {
        skillList = skills.split(',').map((s) => s.trim()).toList();
      }

      List<Map<String, dynamic>> quizzes;

      // 스킬 기반 또는 일반 퀴즈 생성
      if (skillList.isNotEmpty) {
        debugPrint('스킬($skillList) 기반으로 퀴즈 생성');
        quizzes = await _vertexAIClient.generateQuizBySkills(skillList, 1);
      } else {
        debugPrint('일반 퀴즈 생성');
        quizzes = await _vertexAIClient.generateGeneralQuiz(1);
      }

      // 생성된 퀴즈가 없으면 예외 처리
      if (quizzes.isEmpty) {
        throw Exception('생성된 퀴즈가 없습니다');
      }

      // 첫 번째 퀴즈 가져오기
      final quizData = quizzes.first;

      // 필드명 호환성 처리 (VertexAI의 필드명을 우리 모델에 맞게 변환)
      final processedQuiz = {
        'question': quizData['question'],
        'options': quizData['options'],
        'correctAnswerIndex': quizData['correctOptionIndex'],
        'explanation': quizData['explanation'],
        'category': quizData['relatedSkill'],
      };

      // 디버그 로그
      debugPrint('퀴즈 생성 성공: ${processedQuiz['question']}');

      return processedQuiz;
    } catch (e) {
      debugPrint('퀴즈 생성 실패: $e');

      // 오류 발생 시 기본 퀴즈 반환 (API 오류에도 앱이 동작하도록)
      return _getFallbackQuiz(skills);
    }
  }

  // API 오류 시 사용할 기본 퀴즈 목록
  Map<String, dynamic> _getFallbackQuiz(String? skills) {
    final defaultQuizzes = [
      {
        "question": "Flutter 앱에서 상태 관리를 위해 사용되지 않는 패키지는?",
        "options": ["Provider", "Riverpod", "MobX", "Django"],
        "correctAnswerIndex": 3,
        "explanation":
            "Django는 Python 웹 프레임워크로, Flutter 상태 관리에 사용되지 않습니다. Provider, Riverpod, MobX는 모두 Flutter에서 상태 관리에 사용되는 패키지입니다.",
        "category": "Flutter",
      },
      {
        "question": "다음 중 시간 복잡도가 O(n log n)인 정렬 알고리즘은?",
        "options": ["버블 정렬", "퀵 정렬", "삽입 정렬", "선택 정렬"],
        "correctAnswerIndex": 1,
        "explanation":
            "퀵 정렬의 평균 시간 복잡도는 O(n log n)입니다. 버블 정렬, 삽입 정렬, 선택 정렬은 모두 O(n²) 시간 복잡도를 가집니다.",
        "category": "알고리즘",
      },
      {
        "question": "Dart에서 불변 객체를 생성하기 위해 주로 사용되는 패키지는?",
        "options": ["immutable.js", "freezed", "immutable", "const_builder"],
        "correctAnswerIndex": 1,
        "explanation": "freezed는 Dart에서 불변 객체를 쉽게 생성할 수 있게 해주는 코드 생성 패키지입니다.",
        "category": "Dart",
      },
    ];

    // 스킬에 따라 관련 퀴즈 선택 또는 랜덤 선택
    if (skills != null && skills.isNotEmpty) {
      final lowercaseSkills = skills.toLowerCase();
      final matchingQuizzes =
          defaultQuizzes.where((quiz) {
            return lowercaseSkills.contains(
              quiz["category"].toString().toLowerCase(),
            );
          }).toList();

      if (matchingQuizzes.isNotEmpty) {
        return matchingQuizzes[Random().nextInt(matchingQuizzes.length)];
      }
    }

    // 관련 퀴즈가 없으면 랜덤 선택
    return defaultQuizzes[Random().nextInt(defaultQuizzes.length)];
  }
}
