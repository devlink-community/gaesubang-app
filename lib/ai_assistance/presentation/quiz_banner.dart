import 'dart:async';

import 'package:devlink_mobile_app/ai_assistance/presentation/quiz_action.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_color_styles.dart';
import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
import '../module/quiz_di.dart';
<<<<<<< HEAD
<<<<<<< HEAD

// 캐시 관리를 위한 상태 Provider 추가
final quizCacheProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// 캐시 키 기반 FutureProvider 개선
final quizProvider = FutureProvider.autoDispose.family<Quiz?, String?>((
    ref,
    skills,
    ) async {
  // 캐시 키 - 오늘 날짜 + 스킬 (첫 3글자만)
  final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
  final skillArea =
      skills?.split(',')
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '컴퓨터 기초')
          .trim() ??
          '컴퓨터 기초';

  // 스킬 첫 3글자만 사용하여 잦은 캐시 미스 방지
  final skillPrefix = skillArea.length > 3 ? skillArea.substring(0, 3) : skillArea;
  final cacheKey = '$today-$skillPrefix';

  // 디버그 정보
  debugPrint('Quiz 캐시 키: $cacheKey 확인 중');

  // 캐시된 데이터 확인
  final cache = ref.read(quizCacheProvider);
  if (cache.containsKey(cacheKey)) {
    debugPrint('Quiz 캐시 히트: $cacheKey');
    return cache[cacheKey] as Quiz?;
  }

  debugPrint('Quiz 캐시 미스: $cacheKey, API 호출 필요');

  try {
    // 캐시 없으면 새로 생성
    final generateQuizUseCase = ref.watch(generateQuizUseCaseProvider);
    final asyncValue = await generateQuizUseCase.execute(skillArea);

    // 값이 있으면 캐시에 저장
    if (asyncValue.hasValue) {
      final quiz = asyncValue.value;
      debugPrint('Quiz 생성 성공, 캐시에 저장: $cacheKey');

      // 캐시 크기 제한 확인 (최대 10개 항목)
      final currentCache = Map<String, dynamic>.from(ref.read(quizCacheProvider));
      if (currentCache.length >= 10) {
        // 가장 오래된 항목 하나 제거
        final oldestKey = currentCache.keys.first;
        currentCache.remove(oldestKey);
        debugPrint('Quiz 캐시 정리: 오래된 항목 제거 $oldestKey');
      }

      // 새 항목 추가
      currentCache[cacheKey] = quiz;
      ref.read(quizCacheProvider.notifier).state = currentCache;

      return quiz;
    }

    return null;
  } catch (e) {
    debugPrint('퀴즈 생성 중 오류: $e');
    return null;
  }
});
=======
import 'quiz_action.dart';
import 'quiz_notifier.dart';
=======
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
import 'quiz_screen.dart';
>>>>>>> 65e0a3e8 (quiz: banner 수정:)


class DailyQuizBanner extends ConsumerWidget {
  final String? skills;

  const DailyQuizBanner({super.key, this.skills});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleQuizTap(context, ref),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade400, Colors.teal.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '오늘의 퀴즈',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '오늘의 개발 퀴즈를 풀어보세요!',
              style: AppTextStyles.subtitle1Bold.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _getSkillDescription(skills),
              style: AppTextStyles.body2Regular.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleQuizTap(context, ref),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '퀴즈 풀기',
                  style: AppTextStyles.button2Regular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSkillDescription(String? skills) {
    if (skills == null || skills.isEmpty) {
      return '개발자라면 알아야 할 컴퓨터 기초 지식을 테스트해보세요.';
    }

    final skillList =
        skills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    if (skillList.isEmpty) {
      return '개발자라면 알아야 할 컴퓨터 기초 지식을 테스트해보세요.';
    }

    if (skillList.length == 1) {
      return '${skillList[0]} 관련 지식을 테스트해보세요.';
    }

    return '${skillList[0]}와 관련 기술에 대한 지식을 테스트해보세요.';
  }

  void _handleQuizTap(BuildContext context, WidgetRef ref) async {
    // 대화상자 컨텍스트 추적을 위한 변수
    BuildContext? loadingDialogContext;

    // 로딩 타이머 및 리스너 관리를 위한 변수
    Timer? loadingTimer;

    // 로딩 다이얼로그에 고유 키 부여
    final loadingDialogKey = UniqueKey();

    // 퀴즈 로딩 중 표시할 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // 다이얼로그 컨텍스트 저장
        loadingDialogContext = dialogContext;

        return Dialog(
          key: loadingDialogKey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColorStyles.primary80,
                  ),
                ),
                const SizedBox(height: 24),
                Text('퀴즈를 준비하고 있습니다...', style: AppTextStyles.subtitle1Bold),
                const SizedBox(height: 8),
                Text(
                  '잠시만 기다려주세요.',
                  style: AppTextStyles.body2Regular.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 타임아웃 설정 (20초)
    loadingTimer = Timer(const Duration(seconds: 20), () {
      _closeLoadingDialog(loadingDialogContext);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퀴즈 로딩이 지연되고 있습니다. 기본 퀴즈를 표시합니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 백업 퀴즈 표시
        _showBackupQuiz(context, ref);
      }
    });

    try {
      // 퀴즈 생성 UseCase 직접 사용
      final generateQuizUseCase = ref.read(generateQuizUseCaseProvider);
      final selectedSkill =
          skills
              ?.split(',')
              .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '컴퓨터 기초')
              .trim() ??
          '컴퓨터 기초';

      // 퀴즈 생성 (타이머보다 먼저 완료되면 타이머 취소)
      final asyncQuizResult = await generateQuizUseCase.execute(selectedSkill);

      // 타이머 취소
      loadingTimer.cancel();

      // 로딩 다이얼로그 닫기
      _closeLoadingDialog(loadingDialogContext);

      // 퀴즈 결과 처리
      asyncQuizResult.when(
        data: (quiz) {
          if (context.mounted && quiz != null) {
            // 퀴즈 표시
            _showQuizDialog(context, ref, quiz);
          } else {
            // 백업 퀴즈 표시
            _showBackupQuiz(context, ref);
          }
        },
        error: (error, _) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('퀴즈 생성 오류: $error'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );

            // 백업 퀴즈 표시
            _showBackupQuiz(context, ref);
          }
        },
        loading: () {
          // 일반적으로 여기에 도달하지 않지만, 도달했다면 백업 퀴즈 표시
          _closeLoadingDialog(loadingDialogContext);
          _showBackupQuiz(context, ref);
        },
      );
    } catch (e) {
      // 예외 발생 시 타이머 취소 및 백업 퀴즈 표시
      loadingTimer.cancel();
      _closeLoadingDialog(loadingDialogContext);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예상치 못한 오류: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );

        // 백업 퀴즈 표시
        _showBackupQuiz(context, ref);
      }
    }
  }

  // 로딩 다이얼로그 닫기 유틸리티 메서드
  void _closeLoadingDialog(BuildContext? dialogContext) {
    if (dialogContext != null && Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
  }

  // 퀴즈 표시 메서드 - 이 부분이 변경됨
  void _showQuizDialog(BuildContext context, WidgetRef ref, Quiz quiz) {
    // StatefulWidget의 상태를 초기화하기 위한 키 생성
    final uniqueKey = UniqueKey();

    showDialog(
      context: context,
      barrierDismissible: true, // 바탕 클릭으로 닫기 가능
      builder: (dialogContext) {
        // 화면 크기를 가져와서 다이얼로그 크기를 적절히 조정
        final screenSize = MediaQuery.of(context).size;

        return Dialog(
          key: uniqueKey, // 매번 새로운 키 사용으로 상태 리셋 보장
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // 화면의 최대 90%까지 확장 가능하도록 설정
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: screenSize.height * 0.05,
          ),
          // 크기 제한을 좀 더 넓게 설정
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.9,
              maxHeight: screenSize.height * 0.8,
            ),
            child: QuizScreen(
              key: uniqueKey, // QuizScreen에도 고유 키 전달
              quiz: quiz,
              skills: skills,
              onAction: (action) {
                switch (action) {
                  case LoadQuiz(:final skills):
                    // 현재 다이얼로그 닫기
                    Navigator.of(dialogContext).pop();

                    // 약간의 지연 후 새 퀴즈 로딩 다이얼로그 표시
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (context.mounted) {
                        // 새 퀴즈 로딩 시작
                        _handleQuizTap(context, ref);
                      }
                    });
                    break;

                  case SubmitAnswer(:final answerIndex):
                    // 답변 제출은 QuizScreen에서 로컬로 처리
                    break;

                  case CloseQuiz():
                    Navigator.of(dialogContext).pop();
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  // 백업 퀴즈 표시 메서드
  void _showBackupQuiz(BuildContext context, WidgetRef ref) {
    final fallbackQuiz = Quiz(
      question: "프로그래밍에서 변수명 작성 규칙으로 올바른 것은?",
      options: [
        "변수명은 숫자로 시작할 수 있다",
        "변수명에는 공백이 포함될 수 있다",
        "변수명은 대소문자를 구분한다",
        "변수명에는 특수문자(%, &, #)를 자유롭게 사용할 수 있다",
      ],
      explanation:
          "대부분의 프로그래밍 언어에서 변수명은 대소문자를 구분합니다. 예를 들어 'name'과 'Name'은 서로 다른 변수로 취급됩니다.",
      correctOptionIndex: 2,
      relatedSkill:
          skills
              ?.split(',')
              .firstWhere(
                (s) => s.trim().isNotEmpty,
                orElse: () => '프로그래밍 기초',
              ) ??
          '프로그래밍 기초',
    );

    _showQuizDialog(context, ref, fallbackQuiz);
  }
}
