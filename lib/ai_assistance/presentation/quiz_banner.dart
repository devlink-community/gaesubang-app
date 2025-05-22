import 'dart:async';
import 'dart:math';

import 'package:devlink_mobile_app/ai_assistance/presentation/quiz_action.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
import '../module/ai_client_di.dart';
>>>>>>> cc1d0ed3 (충돌 상황 해결)
import 'quiz_screen.dart';
>>>>>>> 65e0a3e8 (quiz: banner 수정:)

=======
import '../module/ai_client_di.dart';
import 'quiz_screen.dart';
>>>>>>> 93342ffe988801372968965945de141989ff1d54

class DailyQuizBanner extends ConsumerWidget {
  final String? skills;
  final Random _random = Random();

  DailyQuizBanner({super.key, this.skills});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // 그라데이션 - 스터디 팁과 다른 색상으로 구분
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF36B37E), Color(0xFF24855E)],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF36B37E).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 부분
          Row(
            children: [
              // 퀴즈 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.quiz_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '오늘의 퀴즈',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // 퀴즈 풀기 버튼
              GestureDetector(
                onTap: () => _handleQuizTap(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '풀어보기',
                        style: TextStyle(
                          color: Color(0xFF36B37E),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Icon(
                        Icons.play_arrow,
                        color: Color(0xFF36B37E),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 퀴즈 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  '개발 지식을 테스트해보세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // 설명
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 메인 설명
                        Text(
                          _getSkillDescription(skills),
                          style: AppTextStyles.body2Regular.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // 퀴즈 카드
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "퀴즈를 풀고 실력을 확인하세요",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                "매일 새로운 ${skills?.split(',').firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍').trim() ?? '프로그래밍'} 퀴즈가 제공됩니다",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 13,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSkillDescription(String? skills) {
    if (skills == null || skills.isEmpty) {
      return '개발자라면 알아야 할 컴퓨터 기초 지식을 테스트해보세요.';
    }

    final skillList = _parseSkillList(skills);

    if (skillList.isEmpty) {
      return '개발자라면 알아야 할 컴퓨터 기초 지식을 테스트해보세요.';
    }

    if (skillList.length == 1) {
      return '${skillList[0]} 관련 지식을 테스트하고 실력을 향상시켜보세요.';
    }

    return '${skillList.join(", ")} 관련 지식을 테스트해보세요.';
  }

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

    // 최대 3개 스킬로 제한
    final limitedSkills =
        skillList.length > 3 ? skillList.sublist(0, 3) : skillList;

    debugPrint('파싱된 스킬 목록(최대 3개): $limitedSkills (${limitedSkills.length}개)');
    return limitedSkills.isEmpty ? ['컴퓨터 기초'] : limitedSkills;
  }

  void _handleQuizTap(BuildContext context, WidgetRef ref) async {
    // 디버그 로그 추가
    debugPrint('퀴즈 생성 시작: skills=$skills');

    // 원본 스킬 목록 파싱 (제한 없이)
    final originalSkillList =
        skills
            ?.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    // 제한된 스킬 목록 생성 (최대 3개)
    final skillList = _parseSkillList(skills);

    // 원본 스킬이 3개를 초과하는 경우 경고 표시
    if (originalSkillList.length > 3 && context.mounted) {
      // 간단한 스낵바로 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('최대 3개의 스킬만 사용됩니다: ${skillList.join(", ")}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.amber.shade700,
        ),
      );
    }

    debugPrint('파싱된 스킬 목록(최대 3개): $skillList (${skillList.length}개)');

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
