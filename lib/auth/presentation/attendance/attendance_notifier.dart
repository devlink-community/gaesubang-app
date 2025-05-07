import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecase/get_group_attendance_use_case.dart';
import '../../module/auth_di.dart';
import 'attendance_state.dart';
import 'attendance_action.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetGroupAttendanceUseCase _getAttendance;

  @override
  AttendanceState build() {
    _getAttendance = ref.watch(getGroupAttendanceUseCaseProvider);
    return const AttendanceState();
  }

  Future<void> onAction(AttendanceAction action) async {
    switch (action) {
      case LoadAttendance(:final date):
        state = state.copyWith(attendances: const AsyncLoading());
        final result = await _getAttendance.execute('group123', date);
        state = state.copyWith(attendances: result);

      case SelectMember(:final memberId):
        state = state.copyWith(selectedMemberId: memberId);
    }
  }
}