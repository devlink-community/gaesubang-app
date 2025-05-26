// lib/auth/domain/usecase/update_summary_for_timer_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_activity_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart'; // 추가: TimerActivityType import
import 'package:firebase_auth/firebase_auth.dart';

/// 타이머 종료 후 사용자 Summary 업데이트 UseCase
class UpdateSummaryForTimerUseCase {
  final AuthActivityRepository _authActivityRepository;

  UpdateSummaryForTimerUseCase({
    required AuthActivityRepository authActivityRepository,
  }) : _authActivityRepository = authActivityRepository;

  /// 타이머 활동 후 Summary 업데이트 실행
  ///
  /// [groupId] 타이머 활동이 발생한 그룹 ID
  /// [timerState] 타이머 상태 (start, pause, resume, end 등)
  /// [elapsedSeconds] 경과 시간(초) - pause/end 상태에서만 필요
  /// [timestamp] 타이머 활동 시간 (기본값: 현재 시간)
  Future<Result<void>> execute({
    required String groupId,
    required TimerActivityType timerState, // 첫 번째 필수 파라미터로 이동
    int? elapsedSeconds, // nullable로 변경
    DateTime? timestamp,
  }) async {
    try {
      // elapsedSeconds 검증 로직 추가
      // pause나 end 상태일 때만 elapsedSeconds가 필요
      if ((timerState == TimerActivityType.pause ||
              timerState == TimerActivityType.end) &&
          elapsedSeconds == null) {
        AppLogger.warning(
          'pause 또는 end 상태에서는 elapsedSeconds가 필요합니다',
          tag: 'UpdateSummaryForTimerUseCase',
        );
        return Result.error(
          Failure(
            FailureType.validation,
            'pause 또는 end 상태에서는 경과 시간이 필요합니다',
          ),
        );
      }

      // start나 resume 상태일 때 elapsedSeconds가 있으면 경고 로그
      if ((timerState == TimerActivityType.start ||
              timerState == TimerActivityType.resume) &&
          elapsedSeconds != null) {
        AppLogger.warning(
          'start 또는 resume 상태에서는 elapsedSeconds가 무시됩니다',
          tag: 'UpdateSummaryForTimerUseCase',
        );
        // 값을 null로 설정
        elapsedSeconds = null;
      }

      AppLogger.debug(
        'Summary 업데이트 시작: groupId=$groupId, state=${timerState.name}, '
        'seconds=${elapsedSeconds ?? "N/A"}',
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
      final dateKey = TimeFormatter.formatDate(
        timestamp ?? TimeFormatter.nowInSeoul(),
      );

      // 3. Summary 업데이트 요청
      final result = await _authActivityRepository
          .updateSummaryForTimerActivity(
            userId: userId,
            groupId: groupId,
            elapsedSeconds: elapsedSeconds,
            dateKey: dateKey,
            timerState: timerState,
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
        'Summary 업데이트 성공: userId=$userId, groupId=$groupId, '
        'state=${timerState.name}, elapsedSeconds=${elapsedSeconds ?? "N/A"}',
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
