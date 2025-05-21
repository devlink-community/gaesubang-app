import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
import '../module/quiz_di.dart';

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


class DailyQuizBanner extends ConsumerWidget {
  final String? skills;

  const DailyQuizBanner({super.key, this.skills});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuiz = ref.watch(quizProvider(skills));

    return Container(
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
        mainAxisSize: MainAxisSize.min, // 추가: 컬럼이 필요한 만큼만 공간 차지하도록
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
          const SizedBox(height: 16),
          Expanded(child: _buildQuizContent(asyncQuiz, context)),
        ],
      ),
    );
  }

  Widget _buildQuizContent(AsyncValue<Quiz?> asyncQuiz, BuildContext context) {
    return asyncQuiz.when(
      data: (quiz) {
        if (quiz == null) {
          return _buildErrorState('퀴즈를 불러올 수 없습니다');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                // 추가: 길이가 긴 텍스트를 스크롤 가능하도록
                child: Text(
                  quiz.question,
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: Colors.white,
                  ),
                  // maxLines 제거: 길이가 긴 텍스트도 표시되도록
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '답을 확인하려면 클릭하세요',
              style: AppTextStyles.button2Regular.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 퀴즈 상세 페이지로 이동 로직
                  _showQuizDetailsDialog(context, quiz);
                },
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
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
      error: (error, stack) => _buildErrorState('오류: $error'),
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.white.withValues(alpha: 0.7),
          size: 32,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              message,
              style: AppTextStyles.body2Regular.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // 재시도 로직
            },
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
              '다시 시도',
              style: AppTextStyles.button2Regular.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 퀴즈 상세 다이얼로그 표시
  void _showQuizDetailsDialog(BuildContext context, Quiz quiz) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('퀴즈', style: AppTextStyles.subtitle1Bold),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.question,
                    style: AppTextStyles.body1Regular.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    quiz.options.length,
                    (index) => _buildOptionItem(
                      context,
                      quiz.options[index],
                      index,
                      quiz.correctOptionIndex,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '해설:',
                    style: AppTextStyles.body2Regular.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(quiz.explanation, style: AppTextStyles.body2Regular),
                  if (quiz.relatedSkill.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '관련 기술: ${quiz.relatedSkill}',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  // 선택지 아이템 위젯
  Widget _buildOptionItem(
    BuildContext context,
    String option,
    int index,
    int correctIndex,
  ) {
    final isCorrect = index == correctIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isCorrect
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.grey,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index), // A, B, C, D로 표시
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option,
              style: AppTextStyles.body2Regular.copyWith(
                color: isCorrect ? Colors.green : Colors.black,
                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}
