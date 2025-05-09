import 'package:devlink_mobile_app/group/data/dto/timer_session_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_session.dart';

// DTO → Model 변환
extension TimerSessionDtoMapper on TimerSessionDto {
  TimerSession toModel() {
    return TimerSession(
      id: id ?? '',
      groupId: groupId ?? '',
      userId: userId ?? '',
      startTime: startTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      endTime: endTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      duration: duration ?? 0,
      isCompleted: isCompleted ?? false,
    );
  }
}

// Model → DTO 변환
extension TimerSessionModelMapper on TimerSession {
  TimerSessionDto toDto() {
    return TimerSessionDto(
      id: id,
      groupId: groupId,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      isCompleted: isCompleted,
    );
  }
}

// List<TimerSessionDto> → List<TimerSession> 변환
extension TimerSessionDtoListMapper on List<TimerSessionDto>? {
  List<TimerSession> toModelList() =>
      this?.map((e) => e.toModel()).toList() ?? [];
}

// List<TimerSession> → List<TimerSessionDto> 변환
extension TimerSessionModelListMapper on List<TimerSession> {
  List<TimerSessionDto> toDtoList() => map((e) => e.toDto()).toList();
}
