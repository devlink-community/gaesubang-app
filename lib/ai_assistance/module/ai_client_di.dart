// lib/ai_assistance/module/ai_assistance_di.dart

import 'package:devlink_mobile_app/ai_assistance/module/quiz_prompt.dart';
import 'package:devlink_mobile_app/ai_assistance/module/vertex_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 데이터 소스 import
import '../data/data_source/fallback_service.dart';
import '../data/data_source/quiz_data_source.dart';
import '../data/data_source/study_tip_data_source.dart';
// 레포지토리 구현체 import
import '../data/repository_impl/quiz_data_repository_impl.dart';
import '../data/repository_impl/study_tip_repository_impl.dart';
// 도메인 레포지토리 인터페이스 import
import '../domain/repository/quiz_repository.dart';
import '../domain/repository/study_tip_repository.dart';
// 유스케이스 import
import '../domain/use_case/generate_quiz_use_case.dart';
import '../domain/use_case/get_study_tip_use_case.dart';

//------------------------------------------------------------------
// 서비스 프로바이더
//------------------------------------------------------------------
/// 프롬프트 생성 서비스 프로바이더
final promptServiceProvider = Provider<PromptService>((ref) {
  return PromptService();
});

/// 폴백 서비스 프로바이더
final fallbackServiceProvider = Provider<FallbackService>((ref) {
  return FallbackService();
});

//------------------------------------------------------------------
// Firebase AI 클라이언트 프로바이더
//------------------------------------------------------------------
/// 중앙 집중식 Firebase AI 클라이언트 프로바이더
/// 이 Provider는 app 전체에서 단일 인스턴스를 공유합니다.
final firebaseAIClientProvider = Provider<FirebaseAIClient>((ref) {
  final client = FirebaseAIClient();

  // 초기화 트리거 - 앱 시작 시 한 번만 실행됩니다
  Future.microtask(() => client.initialize());

  // 앱 종료 시 리소스 정리
  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

//------------------------------------------------------------------
// 퀴즈 관련 프로바이더
//------------------------------------------------------------------
/// 퀴즈 데이터 소스 프로바이더
final vertexAiDataSourceProvider = Provider<FirebaseAiDataSource>((ref) {
  final firebaseAIClient = ref.watch(firebaseAIClientProvider);
  final fallbackService = ref.watch(fallbackServiceProvider);
  final promptService = ref.watch(promptServiceProvider);

  return VertexAiDataSourceImpl(
    firebaseAIClient: firebaseAIClient,
    fallbackService: fallbackService,
    promptService: promptService,
  );
});

/// 퀴즈 리포지토리 프로바이더
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dataSource = ref.watch(vertexAiDataSourceProvider);
  final promptService = ref.watch(promptServiceProvider);

  return QuizRepositoryImpl(
    dataSource: dataSource,
    promptService: promptService,
  );
});

/// 퀴즈 생성 유스케이스 프로바이더
final generateQuizUseCaseProvider = Provider<GenerateQuizUseCase>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return GenerateQuizUseCase(repository: repository);
});

//------------------------------------------------------------------
// 학습 팁 관련 프로바이더
//------------------------------------------------------------------
/// 학습 팁 데이터 소스 프로바이더
final studyTipDataSourceProvider = Provider<StudyTipDataSource>((ref) {
  final firebaseAIClient = ref.watch(firebaseAIClientProvider);
  final fallbackService = ref.watch(fallbackServiceProvider);
  final promptService = ref.watch(promptServiceProvider);

  return StudyTipDataSourceImpl(
    firebaseAIClient: firebaseAIClient,
    fallbackService: fallbackService,
    promptService: promptService,
  );
});

/// 학습 팁 리포지토리 프로바이더
final studyTipRepositoryProvider = Provider<StudyTipRepository>((ref) {
  final dataSource = ref.watch(studyTipDataSourceProvider);
  final promptService = ref.watch(promptServiceProvider);

  return StudyTipRepositoryImpl(
    dataSource: dataSource,
    promptService: promptService,
  );
});

/// 학습 팁 유스케이스 프로바이더
final getStudyTipUseCaseProvider = Provider<GetStudyTipUseCase>((ref) {
  final repository = ref.watch(studyTipRepositoryProvider);
  return GetStudyTipUseCase(repository: repository);
});

/// 학습 팁 캐시 프로바이더 - 더 효과적인 캐싱을 위한 최대 항목 수 제한 추가
final studyTipCacheProvider = StateProvider<Map<String, dynamic>>((ref) {
  // 초기 설정: 캐시 기간은 하루, 최대 10개 항목 저장
  return {};
});
