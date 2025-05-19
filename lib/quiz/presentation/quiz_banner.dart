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
  bool _isExpanded = false;

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColorStyles.primary100.withValues(alpha: 0.1),
                AppColorStyles.primary100.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: AppColorStyles.primary100.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: _buildQuizContent(quizAsync),
        ),
      ),
    );
  }

  Widget _buildQuizContent(AsyncValue<Quiz?> quizAsync) {
    return quizAsync.when(
      data: (quiz) => quiz != null ? _buildQuizCard(quiz) : _buildError(),
      loading:
          () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (error, _) => _buildError(),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColorStyles.error, size: 32),
            const SizedBox(height: 8),
            Text(
              '퀴즈를 불러오는 데 실패했습니다',
              style: AppTextStyles.body1Regular.copyWith(
                color: AppColorStyles.error,
              ),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed:
                  () => ref
                      .read(quizNotifierProvider.notifier)
                      .onAction(const LoadQuiz()),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColorStyles.primary100.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '오늘의 개발 퀴즈',
                  style: AppTextStyles.heading3Bold.copyWith(
                    color: AppColorStyles.primary100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColorStyles.primary100,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed:
                    () => ref
                        .read(quizNotifierProvider.notifier)
                        .onAction(const CloseQuiz()),
                color: AppColorStyles.gray80,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // 퀴즈 카테고리
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 16,
                color: AppColorStyles.primary100,
              ),
              const SizedBox(width: 4),
              Text(
                quiz.category,
                style: AppTextStyles.button2Regular.copyWith(
                  color: AppColorStyles.primary100,
                ),
              ),
            ],
          ),
        ),

        // 퀴즈 질문
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Text(
            quiz.question,
            style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 16),
          ),
        ),

        // 퀴즈 옵션들 (접힌 상태가 아닐 때만 표시)
        if (_isExpanded) ...[
          ...List.generate(quiz.options.length, (index) {
            final option = quiz.options[index];
            final isSelected = _selectedAnswerIndex == index;
            final isCorrect = quiz.correctAnswerIndex == index;
            final isAnswered = quiz.isAnswered;

            // 색상 결정
            Color backgroundColor = AppColorStyles.gray40;
            Color borderColor = AppColorStyles.gray40;
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
              backgroundColor = AppColorStyles.primary100.withValues(
                alpha: 0.15,
              );
              borderColor = AppColorStyles.primary100.withValues(alpha: 0.5);
              textColor = AppColorStyles.primary100;
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                    vertical: 12,
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
                        style: AppTextStyles.body2Regular.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option,
                          style: AppTextStyles.body2Regular.copyWith(
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isAnswered && isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      if (isAnswered && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.red, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 제출 버튼 또는 결과 설명
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                quiz.isAnswered
                    ? _buildExplanation(quiz)
                    : _buildSubmitButton(),
          ),
        ],

        // 접힌 상태이고, 아직 답변하지 않은 경우 "퀴즈 풀기" 버튼 표시
        if (!_isExpanded && !quiz.isAnswered)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorStyles.primary100,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  '퀴즈 풀기',
                  style: AppTextStyles.button2Regular.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // 접힌 상태이고, 이미 답변한 경우 결과 요약 표시
        if (!_isExpanded && quiz.isAnswered)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  quiz.attemptedAnswerIndex == quiz.correctAnswerIndex
                      ? Icons.check_circle
                      : Icons.cancel,
                  color:
                      quiz.attemptedAnswerIndex == quiz.correctAnswerIndex
                          ? Colors.green
                          : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quiz.attemptedAnswerIndex == quiz.correctAnswerIndex
                        ? '정답입니다!'
                        : '틀렸습니다. 정답은 ${String.fromCharCode(65 + quiz.correctAnswerIndex)}번입니다.',
                    style: AppTextStyles.body2Regular.copyWith(
                      color:
                          quiz.attemptedAnswerIndex == quiz.correctAnswerIndex
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  child: Text(
                    '더 보기',
                    style: AppTextStyles.button2Regular.copyWith(
                      color: AppColorStyles.primary100,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 48),
        disabledBackgroundColor: AppColorStyles.gray40,
      ),
      child: Text(
        '정답 제출하기',
        style: AppTextStyles.button1Medium.copyWith(color: Colors.white),
      ),
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
                size: 20,
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
          const SizedBox(height: 8),
          Text(
            '정답: ${String.fromCharCode(65 + quiz.correctAnswerIndex)}. ${quiz.options[quiz.correctAnswerIndex]}',
            style: AppTextStyles.body2Regular.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text('설명: ${quiz.explanation}', style: AppTextStyles.body2Regular),
        ],
      ),
    );
  }
}
