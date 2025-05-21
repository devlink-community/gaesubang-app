// lib/ai_assistance/data/data_source/study_tip_data_source.dart

import 'package:flutter/foundation.dart';
import '../../module/vertex_client.dart';

abstract interface class StudyTipDataSource {
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt);
  Future<Map<String, dynamic>> generateStudyTipBySkill(String skill);
}

class StudyTipDataSourceImpl implements StudyTipDataSource {
  final VertexAIClient _vertexClient;

  StudyTipDataSourceImpl({required VertexAIClient vertexClient})
      : _vertexClient = vertexClient;

  @override
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt) async {
    try {
      // 프롬프트를 직접 VertexAIClient에 전달
      return await _vertexClient.callTextModel(prompt);
    } catch (e) {
      debugPrint('학습 팁 생성 API 호출 실패: $e');
      return _generateFallbackStudyTip(prompt);
    }
  }

  @override
  Future<Map<String, dynamic>> generateStudyTipBySkill(String skill) async {
    try {
      // 스킬 기반으로 프롬프트 생성
      final prompt = _buildPrompt(skill);

      // 생성된 프롬프트로 API 호출
      return await _vertexClient.callTextModel(prompt);
    } catch (e) {
      debugPrint('스킬 기반 학습 팁 생성 실패: $e');
      return _generateFallbackStudyTip(skill);
    }
  }

  /// 스킬 영역에 맞는 프롬프트 생성 메서드 추가
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

  /// 폴백 학습 팁 데이터 생성 메서드
  Map<String, dynamic> _generateFallbackStudyTip(String prompt) {
    // prompt에서 언급된 스킬에 따라 다른 팁 반환
    if (prompt.toLowerCase().contains('python')) {
      return {
        "title": "파이썬 학습 시 실습 중심으로 접근하기",
        "content": "파이썬을 효과적으로 배우려면 단순히 읽는 것보다 직접 코드를 작성해보는 것이 중요합니다. 작은 프로젝트를 만들거나 코딩 챌린지를 통해 학습하는 것이 효과적입니다. 또한 파이썬의 공식 문서와 함께 Stack Overflow를 적극 활용하세요.",
        "relatedSkill": "Python",
        "englishPhrase": "Readability counts.",
        "translation": "가독성이 중요하다.",
        "source": "The Zen of Python"
      };
    } else if (prompt.toLowerCase().contains('flutter') ||
        prompt.toLowerCase().contains('dart')) {
      return {
        "title": "Flutter 개발자를 위한 위젯 이해하기",
        "content": "Flutter에서 모든 것은 위젯입니다. StatefulWidget과 StatelessWidget의 차이를 확실히 이해하고 각각 언제 사용해야 하는지 파악하는 것이 중요합니다. Flutter 개발자 도구를 활용해 위젯 트리를 분석하고 성능 이슈를 디버깅하세요.",
        "relatedSkill": "Flutter",
        "englishPhrase": "Everything is a widget.",
        "translation": "모든 것이 위젯이다.",
        "source": "Flutter 공식 문서"
      };
    }

    // 기본 팁 (프로그래밍 일반)
    return {
      "title": "개발자를 위한 시간 관리 팁",
      "content": "효과적인 개발을 위해서는 '딥 워크'가 필요합니다. 2-3시간 동안 방해 없이 집중할 수 있는 환경을 만드세요. 알림을 끄고, 동료들에게 집중 시간임을 알리고, 소음 차단 헤드폰을 활용하세요. 포모도로 기법(25분 집중 + 5분 휴식)도 효과적입니다.",
      "relatedSkill": "프로그래밍 기초",
      "englishPhrase": "Premature optimization is the root of all evil.",
      "translation": "때 이른 최적화는 모든 악의 근원이다.",
      "source": "Donald Knuth"
    };
  }
}