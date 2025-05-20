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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizNotifierProvider);
    final notifier = ref.watch(quizNotifierProvider.notifier);

    // 배너를 표시하지 않는 경우
    if (!notifier.showBanner) {
      return const SizedBox.shrink();
    }

    // 퀴즈 참여 여부 확인 (퀴즈가 로드되었고 이미 참여한 경우 버튼 텍스트 변경)
    bool hasCompletedQuiz = false;
    if (quizAsync case AsyncData(:final value)) {
      hasCompletedQuiz = value?.isAnswered ?? false;
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
                    // 이미 완료한 경우 "참여 완료"로 표시, 그렇지 않으면 "퀴즈 풀기"
                    hasCompletedQuiz ? '참여 완료' : '퀴즈 풀기',
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
    // 퀴즈 팝업 표시하기 전에 선택된 인덱스 초기화
    setState(() {
      _selectedAnswerIndex = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _QuizBottomSheet(
            skills: widget.skills,
            initialSelectedIndex: _selectedAnswerIndex,
            onAnswerSelected: (index) {
              setState(() {
                _selectedAnswerIndex = index;
              });
            },
          ),
    );
  }
}

// 퀴즈 바텀 시트를 별도 위젯으로 분리
class _QuizBottomSheet extends ConsumerStatefulWidget {
  final String? skills;
  final int? initialSelectedIndex;
  final Function(int) onAnswerSelected;

  const _QuizBottomSheet({
    Key? key,
    this.skills,
    this.initialSelectedIndex,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  ConsumerState<_QuizBottomSheet> createState() => _QuizBottomSheetState();
}

class _QuizBottomSheetState extends ConsumerState<_QuizBottomSheet> {
  int? _selectedAnswerIndex;

  @override
  void initState() {
    super.initState();
    _selectedAnswerIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              Expanded(child: _buildQuizContent(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizContent(ScrollController scrollController) {
    final quizAsync = ref.watch(quizNotifierProvider);

    return quizAsync.when(
      data:
          (quiz) =>
              quiz != null
                  ? _buildQuizDetails(quiz, scrollController)
                  : _buildErrorContent(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorContent(),
    );
  }

  Widget _buildErrorContent() {
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

  Widget _buildQuizDetails(Quiz quiz, ScrollController scrollController) {
    final isAnswered = quiz.isAnswered;

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
          final userAnswered = quiz.attemptedAnswerIndex == index;

          // 색상 결정
          Color backgroundColor = Colors.grey.shade100;
          Color borderColor = Colors.grey.shade300;
          Color textColor = AppColorStyles.textPrimary;

          if (isAnswered) {
            if (isCorrect) {
              backgroundColor = Colors.green.withValues(alpha: 0.15);
              borderColor = Colors.green.withValues(alpha: 0.5);
              textColor = Colors.green.shade800;
            } else if (userAnswered) {
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    isAnswered
                        ? null
                        : () {
                          setState(() {
                            _selectedAnswerIndex = index;
                            debugPrint('선택한 답변: $index');
                          });
                          widget.onAnswerSelected(index);
                        },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
                        if (isAnswered && userAnswered && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        // 제출 버튼 또는 결과 설명
        if (!isAnswered)
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
        if (isAnswered)
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
