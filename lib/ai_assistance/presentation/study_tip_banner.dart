// lib/ai_assistance/presentation/study_tip_banner.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_text_styles.dart';
import '../../core/styles/app_color_styles.dart';
import '../domain/model/study_tip.dart';
import '../module/study_tip_di.dart';

// 캐시 키 생성 헬퍼 함수 추가 - 일관성을 위해
String _generateCacheKey(String? skills) {
  final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
  final skillArea = skills?.split(',')
      .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
      .trim() ??
      '프로그래밍 기초';

  // 스킬 첫 3글자만 사용하여 잦은 캐시 미스 방지
  final skillPrefix = skillArea.length > 3 ? skillArea.substring(0, 3) : skillArea;
  return '$today-$skillPrefix';
}

// 캐시 키 기반 FutureProvider 개선
final studyTipProvider = FutureProvider.autoDispose.family<StudyTip?, String?>((
    ref,
    skills,
    ) async {
  // 캐시 키 생성 - 헬퍼 함수 사용
  final cacheKey = _generateCacheKey(skills);

  // 디버그 정보
  debugPrint('StudyTip 캐시 키: $cacheKey 확인 중');

  // 캐시된 데이터 확인
  final cache = ref.read(studyTipCacheProvider);
  if (cache.containsKey(cacheKey)) {
    debugPrint('StudyTip 캐시 히트: $cacheKey');
    return cache[cacheKey] as StudyTip?;
  }

  debugPrint('StudyTip 캐시 미스: $cacheKey, API 호출 필요');

  try {
    // 캐시 없으면 새로 생성
    final getStudyTipUseCase = ref.watch(getStudyTipUseCaseProvider);
    // 스킬 영역 추출 - 일관성을 위해 동일한 추출 로직 유지
    final skillArea = skills?.split(',')
        .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
        .trim() ??
        '프로그래밍 기초';

    final asyncValue = await getStudyTipUseCase.execute(skillArea);

    // 값이 있으면 캐시에 저장
    if (asyncValue.hasValue) {
      final studyTip = asyncValue.value;
      debugPrint('StudyTip 생성 성공, 캐시에 저장: $cacheKey');

      // 캐시 크기 제한 확인 (최대 10개 항목)
      final currentCache = Map<String, dynamic>.from(ref.read(studyTipCacheProvider));
      if (currentCache.length >= 10) {
        // 가장 오래된 항목 하나 제거
        final oldestKey = currentCache.keys.first;
        currentCache.remove(oldestKey);
        debugPrint('StudyTip 캐시 정리: 오래된 항목 제거 $oldestKey');
      }

      // 새 항목 추가
      currentCache[cacheKey] = studyTip;
      ref.read(studyTipCacheProvider.notifier).state = currentCache;

      return studyTip;
    }

    return null;
  } catch (e) {
    debugPrint('학습 팁 생성 중 오류: $e');
    return null;
  }
});

class StudyTipBanner extends ConsumerWidget {
  final String? skills;

  StudyTipBanner({super.key, this.skills});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudyTip = ref.watch(studyTipProvider(skills));

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade400, Colors.indigo.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '오늘의 공부 팁',
                  style: AppTextStyles.body1Regular.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildStudyTipContent(asyncStudyTip, context),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTipContent(AsyncValue<StudyTip?> asyncStudyTip, BuildContext context) {
    return asyncStudyTip.when(
      data: (tip) {
        if (tip == null) {
          return _buildErrorState('학습 팁을 불러올 수 없습니다');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded 대신 Flexible 사용
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "영어 한 마디: \"${tip.englishPhrase}\"",
                      style: AppTextStyles.body2Regular.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showStudyTipDetailsDialog(context, tip, skills);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.indigo.shade700,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '자세히 보기',
                  style: AppTextStyles.button2Regular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
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
          color: Colors.white.withOpacity(0.7),
          size: 32,
        ),
        const SizedBox(height: 8),
        // Expanded 대신 Flexible 사용
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              message,
              style: AppTextStyles.body2Regular.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // 재시도 로직
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.indigo.shade700,
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
        ),
      ],
    );
  }

  // 현재 선택된 팁 추적을 위한 변수
  StudyTip? _currentSelectedTip;

  // 새로운 팁 로드 메서드
  Future<void> _loadNewTip(BuildContext context, String? skills, WidgetRef ref) async {
    // 로딩 인디케이터 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );

    try {
      // 스킬 영역 추출
      final skillArea = skills?.split(',')
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
          .trim() ??
          '프로그래밍 기초';

      // UseCase 호출
      final getStudyTipUseCase = ref.read(getStudyTipUseCaseProvider);
      final asyncValue = await getStudyTipUseCase.execute(skillArea);

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      // 결과 처리
      if (asyncValue.hasValue && asyncValue.value != null) {
        // 현재 다이얼로그 닫기
        Navigator.of(context).pop();

        // 새 팁으로 다이얼로그 표시
        _showStudyTipDetailsDialog(context, asyncValue.value!, skills);
      } else if (asyncValue.hasError) {
        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('새 팁을 불러오는데 실패했습니다: ${asyncValue.error}')),
        );
      }
    } catch (e) {
      // 예외 처리
      Navigator.of(context).pop(); // 로딩 인디케이터 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }
  void _showStudyTipDetailsDialog(BuildContext context, StudyTip tip, String? skills) {
    // 현재 팁 업데이트
    _currentSelectedTip = tip;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary80,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 및 아이콘 영역
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip.title,
                            style: AppTextStyles.subtitle1Bold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 스킬 영역
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(
                        tip.relatedSkill,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.white.withOpacity(0.9),
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
                        tip.content,
                        style: AppTextStyles.body1Regular.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 구분선
                      Divider(color: Colors.grey[200], thickness: 1),
                      const SizedBox(height: 24),

                      // 영어 한마디 섹션
                      Text(
                        '✈️ 버그보다 무서운 영어, 오늘부터 한 입씩!',
                        style: AppTextStyles.body1Regular.copyWith(
                          color: AppColorStyles.primary80,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColorStyles.secondary01.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${tip.englishPhrase}"',
                              style: AppTextStyles.body1Regular.copyWith(
                                color: AppColorStyles.secondary01,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tip.translation,
                              style: AppTextStyles.body2Regular,
                            ),
                          ],
                        ),
                      ),

                      // 출처 정보
                      if (tip.source != null && tip.source!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '출처: ${tip.source}',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 하단 버튼들 - 두 버튼을 나란히 배치
              Consumer(
                builder: (context, ref, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // 확인 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // 현재 선택된 팁이 있으면 캐시 업데이트
                            if (_currentSelectedTip != null) {
                              // 캐시 키 생성 - 동일한 헬퍼 함수 사용
                              final cacheKey = _generateCacheKey(skills);

                              // 캐시 업데이트
                              ref.read(studyTipCacheProvider.notifier).update((state) => {
                                ...state,
                                cacheKey: _currentSelectedTip,
                              });
                            }

                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColorStyles.primary80,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '확인',
                            style: AppTextStyles.button1Medium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // 간격
                      const SizedBox(width: 12),

                      // One More Tip 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () => _loadNewTip(context, skills, ref),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColorStyles.primary80,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '💡 Next Insight',
                            style: AppTextStyles.button1Medium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}