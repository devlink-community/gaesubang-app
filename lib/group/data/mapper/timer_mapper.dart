import '../../domain/model/member_attendance.dart';
import '../../domain/model/timer.dart';
import '../dto/timer_dto.dart';

extension TimerDtoMapper on TimerDto {
  Timer toModel() {
    return Timer(
      memberId: memberId,
      minTime: minTime,
      totalTime: totalTime,
    );
  }
}

extension TimerDtoListMapper on List<TimerDto> {
  List<Timer> toModelList() => map((e) => e.toModel()).toList();
}