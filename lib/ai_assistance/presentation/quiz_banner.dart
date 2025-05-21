import 'dart:async';
import 'dart:math';

import 'package:devlink_mobile_app/ai_assistance/presentation/quiz_action.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_color_styles.dart';
import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
import '../module/quiz_di.dart';
import 'quiz_screen.dart';

class DailyQuizBanner extends ConsumerWidget {
  final String? skills;
  final Random _random = Random();

  DailyQuizBanner({super.key, this.skills});

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

    return '${skillList.join(", ")} 관련 지식을 테스트해보세요.';
  }

  // 스킬 목록 파싱 메서드 추가
  List<String> _parseSkillList(String? skills) {
    if (skills == null || skills.isEmpty) {
      return ['컴퓨터 기초'];
    }

    final skillList =
        skills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    debugPrint('파싱된 스킬 목록: $skillList');
    return skillList.isEmpty ? ['컴퓨터 기초'] : skillList;
  }

  void _handleQuizTap(BuildContext context, WidgetRef ref) async {
    // 디버그 로그 추가
    debugPrint('퀴즈 생성 시작: skills=$skills');

    // 스킬 목록 파싱 및 로그 출력
    final skillList = _parseSkillList(skills);
    debugPrint('파싱된 스킬 목록: $skillList (${skillList.length}개)');

    // 무작위 스킬 선택
    String selectedSkill;
    if (skillList.isEmpty) {
      selectedSkill = 'Flutter';
    } else {
      selectedSkill = skillList[_random.nextInt(skillList.length)];

      // 이상한 값이 들어온 경우를 필터링
      if (selectedSkill.length > 30 ||
          selectedSkill.contains('{') ||
          selectedSkill.contains('}') ||
          selectedSkill.contains(':')) {
        selectedSkill = 'Flutter';
      }
    }

    debugPrint('선택된 스킬: $selectedSkill');

    // 타임스탬프를 추가하여 캐시 방지
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final quizPrompt = '$selectedSkill-$currentTime';

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

        // 백업 퀴즈 표시 - 선택된 스킬 전달
        _showBackupQuiz(context, ref, selectedSkill);
      }
    });

    try {
      // 퀴즈 생성 UseCase 직접 사용
      final generateQuizUseCase = ref.read(generateQuizUseCaseProvider);

      // 타임스탬프를 추가하여 캐시 방지
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final quizPrompt = '$selectedSkill-$currentTime';

      debugPrint('퀴즈 생성 요청: $quizPrompt');

      // 퀴즈 생성 (타이머보다 먼저 완료되면 타이머 취소)
      final asyncQuizResult = await generateQuizUseCase.execute(quizPrompt);

      // 타이머 취소
      loadingTimer.cancel();

      // 로딩 다이얼로그 닫기
      _closeLoadingDialog(loadingDialogContext);

      // 퀴즈 결과 처리
      asyncQuizResult.when(
        data: (quiz) {
          if (context.mounted && quiz != null) {
            debugPrint(
              '퀴즈 생성 성공 (${quiz.relatedSkill}): ${quiz.question.substring(0, min(30, quiz.question.length))}...',
            );

            // 퀴즈 표시 - 원본 skills 목록 전달
            _showQuizDialog(context, ref, quiz);
          } else {
            // 백업 퀴즈 표시
            _showBackupQuiz(context, ref, selectedSkill);
          }
        },
        error: (error, _) {
          debugPrint('퀴즈 생성 오류: $error');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('퀴즈 생성 오류: $error'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );

            // 백업 퀴즈 표시
            _showBackupQuiz(context, ref, selectedSkill);
          }
        },
        loading: () {
          // 일반적으로 여기에 도달하지 않지만, 도달했다면 백업 퀴즈 표시
          _closeLoadingDialog(loadingDialogContext);
          _showBackupQuiz(context, ref, selectedSkill);
        },
      );
    } catch (e) {
      // 예외 발생 시 타이머 취소 및 백업 퀴즈 표시
      loadingTimer.cancel();
      _closeLoadingDialog(loadingDialogContext);

      debugPrint('퀴즈 생성 예외 발생: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예상치 못한 오류: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );

        // 백업 퀴즈 표시
        _showBackupQuiz(context, ref, selectedSkill);
      }
    }
  }

  // 로딩 다이얼로그 닫기 유틸리티 메서드
  void _closeLoadingDialog(BuildContext? dialogContext) {
    if (dialogContext != null && Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
  }

  // 퀴즈 표시 메서드
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
  void _showBackupQuiz(BuildContext context, WidgetRef ref, String skillArea) {
    debugPrint('백업 퀴즈 표시: 스킬=$skillArea');

    final fallbackQuiz = _generateFallbackQuiz(skillArea);
    _showQuizDialog(context, ref, fallbackQuiz);
  }

  // 백업 퀴즈 생성 메서드
  Quiz _generateFallbackQuiz(String skillArea) {
    // 해당 스킬에 맞는 퀴즈 생성
    if (skillArea.toLowerCase().contains('python')) {
      return Quiz(
        question: "Python에서 리스트 컴프리헨션의 주요 장점은 무엇인가요?",
        options: [
          "메모리 사용량 증가",
          "코드가 더 간결하고 가독성이 좋아짐",
          "항상 더 빠른 실행 속도",
          "버그 방지 기능",
        ],
        explanation:
            "리스트 컴프리헨션은 반복문과 조건문을 한 줄로 작성할 수 있어 코드가 더 간결해지고 가독성이 향상됩니다.",
        correctOptionIndex: 1,
        relatedSkill: "Python",
      );
    } else if (skillArea.toLowerCase().contains('flutter') ||
        skillArea.toLowerCase().contains('dart')) {
      return Quiz(
        question: "Flutter에서 StatefulWidget과 StatelessWidget의 주요 차이점은 무엇인가요?",
        options: [
          "StatefulWidget만 빌드 메서드를 가짐",
          "StatelessWidget이 더 성능이 좋음",
          "StatefulWidget은 내부 상태를 가질 수 있음",
          "StatelessWidget은 항상 더 적은 메모리를 사용함",
        ],
        explanation:
            "StatefulWidget은 내부 상태를 가지고 상태가 변경될 때 UI가 업데이트될 수 있지만, StatelessWidget은 불변이며 내부 상태를 가질 수 없습니다.",
        correctOptionIndex: 2,
        relatedSkill: "Flutter",
      );
    } else if (skillArea.toLowerCase().contains('javascript') ||
        skillArea.toLowerCase().contains('js')) {
      return Quiz(
        question: "JavaScript에서 const와 let의 주요 차이점은 무엇인가요?",
        options: [
          "const는 객체를 불변으로 만들지만, let은 가변 객체를 선언합니다.",
          "const로 선언된 변수는 재할당할 수 없지만, let은 가능합니다.",
          "const는 함수 스코프, let은 블록 스코프를 가집니다.",
          "const는 호이스팅되지 않지만, let은 호이스팅됩니다.",
        ],
        explanation:
            "const로 선언된 변수는 재할당할 수 없지만, let으로 선언된 변수는 재할당이 가능합니다. 둘 다 블록 스코프를 가집니다.",
        correctOptionIndex: 1,
        relatedSkill: "JavaScript",
      );
    } else if (skillArea.toLowerCase().contains('react')) {
      return Quiz(
        question: "React에서 hooks의 주요 규칙 중 하나는 무엇인가요?",
        options: [
          "클래스 컴포넌트에서만 사용 가능하다",
          "반복문, 조건문, 중첩 함수 내에서 호출해야 한다",
          "컴포넌트 내부 최상위 레벨에서만 호출해야 한다",
          "항상 useEffect 내부에서 호출해야 한다",
        ],
        explanation:
            "React Hooks는 컴포넌트 최상위 레벨에서만 호출해야 하며, 반복문, 조건문, 중첩 함수 내에서 호출하면 안 됩니다. 이는 React가 hooks의 호출 순서에 의존하기 때문입니다.",
        correctOptionIndex: 2,
        relatedSkill: "React",
      );
    }

    // 기본 컴퓨터 기초 퀴즈
    return Quiz(
      question: "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
      options: ["4비트", "8비트", "16비트", "32비트"],
      explanation: "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
      correctOptionIndex: 1,
      relatedSkill: skillArea,
    );
  }
}
