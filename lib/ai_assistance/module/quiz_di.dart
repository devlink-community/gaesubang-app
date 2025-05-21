import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/data_source/quiz_data_source.dart';
import '../data/repository_impl/quiz_data_repository_impl.dart';
import '../domain/repository/quiz_repository.dart';
import '../domain/use_case/generate_quiz_use_case.dart';
import '../module/vertex_client.dart';

// Vertex AI 클라이언트 프로바이더
final vertexAIClientProvider = Provider<VertexAIClient>((ref) {
  final client = VertexAIClient();
  // 여기서 initialize()를 호출하면 됩니다. 비동기 메서드이지만 Provider는 동기식이므로
  // 클라이언트 생성시 초기화를 트리거하고, 실제 메서드는 나중에 호출될 수 있도록 함
  client.initialize(); // 비동기 초기화 트리거
  return client;
});

// 데이터 소스 프로바이더
final vertexAiDataSourceProvider = Provider<VertexAiDataSource>((ref) {
  final vertexClient = ref.watch(vertexAIClientProvider);
  return VertexAiDataSourceImpl(vertexClient: vertexClient);
});

// 리포지토리 프로바이더
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dataSource = ref.watch(vertexAiDataSourceProvider);
  return QuizRepositoryImpl(dataSource: dataSource);
});

// 유스케이스 프로바이더
final generateQuizUseCaseProvider = Provider<GenerateQuizUseCase>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return GenerateQuizUseCase(repository: repository);
});
