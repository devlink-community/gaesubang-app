// lib/ai_assistance/presentation/study_tip_action.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_tip_action.freezed.dart';

@freezed
sealed class StudyTipAction with _$StudyTipAction {
  // 학습 팁 로드 액션 - skills 매개변수 추가
  const factory StudyTipAction.loadStudyTip({String? skills}) = LoadStudyTip;

  // 학습 팁 상세 보기 액션
  const factory StudyTipAction.viewStudyTipDetail() = ViewStudyTipDetail;

  // 학습 팁 닫기 액션
  const factory StudyTipAction.closeStudyTip() = CloseStudyTip;
}