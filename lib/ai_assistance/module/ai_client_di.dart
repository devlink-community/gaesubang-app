// lib/ai_assistance/module/ai_client_di.dart

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
// 도메인 모델 import
import '../domain/model/study_tip.dart';
import '../domain/model/quiz.dart';

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

//------------------------------------------------------------------
// 🆕 개선된 캐시 관리 시스템
//------------------------------------------------------------------

/// 🆕 학습 팁 캐시 프로바이더 - 더 효과적인 캐시 관리
final studyTipCacheProvider = StateProvider<Map<String, dynamic>>((ref) {
  // 초기 설정: 캐시 기간은 하루, 최대 20개 항목 저장
  return {};
});

/// 🆕 강제 새로고침용 학습 팁 프로바이더 (캐시 우회)
final freshStudyTipProvider = FutureProvider.autoDispose.family<StudyTip?, String?>((
    ref,
    skills,
    ) async {
  // 🔧 캐시를 완전히 우회하고 항상 새로운 데이터 생성
  final getStudyTipUseCase = ref.watch(getStudyTipUseCaseProvider);

  // 강제 새로고침을 위한 고유 타임스탬프 추가
  final forceRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
  final randomSalt = DateTime.now().microsecond; // 추가 무작위성
  final skillWithForceRefresh = '${skills ?? '프로그래밍 기초'}-fresh-$forceRefreshTimestamp-$randomSalt';

  try {
    final asyncValue = await getStudyTipUseCase.execute(skillWithForceRefresh);

    if (asyncValue.hasValue && asyncValue.value != null) {
      return asyncValue.value as StudyTip;
    }

    return null;
  } catch (e) {
    // 에러 발생 시 null 반환 (fallback 처리는 UI에서)
    return null;
  }
});

/// 🆕 강제 새로고침용 퀴즈 프로바이더 (캐시 우회)
final freshQuizProvider = FutureProvider.autoDispose.family<Quiz?, String?>((
    ref,
    skills,
    ) async {
  // 🔧 캐시를 완전히 우회하고 항상 새로운 데이터 생성
  final generateQuizUseCase = ref.watch(generateQuizUseCaseProvider);

  // 강제 새로고침을 위한 고유 타임스탬프 추가
  final forceRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
  final randomSalt = DateTime.now().microsecond; // 추가 무작위성
  final skillWithForceRefresh = '${skills ?? '프로그래밍 기초'}-fresh-$forceRefreshTimestamp-$randomSalt';

  try {
    final asyncValue = await generateQuizUseCase.execute(skillWithForceRefresh);

    return asyncValue.when(
      data: (quiz) => quiz,
      error: (_, __) => null,
      loading: () => null,
    );
  } catch (e) {
    // 에러 발생 시 null 반환 (fallback 처리는 UI에서)
    return null;
  }
});

//------------------------------------------------------------------
// 🆕 캐시 관리 유틸리티
//------------------------------------------------------------------

/// 🆕 캐시 정리 프로바이더 - 주기적으로 오래된 캐시 정리
final cacheCleanupProvider = Provider((ref) {
  // 캐시 정리 로직을 제공하는 유틸리티
  return CacheCleanupService(ref);
});

/// 🆕 캐시 정리 서비스 클래스
class CacheCleanupService {
  final Ref _ref;

  CacheCleanupService(this._ref);

  /// 오래된 캐시 항목 정리 (1시간 이상 된 항목)
  void cleanupOldCacheEntries() {
    final currentCache = Map<String, dynamic>.from(
      _ref.read(studyTipCacheProvider),
    );

    final now = DateTime.now();
    final cutoffTime = now.subtract(const Duration(hours: 1));

    // 캐시 키에서 타임스탬프 추출하여 오래된 항목 제거
    final keysToRemove = <String>[];

    for (final key in currentCache.keys) {
      // 캐시 키 형식: "YYYY-MM-DD-skillPrefix-timeSlot"
      final parts = key.split('-');
      if (parts.length >= 3) {
        try {
          final dateStr = '${parts[0]}-${parts[1]}-${parts[2]}';
          final cacheDate = DateTime.parse(dateStr);

          if (cacheDate.isBefore(cutoffTime)) {
            keysToRemove.add(key);
          }
        } catch (e) {
          // 파싱 실패 시 해당 항목 제거
          keysToRemove.add(key);
        }
      }
    }

    // 오래된 항목들 제거
    for (final key in keysToRemove) {
      currentCache.remove(key);
    }

    // 캐시 크기 제한 (최대 15개로 감소)
    if (currentCache.length > 15) {
      final sortedKeys = currentCache.keys.toList()..sort();
      final keysToRemoveForLimit = sortedKeys.take(currentCache.length - 15);

      for (final key in keysToRemoveForLimit) {
        currentCache.remove(key);
      }
    }

    // 업데이트된 캐시 저장
    _ref.read(studyTipCacheProvider.notifier).state = currentCache;
  }

  /// 특정 스킬의 캐시 무효화
  void invalidateCacheForSkill(String? skills) {
    final currentCache = Map<String, dynamic>.from(
      _ref.read(studyTipCacheProvider),
    );

    final skillArea = skills
        ?.split(',')
        .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
        .trim() ?? '프로그래밍 기초';

    final skillPrefix = skillArea.length > 3 ? skillArea.substring(0, 3) : skillArea;

    // 해당 스킬과 관련된 캐시 항목들 제거
    final keysToRemove = currentCache.keys
        .where((key) => key.contains(skillPrefix))
        .toList();

    for (final key in keysToRemove) {
      currentCache.remove(key);
    }

    // 업데이트된 캐시 저장
    _ref.read(studyTipCacheProvider.notifier).state = currentCache;
  }

  /// 전체 캐시 초기화
  void clearAllCache() {
    _ref.read(studyTipCacheProvider.notifier).state = {};
  }
}