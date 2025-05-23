// lib/group/domain/service/group_chatbot_service.dart
import 'dart:math';

import 'package:devlink_mobile_app/ai_assistance/module/vertex_client.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:flutter/foundation.dart';

/// 그룹 채팅용 챗봇 서비스
class GroupChatbotService {
  final FirebaseAIClient _aiClient;
  final Random _random = Random();

  GroupChatbotService({required FirebaseAIClient aiClient})
    : _aiClient = aiClient;

  Future<ChatMessage> generateBotResponse({
    required String userMessage,
    required String groupId,
    required BotType botType,
    List<ChatMessage>? recentMessages,
  }) async {
    try {
      // 컨텍스트 구성
      final context = _buildConversationContext(
        userMessage,
        recentMessages,
        botType,
      );

      // 🔧 수정: AI 응답 생성 및 직접 텍스트 처리
      final response = await _aiClient.callTextModel(context);

      String botResponse;

      // JSON 응답인지 확인
      if (response.containsKey('content') ||
          response.containsKey('text') ||
          response.containsKey('response')) {
        botResponse = _extractResponseText(response);
      } else {
        // 🆕 추가: response 자체가 텍스트인 경우
        botResponse =
            response.values.first?.toString() ?? _getFallbackResponse(botType);
      }

      // 봇 메시지 생성
      return _createBotMessage(
        content: botResponse,
        groupId: groupId,
        botType: botType,
      );
    } catch (e) {
      debugPrint('챗봇 응답 생성 실패: $e');

      // 폴백 응답
      return _createBotMessage(
        content: _getFallbackResponse(botType),
        groupId: groupId,
        botType: botType,
      );
    }
  }

  /// 대화 컨텍스트 구성
  String _buildConversationContext(
    String userMessage,
    List<ChatMessage>? recentMessages,
    BotType botType,
  ) {
    final botPersonality = _getBotPersonality(botType);
    final conversationHistory = _buildConversationHistory(recentMessages);

    return """
$botPersonality

대화 기록:
$conversationHistory

사용자 질문: $userMessage

답변 요구사항:
- 한국어로 답변하세요
- 친근하고 도움이 되는 톤으로 작성하세요
- 답변은 200자 이내로 간결하게 해주세요
- 이모지를 적절히 사용해서 친근감을 높여주세요
- 그룹 채팅 환경임을 고려해 간단명료하게 답변하세요

답변:
""";
  }

  /// 봇 성격 정의
  String _getBotPersonality(BotType botType) {
    switch (botType) {
      case BotType.assistant:
        return """
당신은 개발자들을 위한 AI 어시스턴트입니다.
- 프로그래밍, 기술 관련 질문에 전문적으로 답변합니다
- 코드 리뷰, 디버깅 도움, 개발 방법론 조언을 제공합니다
- 최신 기술 트렌드와 모범 사례를 공유합니다
""";
      case BotType.researcher:
        return """
당신은 정보 조사 전문 AI입니다.
- 다양한 주제에 대한 정확한 정보를 제공합니다
- 데이터 분석, 시장 조사, 트렌드 분석을 도와줍니다
- 신뢰할 수 있는 자료와 근거를 바탕으로 답변합니다
""";
      case BotType.counselor:
        return """
당신은 따뜻하고 공감적인 AI 상담사입니다.
- 개발자들의 고민과 스트레스를 이해하고 위로합니다
- 번아웃, 커리어 고민, 학습 방향에 대한 조언을 제공합니다
- 항상 긍정적이고 격려하는 톤으로 소통합니다
""";
    }
  }

  /// 최근 대화 기록 구성
  String _buildConversationHistory(List<ChatMessage>? recentMessages) {
    if (recentMessages == null || recentMessages.isEmpty) {
      return "(이전 대화 없음)";
    }

    // 최근 5개 메시지만 사용
    final messages = recentMessages.take(5).toList();
    final history = messages
        .map((msg) {
          final sender =
              _isBotMessage(msg.senderId) ? msg.senderName : msg.senderName;
          return "$sender: ${msg.content}";
        })
        .join("\n");

    return history;
  }

  /// AI 응답에서 텍스트 추출
  String _extractResponseText(Map<String, dynamic> response) {
    // 🔧 수정: JSON 형식이 아닌 일반 텍스트 응답도 처리

    // 1. JSON 형식 응답 확인
    if (response.containsKey('content')) {
      return response['content'] as String? ?? _getGenericFallback();
    }

    if (response.containsKey('text')) {
      return response['text'] as String? ?? _getGenericFallback();
    }

    if (response.containsKey('response')) {
      return response['response'] as String? ?? _getGenericFallback();
    }

    // 🆕 추가: response 전체가 텍스트인 경우 처리
    final responseString = response.toString();
    if (responseString.isNotEmpty &&
        !responseString.startsWith('{') &&
        !responseString.contains('Instance of')) {
      return responseString;
    }

    return _getGenericFallback();
  }

  /// 봇 메시지 생성
  ChatMessage _createBotMessage({
    required String content,
    required String groupId,
    required BotType botType,
  }) {
    final botInfo = _getBotInfo(botType);

    return ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      groupId: groupId,
      content: content,
      senderId: botInfo.id,
      senderName: botInfo.name,
      senderImage: null,
      // 봇은 이미지 없음
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  /// 봇 정보 가져오기
  BotInfo _getBotInfo(BotType botType) {
    switch (botType) {
      case BotType.assistant:
        return BotInfo(
          id: 'bot_assistant',
          name: '🤖 AI 어시스턴트',
        );
      case BotType.researcher:
        return BotInfo(
          id: 'bot_researcher',
          name: '🔍 AI 리서처',
        );
      case BotType.counselor:
        return BotInfo(
          id: 'bot_counselor',
          name: '💬 AI 상담사',
        );
    }
  }

  /// 폴백 응답 생성
  String _getFallbackResponse(BotType botType) {
    final responses = _getFallbackResponses(botType);
    return responses[_random.nextInt(responses.length)];
  }

  /// 봇 타입별 폴백 응답 목록
  List<String> _getFallbackResponses(BotType botType) {
    switch (botType) {
      case BotType.assistant:
        return [
          "🤖 죄송해요, 지금은 네트워크 상태가 좋지 않아 답변이 어려워요. 잠시 후 다시 시도해주세요!",
          "💻 기술적인 문제로 응답이 지연되고 있어요. 조금만 기다려주세요!",
          "⚡ 시스템을 재정비 중이에요. 곧 더 나은 답변으로 돌아올게요!",
        ];
      case BotType.researcher:
        return [
          "🔍 정보를 수집하는 중에 문제가 발생했어요. 다시 질문해주시면 더 정확한 답변을 드릴게요!",
          "📊 데이터 분석 시스템에 일시적인 오류가 있어요. 잠시만 기다려주세요!",
          "🌐 외부 정보원 연결에 문제가 있어 답변이 어려워요. 다시 시도해주세요!",
        ];
      case BotType.counselor:
        return [
          "💙 지금은 제 시스템에 문제가 있어 충분한 답변을 드리기 어려워요. 하지만 당신의 고민을 듣고 있어요!",
          "🤗 기술적인 어려움이 있지만, 언제든 다시 이야기해주세요. 항상 여기 있을게요!",
          "✨ 일시적인 문제예요. 당신이 걱정하는 일들이 잘 해결되길 바라며, 곧 다시 대화해요!",
        ];
    }
  }

  /// 일반적인 폴백 메시지
  String _getGenericFallback() {
    return "죄송해요, 지금은 응답하기 어려워요. 잠시 후 다시 시도해주세요! 🤖";
  }

  /// 봇 메시지인지 확인
  bool _isBotMessage(String senderId) {
    return senderId.startsWith('bot_');
  }

  /// 멘션 감지 (@챗봇, @어시스턴트 등)
  bool shouldRespondToMessage(String message, BotType? activeBotType) {
    if (activeBotType == null) return false;

    final lowerMessage = message.toLowerCase();
    final botName = _getBotInfo(activeBotType).name.toLowerCase();

    // 멘션 패턴들
    final mentionPatterns = [
      '@챗봇',
      '@봇',
      '@ai',
      '@어시스턴트',
      '@assistant',
      '@리서처',
      '@researcher',
      '@상담사',
      '@counselor',
      botName,
    ];

    return mentionPatterns.any(
      (pattern) => lowerMessage.contains(pattern.toLowerCase()),
    );
  }
}

/// 봇 정보 클래스
class BotInfo {
  final String id;
  final String name;

  BotInfo({required this.id, required this.name});
}

/// 봇 타입 열거형
enum BotType {
  assistant, // 개발 어시스턴트
  researcher, // 리서치 봇
  counselor, // 상담 봇
}

/// 봇 타입 확장
extension BotTypeExtension on BotType {
  String get displayName {
    switch (this) {
      case BotType.assistant:
        return 'AI 어시스턴트';
      case BotType.researcher:
        return 'AI 리서처';
      case BotType.counselor:
        return 'AI 상담사';
    }
  }

  String get emoji {
    switch (this) {
      case BotType.assistant:
        return '🤖';
      case BotType.researcher:
        return '🔍';
      case BotType.counselor:
        return '💬';
    }
  }

  String get description {
    switch (this) {
      case BotType.assistant:
        return '개발 관련 질문, 코딩 도움';
      case BotType.researcher:
        return '정보 검색, 자료 조사';
      case BotType.counselor:
        return '고민 상담, 멘탈 케어';
    }
  }
}
