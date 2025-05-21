// lib/ai_assistance/module/study_tip_di.dart

import 'package:devlink_mobile_app/ai_assistance/module/quiz_di.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/data_source/study_tip_data_source.dart';
import '../data/repository_impl/study_tip_repository_impl.dart';
import '../domain/repository/study_tip_repository.dart';
import '../domain/use_case/get_study_tip_use_case.dart';
import '../module/vertex_client.dart';

// Vertex AI 클라이언트 프로바이더는 이미 quiz_di.dart에 정의되어 있으므로 재사용

// 데이터 소스 프로바이더
final studyTipDataSourceProvider = Provider<StudyTipDataSource>((ref) {
  final vertexClient = ref.watch(vertexAIClientProvider);
  return StudyTipDataSourceImpl(vertexClient: vertexClient);
});

// 리포지토리 프로바이더
final studyTipRepositoryProvider = Provider<StudyTipRepository>((ref) {
  final dataSource = ref.watch(studyTipDataSourceProvider);
  return StudyTipRepositoryImpl(dataSource: dataSource);
});

// 유스케이스 프로바이더
final getStudyTipUseCaseProvider = Provider<GetStudyTipUseCase>((ref) {
  final repository = ref.watch(studyTipRepositoryProvider);
  return GetStudyTipUseCase(repository: repository);
});

// 학습 팁 캐시 프로바이더 - 하루에 한 번만 갱신
final studyTipCacheProvider = StateProvider<Map<String, dynamic>>((ref) => {});