// lib/quiz/presentation/quiz_banner.dart

import 'package:devlink_mobile_app/quiz/presentation/quiz_action.dart';
import 'package:devlink_mobile_app/quiz/presentation/quiz_notifier.dart';
import 'package:devlink_mobile_app/quiz/presentation/quiz_state.dart';
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

  String? _currentSkills;

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

    _currentSkills = widget.skills;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuiz();
      _animController.forward();
    });
  }

  @override
  void didUpdateWidget(DailyQuizBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skills != widget.skills) {
      debugPrint(
        'DailyQuizBanner - 스킬 변경 감지: ${oldWidget.skills} -> ${widget.skills}',
      );
      _currentSkills = widget.skills;
      _loadQuiz();
    }
  }

  void _loadQuiz() {
    debugPrint('DailyQuizBanner - 퀴즈 로드 시작, 스킬 정보: $_currentSkills');
    ref
        .read(quizNotifierProvider.notifier)
        .onAction(QuizAction.loadQuiz(skills: _currentSkills));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    // final notifier = ref.watch(quizNotifierProvider.notifier); // notifier는 필요시 사용

    if (!quizState.showBanner) {
      return const SizedBox.shrink();
    }

    final bool hasCompletedQuiz = quizState.isAnswered;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: () => _showQuizPopup(context),
          child: Container(
            width: 280,
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
                  color: Colors.black.withOpacity(
                    0.15,
                  ), // withValues 대신 withOpacity 사용
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
                        color: Colors.white.withOpacity(
                          0.3,
                        ), // withValues 대신 withOpacity 사용
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
                    GestureDetector(
                      onTap: () {
                        _loadQuiz();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('퀴즈를 새로고침했습니다'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.2,
                          ), // withValues 대신 withOpacity 사용
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quiz icon (기존 코드 유지)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.2,
                        ), // withValues 대신 withOpacity 사용
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
                const Icon(Icons.psychology, color: Colors.white, size: 32),
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
    // QuizNotifier의 updateSelectedAnswer가 int?를 받도록 수정되었다고 가정합니다.
    ref.read(quizNotifierProvider.notifier).updateSelectedAnswer(null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuizBottomSheet(skills: _currentSkills),
    );
  }
}

class _QuizBottomSheet extends ConsumerWidget {
  // ConsumerWidget으로 변경
  final String? skills;

  const _QuizBottomSheet({Key? key, this.skills}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WidgetRef ref 추가
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
              Expanded(
                child: _QuizContent(
                  // ref를 명시적으로 전달할 필요 없음, _QuizContent가 ConsumerWidget이므로 내부에서 ref 사용 가능
                  scrollController: scrollController,
                  skills: skills,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuizContent extends ConsumerWidget {
  // ConsumerWidget으로 변경
  final ScrollController scrollController;
  final String? skills;

  const _QuizContent({Key? key, required this.scrollController, this.skills})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WidgetRef ref 추가
    final quizState = ref.watch(quizNotifierProvider);

    if (quizState.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('잠시만 기다려주세요...'),
          ],
        ),
      );
    }

    if (quizState.hasError) {
      // ref를 _buildErrorContent로 전달
      return _buildErrorContent(
        context,
        quizState.quizData.error?.toString() ?? '알 수 없는 오류',
        ref,
      );
    }

    if (quizState.quiz == null) {
      // ref를 _buildErrorContent로 전달 (퀴즈 데이터 없는 경우도 에러로 간주)
      return _buildErrorContent(context, '퀴즈 데이터를 불러올 수 없습니다', ref);
    }

    return _buildQuizDetails(context, quizState, ref); // ref 전달
  }

  // _buildErrorContent 메서드 시그니처 수정 (WidgetRef ref 파라미터 추가)
  Widget _buildErrorContent(
    BuildContext context,
    String errorMessage,
    WidgetRef ref,
  ) {
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
            const SizedBox(height: 8),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage,
                  style: AppTextStyles.body2Regular.copyWith(
                    color: AppColorStyles.error.withOpacity(
                      0.8,
                    ), // withValues 대신 withOpacity
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 현재 팝업이 있다면 닫기 (선택적)
                // if (Navigator.canPop(context)) {
                // Navigator.of(context).pop();
                // }
                // 새 퀴즈 로드
                ref // 이제 ref 사용 가능
                    .read(quizNotifierProvider.notifier)
                    .onAction(QuizAction.loadQuiz(skills: skills));
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

  // _buildQuizDetails 메서드 시그니처 수정 (WidgetRef ref 파라미터 추가)
  Widget _buildQuizDetails(
    BuildContext context,
    QuizState state,
    WidgetRef ref,
  ) {
    final Quiz quiz = state.quiz!;
    final isAnswered = state.isAnswered;
    final selectedIndex = state.selectedAnswerIndex;
    final notifier = ref.read(
      quizNotifierProvider.notifier,
    ); // 여기서 notifier 가져오기

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withOpacity(
                  0.1,
                ), // withValues 대신 withOpacity
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorStyles.primary100.withOpacity(
                    0.3,
                  ), // withValues 대신 withOpacity
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
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: () {
                // 현재 팝업이 있다면 닫기 (선택적)
                // if (Navigator.canPop(context)) {
                //   Navigator.of(context).pop();
                // }
                ref
                    .read(quizNotifierProvider.notifier)
                    .onAction(QuizAction.loadQuiz(skills: skills));
              },
              color: AppColorStyles.primary100,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: () => Navigator.of(context).pop(),
              color: AppColorStyles.gray80,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(quiz.question, style: AppTextStyles.heading6Bold),
        const SizedBox(height: 24),
        ...List.generate(quiz.options.length, (index) {
          final option = quiz.options[index];
          final isSelected = selectedIndex == index;
          final isCorrect = quiz.correctAnswerIndex == index;
          final userAnswered = quiz.attemptedAnswerIndex == index;

          Color backgroundColor = Colors.grey.shade100;
          Color borderColor = Colors.grey.shade300;
          Color textColor = AppColorStyles.textPrimary;

          if (isAnswered) {
            if (isCorrect) {
              backgroundColor = Colors.green.withOpacity(
                0.15,
              ); // withValues 대신 withOpacity
              borderColor = Colors.green.withOpacity(
                0.5,
              ); // withValues 대신 withOpacity
              textColor = Colors.green.shade800;
            } else if (userAnswered) {
              backgroundColor = Colors.red.withOpacity(
                0.15,
              ); // withValues 대신 withOpacity
              borderColor = Colors.red.withOpacity(
                0.5,
              ); // withValues 대신 withOpacity
              textColor = Colors.red.shade800;
            }
          } else if (isSelected) {
            backgroundColor = AppColorStyles.primary100.withOpacity(
              0.15,
            ); // withValues 대신 withOpacity
            borderColor = AppColorStyles.primary100.withOpacity(
              0.5,
            ); // withValues 대신 withOpacity
            textColor = AppColorStyles.primary100;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    isAnswered || state.isSubmitting
                        ? null
                        : () {
                          notifier.updateSelectedAnswer(index);
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
        if (!isAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed:
                  state.isSubmitting || selectedIndex == null
                      ? null
                      : () async {
                        // selectedIndex가 null이 아님을 확신할 수 있으므로 ! 사용 가능 (위 조건문에서 확인)
                        await notifier.onAction(SubmitAnswer(selectedIndex!));
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
                state.isSubmitting ? '제출 중...' : '정답 제출하기',
                style: AppTextStyles.button1Medium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (isAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildExplanation(quiz, state),
          ),
      ],
    );
  }

  Widget _buildExplanation(Quiz quiz, QuizState state) {
    final isCorrect = state.isCorrectAnswer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isCorrect
                ? Colors.green.withOpacity(0.1) // withValues 대신 withOpacity
                : Colors.red.withOpacity(0.1), // withValues 대신 withOpacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCorrect
                  ? Colors.green.withOpacity(0.3) // withValues 대신 withOpacity
                  : Colors.red.withOpacity(0.3), // withValues 대신 withOpacity
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1), // withValues 대신 withOpacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '카테고리: ${quiz.category}',
                  style: AppTextStyles.body2Regular,
                ),
                const SizedBox(height: 4),
                Text(
                  '사용자 스킬: ${skills ?? "없음"}', // skills 변수 사용
                  style: AppTextStyles.body2Regular,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
