import 'dart:async';
import 'dart:math';

import 'package:devlink_mobile_app/ai_assistance/presentation/quiz_action.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_text_styles.dart';
import '../domain/model/quiz.dart';
import '../module/ai_client_di.dart';
import 'quiz_screen.dart';

class DailyQuizBanner extends ConsumerWidget {
  final String? skills;
  final Random _random = Random();

  // 🆕 다이얼로그 상태 변경 콜백 추가
  final Function(bool isVisible)? onDialogStateChanged;

  DailyQuizBanner({
    super.key,
    this.skills,
    this.onDialogStateChanged, // 🆕 콜백 매개변수 추가
  });

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

    AppLogger.debug(
      '파싱된 스킬 목록(최대 3개): $limitedSkills (${limitedSkills.length}개)',
      tag: 'QuizSkillParser',
    );

    return limitedSkills.isEmpty ? ['컴퓨터 기초'] : limitedSkills;
  }

  // 🔧 다이얼로그 상태 알림 기능 추가
  void _notifyDialogState(bool isVisible) {
    if (onDialogStateChanged != null) {
      onDialogStateChanged!(isVisible);
      AppLogger.debug(
        'CarouselSlider 상태 변경 알림: isVisible=$isVisible',
        tag: 'QuizDialog',
      );
    }
  }

  void _handleQuizTap(BuildContext context, WidgetRef ref) async {
    final startTime = DateTime.now();

    AppLogger.info(
      '퀴즈 생성 시작: skills=$skills',
      tag: 'QuizGeneration',
    );

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
      AppLogger.warning(
        '스킬 개수 제한: ${originalSkillList.length}개 → 3개로 제한됨',
        tag: 'QuizSkillParser',
      );

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

    AppLogger.logState('파싱된 스킬 정보', {
      '원본 스킬 개수': originalSkillList.length,
      '제한된 스킬 개수': skillList.length,
      '제한된 스킬 목록': skillList,
    });

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
        AppLogger.warning(
          '비정상적인 스킬명 감지: $selectedSkill → Flutter로 대체',
          tag: 'QuizSkillParser',
        );
        selectedSkill = 'Flutter';
      }
    }

    AppLogger.info(
      '선택된 스킬: $selectedSkill',
      tag: 'QuizGeneration',
    );

    // 🆕 배너 자동재생 중지
    _notifyDialogState(true);

    // 🆕 통합된 퀴즈 다이얼로그 표시 (로딩 포함)
    _showQuizDialogWithLoading(context, ref, selectedSkill);
  }

  // 🆕 로딩과 퀴즈 화면을 통합한 다이얼로그
  void _showQuizDialogWithLoading(
    BuildContext context,
    WidgetRef ref,
    String selectedSkill,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _QuizDialogWithLoading(
          skills: skills,
          selectedSkill: selectedSkill,
          onDialogClosed: () => _notifyDialogState(false), // 배너 자동재생 재개
        );
      },
    ).then((_) {
      // 다이얼로그가 외부에서 닫혔을 때도 배너 자동재생 재개
      _notifyDialogState(false);
    });
  }

  // 백업 퀴즈 생성 메서드
  Quiz _generateFallbackQuiz(String skillArea) {
    AppLogger.debug(
      '백업 퀴즈 생성 시작: $skillArea',
      tag: 'QuizFallback',
    );

    Quiz fallbackQuiz;

    // 해당 스킬에 맞는 퀴즈 생성
    if (skillArea.toLowerCase().contains('python')) {
      fallbackQuiz = Quiz(
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
      fallbackQuiz = Quiz(
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
      fallbackQuiz = Quiz(
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
      fallbackQuiz = Quiz(
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
    } else {
      // 기본 컴퓨터 기초 퀴즈
      fallbackQuiz = Quiz(
        question: "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
        options: ["4비트", "8비트", "16비트", "32비트"],
        explanation: "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
        correctOptionIndex: 1,
        relatedSkill: skillArea,
      );
    }

    AppLogger.info(
      '백업 퀴즈 생성 완료: ${fallbackQuiz.relatedSkill} - ${fallbackQuiz.question.substring(0, min(30, fallbackQuiz.question.length))}...',
      tag: 'QuizFallback',
    );

    return fallbackQuiz;
  }
}

// 🆕 로딩과 퀴즈를 통합한 StatefulWidget
class _QuizDialogWithLoading extends ConsumerStatefulWidget {
  final String? skills;
  final String selectedSkill;
  final VoidCallback onDialogClosed;

  const _QuizDialogWithLoading({
    required this.skills,
    required this.selectedSkill,
    required this.onDialogClosed,
  });

  @override
  ConsumerState<_QuizDialogWithLoading> createState() =>
      _QuizDialogWithLoadingState();
}

class _QuizDialogWithLoadingState
    extends ConsumerState<_QuizDialogWithLoading> {
  bool _isLoading = true;
  Quiz? _currentQuiz;
  String? _errorMessage;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialQuiz();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialQuiz() async {
    await _loadQuiz(widget.selectedSkill);
  }

  Future<void> _loadQuiz(String skillArea) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AppLogger.info(
      '퀴즈 로딩 시작: $skillArea',
      tag: 'QuizLoading',
    );

    // 타임아웃 타이머 설정 (15초)
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        _handleQuizTimeout();
      }
    });

    try {
      final generateQuizUseCase = ref.read(generateQuizUseCaseProvider);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final quizPrompt = '$skillArea-$currentTime';

      final asyncQuizResult = await generateQuizUseCase.execute(quizPrompt);

      _timeoutTimer?.cancel();

      if (!mounted) return;

      asyncQuizResult.when(
        data: (quiz) {
          setState(() {
            _currentQuiz = quiz;
            _isLoading = false;
          });

          AppLogger.info(
            '퀴즈 로딩 성공: ${quiz.question.substring(0, min(30, quiz.question.length))}...',
            tag: 'QuizLoading',
          );
        },
        error: (error, _) {
          _handleQuizError('퀴즈 생성 오류: $error');
        },
        loading: () {
          _handleQuizError('예상치 못한 로딩 상태');
        },
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      _handleQuizError('예상치 못한 오류: $e');
    }
  }

  void _handleQuizTimeout() {
    AppLogger.warning('퀴즈 로딩 타임아웃', tag: 'QuizLoading');
    _handleQuizError('퀴즈 로딩이 지연되고 있습니다');
  }

  void _handleQuizError(String error) {
    if (!mounted) return;

    AppLogger.error('퀴즈 로딩 실패: $error', tag: 'QuizLoading');

    // 백업 퀴즈 생성
    final fallbackQuiz = _generateFallbackQuiz(widget.selectedSkill);

    setState(() {
      _currentQuiz = fallbackQuiz;
      _isLoading = false;
      _errorMessage = error;
    });

    // 에러 메시지 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error. 기본 퀴즈를 표시합니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.amber.shade700,
        ),
      );
    }
  }

  Quiz _generateFallbackQuiz(String skillArea) {
    // DailyQuizBanner의 백업 퀴즈 로직과 동일
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
    } else {
      return Quiz(
        question: "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
        options: ["4비트", "8비트", "16비트", "32비트"],
        explanation: "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
        correctOptionIndex: 1,
        relatedSkill: skillArea,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.05,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.8,
        ),
        child: _isLoading ? _buildLoadingScreen() : _buildQuizScreen(),
      ),
    );
  }

  // 🆕 꿀팁과 일치하는 로딩 화면 디자인
  Widget _buildLoadingScreen() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        // 🆕 퀴즈 테마 그라데이션 (초록색)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF36B37E), Color(0xFF24855E)],
        ),
        borderRadius: BorderRadius.circular(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🆕 퀴즈 브랜드 아이콘
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),

          // 로딩 스피너
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),

          // 🆕 퀴즈 전용 메시지
          Text(
            '새로운 퀴즈를\n준비하고 있어요 🧩',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            '당신의 실력을 테스트할 문제를 만들고 있습니다',
            style: AppTextStyles.body2Regular.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            '잠시만 기다려주세요...',
            style: AppTextStyles.captionRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    if (_currentQuiz == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('퀴즈를 불러올 수 없습니다', style: AppTextStyles.subtitle1Bold),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('닫기'),
            ),
          ],
        ),
      );
    }

    return QuizScreen(
      quiz: _currentQuiz!,
      skills: widget.skills,
      onAction: (action) {
        switch (action) {
          case LoadQuiz(:final skills):
            AppLogger.info('새 퀴즈 로드 요청: $skills', tag: 'QuizDialog');

            // 🔧 새 퀴즈 요청 시 다이얼로그를 닫지 않고 현재 화면에서 로딩 시작
            final skillList =
                skills
                    ?.split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList() ??
                ['컴퓨터 기초'];
            final selectedSkill =
                skillList.isNotEmpty
                    ? skillList[Random().nextInt(skillList.length)]
                    : '컴퓨터 기초';

            _loadQuiz(selectedSkill);
            break;

          case SubmitAnswer(:final answerIndex):
            AppLogger.info('퀴즈 답변 제출: 인덱스 $answerIndex', tag: 'QuizAnswer');
            break;

          case CloseQuiz():
            AppLogger.info('퀴즈 다이얼로그 닫기', tag: 'QuizDialog');
            widget.onDialogClosed(); // 배너 자동재생 재개
            Navigator.of(context).pop();
            break;
        }
      },
    );
  }
}
