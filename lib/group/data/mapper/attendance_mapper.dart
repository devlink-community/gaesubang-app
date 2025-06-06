// lib/group/data/mapper/attendance_mapper.dart
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/data/dto/attendance_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';

extension AttendanceDtoMapper on AttendanceDto {
  Attendance toModel({
    String? userName,
    String? profileUrl,
  }) {
    // 날짜 문자열을 DateTime으로 변환
    DateTime date;
    try {
      // 빈 문자열 체크 추가
      if (this.date == null || this.date!.isEmpty) {
        // 기본값으로 현재 시간 사용
        date = TimeFormatter.nowInSeoul();
      } else {
        date = TimeFormatter.parseDate(this.date!);
      }
    } catch (e) {
      // 기본값으로 현재 날짜 사용
      date = TimeFormatter.nowInSeoul();
    }

    // 초 단위를 분 단위로 변환
    final timeInMinutes = (timeInSeconds ?? 0) ~/ 60;

    return Attendance(
      groupId: groupId ?? '',
      userId: userId ?? '',
      userName: userName ?? 'Unknown',
      profileUrl: profileUrl,
      date: date,
      timeInMinutes: timeInMinutes,
    );
  }
}

extension AttendanceDtoListMapper on List<AttendanceDto> {
  List<Attendance> toModelList({
    Map<String, String>? userNames,
    Map<String, String>? profileUrls,
  }) {
    return map((dto) {
      final userId = dto.userId ?? '';
      return dto.toModel(
        userName: userNames?[userId] ?? 'Unknown',
        profileUrl: profileUrls?[userId],
      );
    }).toList();
  }
}
