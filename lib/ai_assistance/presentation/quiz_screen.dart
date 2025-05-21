import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_color_styles.dart';
import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
import 'quiz_action.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final String? skills;
  final Function(QuizAction)? onAction;

  const QuizScreen({super.key, required this.quiz, this.skills, this.onAction});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int? selectedAnswerIndex;
  bool hasAnswered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuestion(),
          const SizedBox(height: 16),
          _buildOptions(),
          if (hasAnswered) ...[const SizedBox(height: 16), _buildExplanation()],
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColorStyles.primary60.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.quiz.relatedSkill} 퀴즈',
            style: AppTextStyles.button2Regular.copyWith(
              color: AppColorStyles.primary80,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            if (widget.onAction != null) {
              widget.onAction!(const QuizAction.closeQuiz());
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.close, size: 24),
          color: Colors.grey[600],
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Text(widget.quiz.question, style: AppTextStyles.subtitle1Bold);
  }

  Widget _buildOptions() {
    return Column(
      children: List.generate(
        widget.quiz.options.length,
        (index) => _buildOptionItem(index),
      ),
    );
  }

  Widget _buildOptionItem(int index) {
    final option = widget.quiz.options[index];
    final isSelected = selectedAnswerIndex == index;
    final isCorrect = hasAnswered && index == widget.quiz.correctOptionIndex;
    final isWrong = hasAnswered && isSelected && !isCorrect;

    // 상태에 따른 색상 및 스타일 설정
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;

    if (isCorrect) {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green;
      textColor = Colors.green.shade800;
      trailingIcon = Icons.check_circle;
    } else if (isWrong) {
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      borderColor = Colors.red;
      textColor = Colors.red.shade800;
      trailingIcon = Icons.cancel;
    } else if (isSelected) {
      backgroundColor = AppColorStyles.primary60;
      borderColor = AppColorStyles.primary80;
      textColor = AppColorStyles.primary80;
      trailingIcon = null;
    } else {
      backgroundColor = Colors.grey.withValues(alpha: 0.05);
      borderColor = Colors.grey.withValues(alpha: 0.2);
      textColor = Colors.grey[800]!;
      trailingIcon = null;
    }

    return GestureDetector(
      onTap: hasAnswered ? null : () => _selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D...
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.body1Regular.copyWith(
                  color: textColor,
                  fontWeight: isCorrect || isSelected ? FontWeight.w500 : null,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '해설',
            style: AppTextStyles.captionRegular.copyWith(
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.quiz.explanation,
            style: AppTextStyles.body2Regular.copyWith(
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!hasAnswered) ...[
          ElevatedButton(
            onPressed:
                selectedAnswerIndex != null
                    ? () => _checkAnswer(selectedAnswerIndex!)
                    : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColorStyles.primary60.withAlpha(200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text('정답 확인', style: AppTextStyles.subtitle1Bold),
          ),
        ] else ...[
          OutlinedButton(
            onPressed: () {
              if (widget.onAction != null) {
                widget.onAction!(const QuizAction.closeQuiz());
              } else {
                Navigator.of(context).pop();
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorStyles.primary80,
              side: BorderSide(color: AppColorStyles.primary80),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '닫기',
              style: AppTextStyles.button2Regular.copyWith(
                color: AppColorStyles.primary80,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // 새로운 퀴즈 로드 액션 트리거
              if (widget.onAction != null) {
                widget.onAction!(QuizAction.loadQuiz(skills: widget.skills));
              }
              // 상태 초기화
              setState(() {
                selectedAnswerIndex = null;
                hasAnswered = false;
              });
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColorStyles.primary80,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text('새 퀴즈', style: AppTextStyles.button2Regular),
          ),
        ],
      ],
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswerIndex = index;
    });
  }

  void _checkAnswer(int index) {
    setState(() {
      hasAnswered = true;
    });

    // 답변 제출 액션 호출
    if (widget.onAction != null) {
      widget.onAction!(QuizAction.submitAnswer(index));
    }
  }
}
