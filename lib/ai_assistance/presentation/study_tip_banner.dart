// lib/ai_assistance/presentation/study_tip_banner.dart

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/model/study_tip.dart';
import '../module/ai_client_di.dart';

// 캐시 키 생성 헬퍼 함수 추가 - 일관성을 위해
String _generateCacheKey(String? skills) {
  final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
  final skillArea =
      skills
          ?.split(',')
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
          .trim() ??
      '프로그래밍 기초';

  // 스킬 첫 3글자만 사용하여 잦은 캐시 미스 방지
  final skillPrefix =
      skillArea.length > 3 ? skillArea.substring(0, 3) : skillArea;
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
    final skillArea =
        skills
            ?.split(',')
            .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '프로그래밍 기초')
            .trim() ??
        '프로그래밍 기초';

    final asyncValue = await getStudyTipUseCase.execute(skillArea);

    // 값이 있으면 캐시에 저장
    if (asyncValue.hasValue) {
      final studyTip = asyncValue.value;
      debugPrint('StudyTip 생성 성공, 캐시에 저장: $cacheKey');

      // 캐시 크기 제한 확인 (최대 10개 항목)
      final currentCache = Map<String, dynamic>.from(
        ref.read(studyTipCacheProvider),
      );
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

  // 현재 선택된 팁 추적을 위한 변수
  StudyTip? _currentSelectedTip;

  // 새로운 팁 로드 메서드
  Future<void> _loadNewTip(
    BuildContext context,
    String? skills,
    WidgetRef ref,
  ) async {
    // 로딩 인디케이터 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
    );

    try {
      // 스킬 영역 추출
      final skillArea =
          skills
              ?.split(',')
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  void _showStudyTipDetailsDialog(
    BuildContext context,
    StudyTip tip,
    String? skills,
  ) {
    // 현재 팁 업데이트
    _currentSelectedTip = tip;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                                tip.title,
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
                            tip.relatedSkill,
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
                            tip.content,
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
                                '버그보다 무서운 영어, 한 입씩!',
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
                                    '"${tip.englishPhrase}"',
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
                                  tip.translation,
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
                          if (tip.source != null && tip.source!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.source_outlined,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '출처: ${tip.source}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
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
                  Consumer(
                    builder:
                        (context, ref, _) => Padding(
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
                                      final cacheKey = _generateCacheKey(
                                        skills,
                                      );

                                      // 캐시 업데이트
                                      ref
                                          .read(studyTipCacheProvider.notifier)
                                          .update(
                                            (state) => {
                                              ...state,
                                              cacheKey: _currentSelectedTip,
                                            },
                                          );
                                    }

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
                                        color: AppColorStyles.primary80
                                            .withValues(alpha: 0.3),
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

                              // One More Tip 버튼
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      () => _loadNewTip(context, skills, ref),
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
                                      Icon(Icons.auto_awesome, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Next Insight',
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
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
