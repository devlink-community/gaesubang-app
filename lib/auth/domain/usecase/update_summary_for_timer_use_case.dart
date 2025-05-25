// lib/auth/domain/usecase/update_summary_for_timer_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_activity_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 타이머 종료 후 사용자 Summary 업데이트 UseCase
class UpdateSummaryForTimerUseCase {
  final AuthActivityRepository _authActivityRepository;

  UpdateSummaryForTimerUseCase({
    required AuthActivityRepository authActivityRepository,
  }) : _authActivityRepository = authActivityRepository;

  /// 타이머 종료 후 Summary 업데이트 실행
  Future<Result<void>> execute({
    required String groupId,
    required int elapsedSeconds,
    DateTime? timestamp,
  }) async {
    try {
      AppLogger.debug(
        'Summary 업데이트 시작: groupId=$groupId, seconds=$elapsedSeconds',
        tag: 'UpdateSummaryForTimerUseCase',
      );

      // 1. 현재 사용자 ID 확인
      final userId = _getCurrentUserId();
      if (userId == null) {
        return Result.error(
          Failure(
            FailureType.unauthorized,
            '로그인이 필요합니다',
          ),
        );
      }

      // 2. 날짜 키 생성 (오늘 날짜 기준)
      final dateKey = TimeFormatter.formatDate(timestamp ?? DateTime.now());

      // 3. Summary 업데이트 요청
      final result = await _authActivityRepository
          .updateSummaryForTimerActivity(
            userId: userId,
            groupId: groupId,
            elapsedSeconds: elapsedSeconds,
            dateKey: dateKey,
          );

      if (result is Error) {
        AppLogger.error(
          'Summary 업데이트 실패',
          tag: 'UpdateSummaryForTimerUseCase',
          error: result.failure,
        );
        return result;
      }

      AppLogger.info(
        'Summary 업데이트 성공: userId=$userId, groupId=$groupId, elapsedSeconds=$elapsedSeconds',
        tag: 'UpdateSummaryForTimerUseCase',
      );

      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error(
        'Summary 업데이트 중 예외 발생',
        tag: 'UpdateSummaryForTimerUseCase',
        error: e,
        stackTrace: st,
      );
      return Result.error(
        Failure(
          FailureType.unknown,
          '통계 정보 업데이트 중 오류가 발생했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// 현재 사용자 ID 확인
  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
