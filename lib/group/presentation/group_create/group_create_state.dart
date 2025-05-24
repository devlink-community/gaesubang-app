// lib/group/presentation/group_create/group_create_state.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_create_state.freezed.dart';

@freezed
class GroupCreateState with _$GroupCreateState {
  const GroupCreateState({
    this.name = '',
    this.description = '',
    this.limitMemberCount = 10, // 기본값 10명
    this.hashTags = const [],
    this.imageUrl,
    this.pauseTimeLimit = 120, // 기본값 120분 = 2시간
    this.invitedMembers = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.createdGroupId,
    this.nameError,
    this.descriptionError,
    this.memberLimitError,
    this.pauseTimeLimitError,
    this.isFormTouched = false,
    this.showValidationErrors = false,
  });

  @override
  final String name;
  @override
  final String description;
  @override
  final int limitMemberCount;
  @override
  final List<HashTag> hashTags;
  @override
  final String? imageUrl;
  @override
  final int pauseTimeLimit;

  @override
  final List<Member> invitedMembers;

  @override
  final bool isSubmitting;
  @override
  final String? errorMessage;
  @override
  final String? successMessage;
  @override
  final String? createdGroupId;

  @override
  final String? nameError;
  @override
  final String? descriptionError;
  @override
  final String? memberLimitError;
  @override
  final String? pauseTimeLimitError;

  @override
  final bool isFormTouched;
  @override
  final bool showValidationErrors;
}

// Extension으로 computed 속성들과 유틸리티 메서드들을 분리
extension GroupCreateStateExtension on GroupCreateState {
  /// 폼이 유효한지 검사
  bool get isFormValid {
    return nameError == null &&
        descriptionError == null &&
        memberLimitError == null &&
        pauseTimeLimitError == null &&
        name.trim().isNotEmpty &&
        description.trim().isNotEmpty &&
        hashTags.length <= 10;
  }

  /// 제출 가능한지 검사
  bool get canSubmit {
    return isFormValid && !isSubmitting;
  }

  /// 총 예상 멤버 수 (본인 + 초대된 멤버)
  int get totalExpectedMembers {
    return 1 + invitedMembers.length;
  }

  /// 해시태그를 문자열 리스트로 변환
  List<String> get hashTagStrings {
    return hashTags.map((tag) => tag.content).toList();
  }

  /// 일시정지 제한시간을 시간:분 형식으로 변환
  String get pauseTimeLimitFormatted {
    final hours = pauseTimeLimit ~/ 60;
    final minutes = pauseTimeLimit % 60;

    if (hours == 0) {
      return '$minutes분';
    } else if (minutes == 0) {
      return '$hours시간';
    } else {
      return '$hours시간 $minutes분';
    }
  }

  /// 일시정지 제한시간 슬라이더 값 (30분~8시간을 0.0~1.0으로 정규화)
  double get pauseTimeLimitSliderValue {
    const minMinutes = 30.0;
    const maxMinutes = 480.0; // 8시간
    return (pauseTimeLimit - minMinutes) / (maxMinutes - minMinutes);
  }

  /// 에러가 있는지 확인
  bool get hasError {
    return errorMessage != null ||
        nameError != null ||
        descriptionError != null ||
        memberLimitError != null ||
        pauseTimeLimitError != null;
  }

  /// 모든 에러 메시지 제거한 상태로 복사
  GroupCreateState clearAllErrors() {
    return copyWith(
      errorMessage: null,
      nameError: null,
      descriptionError: null,
      memberLimitError: null,
      pauseTimeLimitError: null,
    );
  }

  /// 폼을 터치된 상태로 마크
  GroupCreateState markAsTouched() {
    return copyWith(
      isFormTouched: true,
      showValidationErrors: true,
    );
  }

  /// 특정 해시태그가 이미 존재하는지 확인
  bool hasHashTag(String content) {
    return hashTags.any(
      (tag) => tag.content.toLowerCase() == content.toLowerCase(),
    );
  }

  /// 특정 멤버가 이미 초대되었는지 확인
  bool hasMember(String userId) {
    return invitedMembers.any((member) => member.id == userId);
  }
}

// 정적 유틸리티 메서드들을 별도 클래스로 분리
class GroupCreateStateUtils {
  const GroupCreateStateUtils._(); // 인스턴스화 방지

  /// 슬라이더 값을 분 단위로 변환
  static int sliderValueToMinutes(double value) {
    const minMinutes = 30;
    const maxMinutes = 480; // 8시간
    return (minMinutes + (value * (maxMinutes - minMinutes))).round();
  }

  /// 분 단위를 슬라이더 값으로 변환
  static double minutesToSliderValue(int minutes) {
    const minMinutes = 30.0;
    const maxMinutes = 480.0; // 8시간
    final clampedMinutes =
        minutes.clamp(minMinutes.toInt(), maxMinutes.toInt()).toDouble();
    return (clampedMinutes - minMinutes) / (maxMinutes - minMinutes);
  }

  /// 시간 포맷팅 (정적 메서드 버전)
  static String formatPauseTimeLimit(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$remainingMinutes분';
    } else if (remainingMinutes == 0) {
      return '$hours시간';
    } else {
      return '$hours시간 $remainingMinutes분';
    }
  }

  /// 유효한 일시정지 제한시간 범위인지 확인
  static bool isValidPauseTimeLimit(int minutes) {
    return minutes >= 30 && minutes <= 480;
  }

  /// 유효한 멤버 수 범위인지 확인
  static bool isValidMemberLimit(int count) {
    return count >= 2 && count <= 100;
  }

  /// 유효한 그룹 이름인지 확인
  static bool isValidGroupName(String name) {
    final trimmed = name.trim();
    return trimmed.length >= 2 &&
        trimmed.length <= 50 &&
        RegExp(r'^[가-힣a-zA-Z0-9\s\-_.]+$').hasMatch(trimmed);
  }

  /// 유효한 그룹 설명인지 확인
  static bool isValidGroupDescription(String description) {
    final trimmed = description.trim();
    return trimmed.length >= 10 && trimmed.length <= 500;
  }

  /// 유효한 해시태그인지 확인
  static bool isValidHashTag(String tag) {
    final trimmed = tag.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= 20 &&
        RegExp(r'^[가-힣a-zA-Z0-9\s]+$').hasMatch(trimmed);
  }
}
