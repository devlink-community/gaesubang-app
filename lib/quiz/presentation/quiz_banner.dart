import 'package:devlink_mobile_app/quiz/presentation/quiz_action.dart';
import 'package:devlink_mobile_app/quiz/presentation/quiz_notifier.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';

class DailyQuizBanner extends ConsumerStatefulWidget {
  final String? skills;

  const DailyQuizBanner({Key? key, this.skills}) : super(key: key);

  @override
  ConsumerState<DailyQuizBanner> createState() => _DailyQuizBannerState();
}

class _DailyQuizBannerState extends ConsumerState<DailyQuizBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int? _selectedAnswerIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    // 컴포넌트 마운트 시 퀴즈 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizNotifierProvider.notifier).onAction(const LoadQuiz());
      _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizNotifierProvider);
    final notifier = ref.watch(quizNotifierProvider.notifier);

    // 배너를 표시하지 않는 경우
    if (!notifier.showBanner) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: () => _showQuizPopup(context),
          child: Container(
            width: 280, // 고정 너비 설정
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade400, Colors.purple.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
                        '오늘의 개발 퀴즈',
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
                        Icons.quiz,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.psychology, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  '개발 지식을 테스트해보세요',
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _showQuizPopup(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.purple.shade700,
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
            ),
          ),
        ),
      ),
    );
  }

  void _showQuizPopup(BuildContext context) {
    final quizAsync = ref.read(quizNotifierProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: quizAsync.when(
                          data:
                              (quiz) =>
                                  quiz != null
                                      ? _buildQuizContent(
                                        context,
                                        quiz,
                                        scrollController,
                                      )
                                      : _buildErrorContent(context),
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error: (_, __) => _buildErrorContent(context),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColorStyles.error, size: 48),
            const SizedBox(height: 16),
            Text(
              '퀴즈를 불러오는 데 실패했습니다',
              style: AppTextStyles.subtitle1Bold.copyWith(
                color: AppColorStyles.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(quizNotifierProvider.notifier)
                    .onAction(const LoadQuiz());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorStyles.primary100,
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent(
    BuildContext context,
    Quiz quiz,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // 헤더
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorStyles.primary100.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                quiz.category,
                style: AppTextStyles.button2Regular.copyWith(
                  color: AppColorStyles.primary100,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: () => Navigator.of(context).pop(),
              color: AppColorStyles.gray80,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 퀴즈 질문
        Text(quiz.question, style: AppTextStyles.heading6Bold),
        const SizedBox(height: 24),

        // 퀴즈 옵션들
        ...List.generate(quiz.options.length, (index) {
          final option = quiz.options[index];
          final isSelected = _selectedAnswerIndex == index;
          final isCorrect = quiz.correctAnswerIndex == index;
          final isAnswered = quiz.isAnswered;

          // 색상 결정
          Color backgroundColor = Colors.grey.shade100;
          Color borderColor = Colors.grey.shade300;
          Color textColor = AppColorStyles.textPrimary;

          if (isAnswered) {
            if (isCorrect) {
              backgroundColor = Colors.green.withValues(alpha: 0.15);
              borderColor = Colors.green.withValues(alpha: 0.5);
              textColor = Colors.green.shade800;
            } else if (isSelected) {
              backgroundColor = Colors.red.withValues(alpha: 0.15);
              borderColor = Colors.red.withValues(alpha: 0.5);
              textColor = Colors.red.shade800;
            }
          } else if (isSelected) {
            backgroundColor = AppColorStyles.primary100.withValues(alpha: 0.15);
            borderColor = AppColorStyles.primary100.withValues(alpha: 0.5);
            textColor = AppColorStyles.primary100;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap:
                  isAnswered
                      ? null
                      : () {
                        setState(() {
                          _selectedAnswerIndex = index;
                        });
                      },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + index)}.',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: AppTextStyles.body1Regular.copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isAnswered && isCorrect)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    if (isAnswered && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: Colors.red, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),

        // 제출 버튼 또는 결과 설명
        if (!quiz.isAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed:
                  _selectedAnswerIndex == null
                      ? null
                      : () {
                        // 답변 제출
                        ref
                            .read(quizNotifierProvider.notifier)
                            .onAction(SubmitAnswer(_selectedAnswerIndex!));

                        // 팝업은 유지하고 상태만 업데이트
                        setState(() {});
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorStyles.primary100,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
                disabledBackgroundColor: AppColorStyles.gray40,
              ),
              child: Text(
                '정답 제출하기',
                style: AppTextStyles.button1Medium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // 설명 (정답 제출 후)
        if (quiz.isAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildExplanation(quiz),
          ),
      ],
    );
  }

  Widget _buildExplanation(Quiz quiz) {
    final isCorrect = quiz.attemptedAnswerIndex == quiz.correctAnswerIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isCorrect
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCorrect
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? '정답입니다!' : '틀렸습니다!',
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color:
                      isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '정답: ${String.fromCharCode(65 + quiz.correctAnswerIndex)}. ${quiz.options[quiz.correctAnswerIndex]}',
            style: AppTextStyles.body1Regular.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text('설명: ${quiz.explanation}', style: AppTextStyles.body1Regular),
        ],
      ),
    );
  }
}
