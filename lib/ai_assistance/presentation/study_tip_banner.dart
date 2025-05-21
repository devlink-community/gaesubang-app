// lib/ai_assistance/presentation/study_tip_banner.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/styles/app_text_styles.dart';
import '../../core/styles/app_color_styles.dart';
import '../domain/model/study_tip.dart';
import '../module/study_tip_di.dart';

// 캐시 키 기반 FutureProvider
final studyTipProvider = FutureProvider.autoDispose.family<StudyTip?, String?>((
    ref,
    skills,
    ) async {
  // 캐시 키 - 오늘 날짜 + 스킬
  final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
  final skillArea = skills?.split(',')
      .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
      .trim() ??
      '프로그래밍 기초';

  final cacheKey = '$today-$skillArea';

  // 캐시된 데이터 확인
  final cache = ref.read(studyTipCacheProvider);
  if (cache.containsKey(cacheKey)) {
    return cache[cacheKey] as StudyTip?;
  }

  try {
    // 캐시 없으면 새로 생성
    final getStudyTipUseCase = ref.watch(getStudyTipUseCaseProvider);
    final asyncValue = await getStudyTipUseCase.execute(skillArea);

    // 값이 있으면 캐시에 저장
    if (asyncValue.hasValue) {
      final studyTip = asyncValue.value;
      ref.read(studyTipCacheProvider.notifier).update((state) => {
        ...state,
        cacheKey: studyTip,
      });
      return studyTip;
    }

    return null;
  } catch (e) {
    print('학습 팁 생성 중 오류: $e');
    return null;
  }
});

class StudyTipBanner extends ConsumerWidget {
  final String? skills;

  const StudyTipBanner({super.key, this.skills});

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
          Expanded(child: _buildStudyTipContent(asyncStudyTip, context)),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "영어 한 마디: \"${tip.englishPhrase}\"",
                      style: AppTextStyles.body2Regular.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
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
                  _showStudyTipDetailsDialog(context, tip);
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
        Expanded(
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

  void _showStudyTipDetailsDialog(BuildContext context, StudyTip tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tip.title, style: AppTextStyles.subtitle1Bold),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 팁 내용
              Text(tip.content, style: AppTextStyles.body1Regular),
              const SizedBox(height: 16),
              const Divider(),

              // 영어 한 마디 섹션
              Text('오늘의 개발자 영어', style: AppTextStyles.body2Bold),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorStyles.secondary01.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.englishPhrase,
                      style: AppTextStyles.body1Bold.copyWith(
                          color: AppColorStyles.secondary01
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(tip.translation, style: AppTextStyles.body2Regular),
                  ],
                ),
              ),

              // 출처 정보
              if (tip.source != null && tip.source!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('출처: ${tip.source}', style: AppTextStyles.captionRegular),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}