import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
import '../module/quiz_di.dart';

final quizProvider = FutureProvider.autoDispose.family<Quiz?, String?>((
  ref,
  skills,
) async {
  // 퀴즈 생성
  final generateQuizUseCase = ref.watch(generateQuizUseCaseProvider);
  final skillArea =
      skills
          ?.split(',')
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '컴퓨터 기초')
          .trim() ??
      '컴퓨터 기초';

  try {
    final asyncValue = await generateQuizUseCase.execute(skillArea);
    return asyncValue.value;
  } catch (e) {
    print('퀴즈 생성 중 오류: $e');
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
          _buildQuizContent(asyncQuiz),
        ],
      ),
    );
  }

  Widget _buildQuizContent(AsyncValue<Quiz?> asyncQuiz) {
    return Expanded(
      child: asyncQuiz.when(
        data: (quiz) {
          if (quiz == null) {
            return _buildErrorState('퀴즈를 불러올 수 없습니다');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.question,
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: Colors.white,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '답을 확인하려면 클릭하세요',
                style: AppTextStyles.button2Regular.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: 퀴즈 상세 페이지로 이동
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 40),
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
      ),
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
        Text(
          message,
          style: AppTextStyles.body2Regular.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            // TODO: 재시도 기능
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.teal.shade700,
            backgroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 40),
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
      ],
    );
  }
}
