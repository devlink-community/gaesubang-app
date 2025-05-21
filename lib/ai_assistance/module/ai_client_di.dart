import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'vertex_client.dart';

/// 중앙 집중식 Vertex AI 클라이언트 프로바이더
/// 이 Provider는 app 전체에서 단일 인스턴스를 공유합니다.
final vertexAIClientProvider = Provider<VertexAIClient>((ref) {
  final client = VertexAIClient();

  // 초기화 트리거 - 앱 시작 시 한 번만 실행됩니다
  Future.microtask(() => client.initialize());

  // 앱 종료 시 리소스 정리
  ref.onDispose(() {
    client.dispose();
  });

  return client;
});