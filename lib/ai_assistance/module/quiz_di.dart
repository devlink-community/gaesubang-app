import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/data_source/quiz_data_source.dart';
import '../data/repository_impl/quiz_data_repository_impl.dart';
import '../domain/repository/quiz_repository.dart';
import '../domain/use_case/generate_quiz_use_case.dart';

final vertexAiDataSourceProvider = Provider<VertexAiDataSource>((ref) {
  final remoteConfig = FirebaseRemoteConfig.instance;
  return VertexAiDataSourceImpl(remoteConfig: remoteConfig);
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dataSource = ref.watch(vertexAiDataSourceProvider);
  return QuizRepositoryImpl(dataSource: dataSource);
});

final generateQuizUseCaseProvider = Provider<GenerateQuizUseCase>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return GenerateQuizUseCase(repository: repository);
});
