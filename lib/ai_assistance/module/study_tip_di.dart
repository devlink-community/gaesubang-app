import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/data_source/study_tip_data_source.dart';
import '../data/repository_impl/study_tip_repository_impl.dart';
import '../domain/repository/study_tip_repository.dart';
import '../domain/use_case/get_study_tip_use_case.dart';
import 'ai_client_di.dart'; // 새로운 중앙 Provider import

// 데이터 소스 프로바이더
final studyTipDataSourceProvider = Provider<StudyTipDataSource>((ref) {
  final vertexClient = ref.watch(vertexAIClientProvider); // 중앙 Provider 사용
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

// 학습 팁 캐시 프로바이더 - 더 효과적인 캐싱을 위한 최대 항목 수 제한 추가
final studyTipCacheProvider = StateProvider<Map<String, dynamic>>((ref) {
  // 초기 설정: 캐시 기간은 하루, 최대 10개 항목 저장
  return {};
});