// lib/ai_assistance/presentation/study_tip_banner.dart

import 'dart:async';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/model/study_tip.dart';
import '../module/ai_client_di.dart';

// 캐시 키 생성 헬퍼 함수 - 다양성 요소 반영
String _generateCacheKey(String? skills) {
  final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
  final hour = DateTime.now().hour; // 시간대별 다양성 추가

  // 스킬 처리 - 첫 번째 스킬만 사용 (Repository에서 랜덤 선택됨)
  final skillArea =
      skills
          ?.split(',')
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
          .trim() ??
          '프로그래밍 기초';

  // 스킬 첫 3글자만 사용하여 캐시 키 생성
  final skillPrefix =
  skillArea.length > 3 ? skillArea.substring(0, 3) : skillArea;

  // 시간대별 다양성 추가 (4시간 단위로 캐시 갱신)
  final timeSlot = (hour / 4).floor();

  return '$today-$skillPrefix-$timeSlot';
}

// 🔧 개선된 캐시 기반 FutureProvider - 일반 배너용
final studyTipProvider = FutureProvider.autoDispose.family<StudyTip?, String?>((
    ref,
    skills,
    ) async {
  // 캐시 키 생성 - 시간대별 다양성 반영
  final cacheKey = _generateCacheKey(skills);

  AppLogger.debug(
    'StudyTip 캐시 키 확인: $cacheKey',
    tag: 'StudyTipCache',
  );

  // 캐시된 데이터 확인
  final cache = ref.read(studyTipCacheProvider);
  if (cache.containsKey(cacheKey)) {
    AppLogger.info(
      'StudyTip 캐시 히트: $cacheKey',
      tag: 'StudyTipCache',
    );
    return cache[cacheKey] as StudyTip?;
  }

  AppLogger.info(
    'StudyTip 캐시 미스: $cacheKey, 새로운 팁 생성 필요',
    tag: 'StudyTipCache',
  );

  try {
    // 캐시 없으면 새로 생성 - Repository에서 스킬 랜덤 선택됨
    final getStudyTipUseCase = ref.watch(getStudyTipUseCaseProvider);

    // 전체 스킬 목록을 Repository로 전달 (Repository에서 랜덤 선택)
    final asyncValue = await getStudyTipUseCase.execute(skills ?? '프로그래밍 기초');

    // 값이 있으면 캐시에 저장
    if (asyncValue.hasValue) {
      final studyTip = asyncValue.value;

      AppLogger.info(
        'StudyTip 생성 성공, 캐시에 저장: $cacheKey',
        tag: 'StudyTipCache',
      );

      // 🔧 캐시 정리 서비스 활용
      final cacheCleanup = ref.read(cacheCleanupProvider);
      cacheCleanup.cleanupOldCacheEntries();

      // 새 항목 추가
      final currentCache = Map<String, dynamic>.from(
        ref.read(studyTipCacheProvider),
      );
      currentCache[cacheKey] = studyTip;
      ref.read(studyTipCacheProvider.notifier).state = currentCache;

      return studyTip;
    }

    return null;
  } catch (e) {
    AppLogger.error(
      '학습 팁 생성 중 오류',
      tag: 'StudyTipGeneration',
      error: e,
    );
    return null;
  }
});

class StudyTipBanner extends ConsumerWidget {
  final String? skills;

  // 다이얼로그 상태 변경 콜백
  final Function(bool isVisible)? onDialogStateChanged;

  const StudyTipBanner({
    super.key,
    this.skills,
    this.onDialogStateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudyTip = ref.watch(studyTipProvider(skills));

    return Container(
      width: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // 더 멋진 그라데이션으로 변경
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColorStyles.primary60, AppColorStyles.primary100],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(24), // 라운딩 증가
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary60.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 부분 개선
          Row(
            children: [
              // 더 세련된 배지 디자인
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
                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '오늘의 꿀팁',
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

              // 자세히보기 버튼 - 작고 세련된 형태로 옮김
              asyncStudyTip.when(
                data:
                    (tip) =>
                tip != null
                    ? GestureDetector(
                  onTap:
                      () => _showStudyTipDetailsDialog(
                    context,
                    tip,
                    skills,
                    ref,
                  ),
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
                          color: Colors.black.withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '더보기',
                          style: TextStyle(
                            color: AppColorStyles.primary80,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Icon(
                          Icons.play_arrow,
                          color: AppColorStyles.primary80,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                )
                    : SizedBox.shrink(),
                loading: () => SizedBox.shrink(),
                error: (_, __) => SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildStudyTipContent(asyncStudyTip, context)),
        ],
      ),
    );
  }

  Widget _buildStudyTipContent(
      AsyncValue<StudyTip?> asyncStudyTip,
      BuildContext context,
      ) {
    return asyncStudyTip.when(
      data: (tip) {
        if (tip == null) {
          return _buildErrorState('학습 팁을 불러올 수 없습니다');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              tip.title,
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

            // 내용 부분 - Flexible 안에 넣어 스크롤 가능하게
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 내용
                    Text(
                      tip.content,
                      style: AppTextStyles.body2Regular.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 영어 문구
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
                          // 영어 구문
                          SizedBox(height: 6),
                          Text(
                            '"${tip.englishPhrase}"',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
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
          size: 24,
        ),
        const SizedBox(height: 8),
        // Expanded 대신 Flexible 사용
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // 다이얼로그 상태 알림 기능
  void _notifyDialogState(bool isVisible) {
    if (onDialogStateChanged != null) {
      onDialogStateChanged!(isVisible);
      AppLogger.debug(
        'CarouselSlider 상태 변경 알림: isVisible=$isVisible',
        tag: 'StudyTipDialog',
      );
    }
  }

  // 캐시 업데이트 메서드 - 홈화면에 새로운 팁 반영
  void _updateHomeBannerCache(WidgetRef ref, StudyTip newTip, String? skills) {
    final cacheKey = _generateCacheKey(skills);
    ref
        .read(studyTipCacheProvider.notifier)
        .update(
          (state) => {
        ...state,
        cacheKey: newTip,
      },
    );

    // Provider 새로고침을 위해 invalidate
    ref.invalidate(studyTipProvider(skills));

    AppLogger.info(
      '홈 배너 캐시 업데이트 완료: $cacheKey',
      tag: 'StudyTipCache',
    );
  }

  // 🆕 강제 새로고침용 새로운 팁 로딩 메서드 - 캐시 우회
  Future<void> _loadNewTipWithCacheBypass(
      BuildContext context,
      String? skills,
      WidgetRef ref,
      Function(StudyTip) updateDialogContent,
      ) async {
    final startTime = DateTime.now();

    AppLogger.info(
      '캐시 우회 새로운 학습 팁 로딩 시작: $skills',
      tag: 'StudyTipFresh',
    );

    // 🔧 freshStudyTipProvider를 사용하여 캐시 완전 우회
    try {
      final freshTip = await ref.read(freshStudyTipProvider(skills).future);

      final duration = DateTime.now().difference(startTime);

      if (freshTip != null) {
        AppLogger.logPerformance('캐시 우회 StudyTip 생성 성공', duration);
        AppLogger.info(
          '새 StudyTip 생성 성공 (캐시 우회): ${freshTip.title}',
          tag: 'StudyTipFresh',
        );

        // 다이얼로그 내용 업데이트
        updateDialogContent(freshTip);

        // 🆕 새로운 팁을 일반 캐시에도 저장 (다음 번 일반 로딩을 위해)
        _updateHomeBannerCache(ref, freshTip, skills);

      } else {
        AppLogger.logPerformance('캐시 우회 StudyTip 생성 실패', duration);

        // Fallback 처리
        final backupTip = _generateBackupStudyTip(skills, ref);
        updateDialogContent(backupTip);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('새로운 팁 생성에 실패했습니다. 기본 팁을 표시합니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.amber.shade700,
            ),
          );
        }
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('캐시 우회 StudyTip 생성 예외', duration);
      AppLogger.error(
        '캐시 우회 StudyTip 생성 예외',
        tag: 'StudyTipFresh',
        error: e,
      );

      // Fallback 처리
      final backupTip = _generateBackupStudyTip(skills, ref);
      updateDialogContent(backupTip);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예상치 못한 오류가 발생했습니다. 기본 팁을 표시합니다.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔧 기존 로딩 다이얼로그와 함께 사용하는 개선된 메서드
  Future<void> _loadNewTip(
      BuildContext context,
      String? skills,
      WidgetRef ref,
      Function(StudyTip) updateDialogContent,
      ) async {
    // 대화상자 컨텍스트 추적을 위한 변수
    BuildContext? loadingDialogContext;

    // 로딩 타이머 관리를 위한 변수
    Timer? loadingTimer;

    // 취소 여부 추적
    bool isCancelled = false;

    // 로딩 다이얼로그에 고유 키 부여
    final loadingDialogKey = UniqueKey();

    AppLogger.info(
      '새로운 학습 팁 로딩 시작 (로딩 다이얼로그 포함)',
      tag: 'StudyTipGeneration',
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // 다이얼로그 컨텍스트 저장
        loadingDialogContext = dialogContext;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              // 뒤로가기 버튼으로 취소 처리
              isCancelled = true;
              loadingTimer?.cancel();
              AppLogger.info('사용자가 학습 팁 로딩을 취소했습니다', tag: 'StudyTipGeneration');
            }
          },
          child: Dialog(
            key: loadingDialogKey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColorStyles.primary60, AppColorStyles.primary100],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColorStyles.primary60.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 브랜드 아이콘
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
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

                  // 🆕 더 구체적인 메시지
                  Text(
                    '새로운 꿀팁을\n우려내고 있어요 ✨',
                    style: AppTextStyles.subtitle1Bold.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '이전과는 완전히 다른 새로운 꿀팁을 준비 중입니다',
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
            ),
          ),
        );
      },
    ).then((_) {
      // 다이얼로그가 닫혔을 때 취소 처리
      if (!isCancelled) {
        isCancelled = true;
        loadingTimer?.cancel();
      }
    });

    // 타임아웃 설정 (15초로 단축 - 캐시 우회로 더 빠름)
    loadingTimer = Timer(const Duration(seconds: 15), () {
      if (isCancelled) return;

      AppLogger.warning(
        '새 학습 팁 로딩 타임아웃 (15초)',
        tag: 'StudyTipGeneration',
      );

      _closeLoadingDialog(loadingDialogContext);

      if (context.mounted && !isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('새로운 팁 생성이 지연되고 있습니다. 기본 팁을 표시합니다.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColorStyles.primary80,
          ),
        );

        // 백업 스터디 팁으로 업데이트
        final backupTip = _generateBackupStudyTip(skills, ref);
        updateDialogContent(backupTip);
      }
    });

    // 🆕 캐시 우회 방식으로 새로운 팁 로딩
    try {
      final freshTip = await ref.read(freshStudyTipProvider(skills).future);

      // 취소되었으면 더 이상 진행하지 않음
      if (isCancelled) {
        AppLogger.info('로딩이 취소되어 결과를 무시합니다', tag: 'StudyTipGeneration');
        return;
      }

      // 타이머 취소
      loadingTimer.cancel();

      // 로딩 다이얼로그 닫기
      _closeLoadingDialog(loadingDialogContext);

      if (freshTip != null) {
        AppLogger.info(
          '새 StudyTip 생성 성공 (캐시 우회): ${freshTip.title}',
          tag: 'StudyTipGeneration',
        );

        // 기존 다이얼로그 내용 업데이트
        updateDialogContent(freshTip);

        // 새로운 팁을 일반 캐시에도 저장
        _updateHomeBannerCache(ref, freshTip, skills);

      } else {
        AppLogger.warning(
          'freshStudyTipProvider에서 null 반환',
          tag: 'StudyTipGeneration',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('새로운 팁을 생성하지 못했습니다. 기본 팁을 표시합니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.amber.shade700,
            ),
          );

          // 백업 스터디 팁으로 업데이트
          final backupTip = _generateBackupStudyTip(skills, ref);
          updateDialogContent(backupTip);
        }
      }
    } catch (e) {
      // 취소되었으면 더 이상 진행하지 않음
      if (isCancelled) {
        AppLogger.info('로딩이 취소되어 예외 처리를 무시합니다', tag: 'StudyTipGeneration');
        return;
      }

      // 예외 발생 시 타이머 취소 및 백업 팁 표시
      loadingTimer.cancel();
      _closeLoadingDialog(loadingDialogContext);

      AppLogger.error(
        'freshStudyTipProvider 예외 발생',
        tag: 'StudyTipGeneration',
        error: e,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예상치 못한 오류: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );

        // 백업 스터디 팁으로 업데이트
        final backupTip = _generateBackupStudyTip(skills, ref);
        updateDialogContent(backupTip);
      }
    }
  }

  // 로딩 다이얼로그 닫기 유틸리티 메서드
  void _closeLoadingDialog(BuildContext? dialogContext) {
    if (dialogContext != null && Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();

      AppLogger.debug(
        '로딩 다이얼로그 닫기 완료',
        tag: 'StudyTipUI',
      );
    }
  }

  // 백업 스터디 팁 생성 메서드
  StudyTip _generateBackupStudyTip(String? skills, WidgetRef ref) {
    final fallbackService = ref.read(fallbackServiceProvider);
    final skillArea =
        skills
            ?.split(',')
            .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
            .trim() ??
            '프로그래밍 기초';

    AppLogger.info(
      '백업 StudyTip 생성: $skillArea',
      tag: 'StudyTipFallback',
    );

    final fallbackTipData = fallbackService.getFallbackStudyTip(skillArea);

    return StudyTip(
      title: fallbackTipData['title'] ?? '학습 팁',
      content: fallbackTipData['content'] ?? '꾸준한 학습이 성공의 열쇠입니다.',
      relatedSkill: fallbackTipData['relatedSkill'] ?? skillArea,
      englishPhrase:
      fallbackTipData['englishPhrase'] ?? 'Practice makes perfect.',
      translation: fallbackTipData['translation'] ?? '연습이 완벽을 만든다.',
      source: fallbackTipData['source'],
    );
  }

  void _showStudyTipDetailsDialog(
      BuildContext context,
      StudyTip tip,
      String? skills,
      WidgetRef ref,
      ) {
    AppLogger.info(
      '학습 팁 상세 다이얼로그 표시: ${tip.title}',
      tag: 'StudyTipUI',
    );

    // 상세 다이얼로그 표시 전 배너 자동재생 중지
    _notifyDialogState(true);

    // StatefulWidget으로 다이얼로그 상태 관리
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => _StudyTipDialog(
        initialTip: tip,
        skills: skills,
        onConfirm: (StudyTip finalTip) {
          AppLogger.info(
            '학습 팁 확인 버튼 클릭: ${finalTip.title}',
            tag: 'StudyTipUI',
          );

          // 확인 버튼 클릭 시 홈 배너 캐시 업데이트
          _updateHomeBannerCache(ref, finalTip, skills);
        },
        onLoadNewTip: (Function(StudyTip) updateContent) {
          AppLogger.info(
            'Next Insight 버튼 클릭 - 캐시 우회 모드',
            tag: 'StudyTipUI',
          );

          // 🆕 캐시 우회 방식으로 새 팁 로드
          _loadNewTip(context, skills, ref, updateContent);
        },
      ),
    ).then((_) {
      // 상세 다이얼로그 닫힐 때 배너 자동재생 재개
      _notifyDialogState(false);
    });
  }
}

// 다이얼로그를 위한 별도 StatefulWidget - 기존과 동일
class _StudyTipDialog extends StatefulWidget {
  final StudyTip initialTip;
  final String? skills;
  final Function(StudyTip) onConfirm;
  final Function(Function(StudyTip)) onLoadNewTip;

  const _StudyTipDialog({
    required this.initialTip,
    required this.skills,
    required this.onConfirm,
    required this.onLoadNewTip,
  });

  @override
  State<_StudyTipDialog> createState() => _StudyTipDialogState();
}

class _StudyTipDialogState extends State<_StudyTipDialog> {
  late StudyTip currentTip;

  @override
  void initState() {
    super.initState();
    currentTip = widget.initialTip;

    AppLogger.debug(
      'StudyTipDialog 초기화: ${currentTip.title}',
      tag: 'StudyTipUI',
    );
  }

  void _updateCurrentTip(StudyTip newTip) {
    if (mounted) {
      setState(() {
        currentTip = newTip;
      });

      AppLogger.info(
        'StudyTipDialog 내용 업데이트: ${newTip.title}',
        tag: 'StudyTipUI',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColorStyles.primary60,
                    AppColorStyles.primary100,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 및 아이콘 영역
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentTip.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 스킬 영역
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      currentTip.relatedSkill,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 콘텐츠 영역
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 팁 내용
                    Text(
                      currentTip.content,
                      style: TextStyle(
                        height: 1.6,
                        color: Colors.grey[800],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 구분선 - 시각적으로 더 세련되게
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 영어 한마디 섹션 - 더 세련되게
                    Row(
                      children: [
                        Icon(
                          Icons.flight_takeoff_rounded,
                          color: AppColorStyles.primary80.withValues(
                            alpha: 0.8,
                          ),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '버그보다 무서운 영어, 하루 한 입씩!',
                          style: TextStyle(
                            color: AppColorStyles.primary80,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFDCE3FF),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorStyles.primary80.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '"${currentTip.englishPhrase}"',
                              style: TextStyle(
                                color: AppColorStyles.primary80,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentTip.translation,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 출처 정보
                    if (currentTip.source != null &&
                        currentTip.source!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.source_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '출처: ${currentTip.source}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 하단 버튼들 - 두 버튼을 나란히 배치
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // 확인 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // 현재 팁으로 홈 배너 업데이트
                        widget.onConfirm(currentTip);
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFF5F7FF),
                        foregroundColor: AppColorStyles.primary80,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColorStyles.primary80.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  // 간격
                  const SizedBox(width: 12),

                  // 🆕 개선된 Next Insight 버튼 - 캐시 우회 강조
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // 캐시 우회 방식으로 새 팁 로드
                        widget.onLoadNewTip(_updateCurrentTip);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColorStyles.primary80,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, size: 16), // 🆕 새로고침 아이콘
                          SizedBox(width: 6),
                          Text(
                            '꿀팁 하나더!',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
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
      ),
    );
  }
}