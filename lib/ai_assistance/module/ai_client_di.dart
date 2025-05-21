// lib/ai_assistance/module/ai_client_di.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'vertex_client.dart';

/// 중앙 집중식 Vertex AI 클라이언트 프로바이더
/// 이 Provider는 app 전체에서 단일 인스턴스를 공유합니다.
final vertexAIClientProvider = Provider<VertexAIClient>((ref) {
  final client = VertexAIClient();

  // 초기화는 프로바이더 생성 시 한 번만 수행
  // Future.microtask 대신 바로 초기화를 시작하여 지연 시간 단축
  client.initialize();

  // 앱 종료 시 리소스 정리
  ref.onDispose(() {
    client.dispose();
  });

  return client;
}, name: 'vertexAIClient'); // 이름 추가하여 디버깅 용이하게