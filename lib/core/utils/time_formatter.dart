// lib/core/utils/time_formatter.dart
import 'package:intl/intl.dart';

/// 시간 포맷 관련 유틸리티 클래스
class TimeFormatter {
  const TimeFormatter._(); // 인스턴스화 방지

  /// 초 단위의 시간을 HH:MM:SS 형식으로 변환
  ///
  /// [seconds] 초 단위 시간 (예: 3600 -> 01:00:00)
  /// [includeSeconds] 초 단위 포함 여부
  ///
  /// 25시간 이상도 처리 가능 (예: 90000초 -> 25:00:00)
  static String formatSeconds(int seconds, {bool includeSeconds = true}) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return includeSeconds
        ? '$hoursStr:$minutesStr:$secondsStr'
        : '$hoursStr:$minutesStr';
  }

  /// 분 단위의 시간을 HH:MM:SS 형식으로 변환
  ///
  /// [minutes] 분 단위 시간 (예: 90 -> 01:30:00)
  /// [includeSeconds] 초 단위 포함 여부
  static String formatMinutes(int minutes, {bool includeSeconds = true}) {
    return formatSeconds(minutes * 60, includeSeconds: includeSeconds);
  }

  /// 시작 시간부터 현재까지의 경과 시간을 HH:MM:SS 형식으로 변환
  ///
  /// [startTime] 시작 시간
  /// [includeSeconds] 초 단위 포함 여부
  static String formatElapsedTime(DateTime startTime, {bool includeSeconds = true}) {
    final now = DateTime.now();
    final difference = now.difference(startTime);
    return formatSeconds(difference.inSeconds, includeSeconds: includeSeconds);
  }

  /// 두 시간 사이의 간격을 HH:MM:SS 형식으로 변환
  ///
  /// [startTime] 시작 시간
  /// [endTime] 종료 시간
  /// [includeSeconds] 초 단위 포함 여부
  static String formatTimeDifference(
      DateTime startTime,
      DateTime endTime,
      {bool includeSeconds = true}
      ) {
    final difference = endTime.difference(startTime);
    return formatSeconds(difference.inSeconds, includeSeconds: includeSeconds);
  }

  /// DateTime을 "yyyy-MM-dd" 형식의 문자열로 변환
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// DateTime을 "yyyy-MM-dd HH:mm" 형식의 문자열로 변환
  static String formatDatetime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// DateTime을 "yyyy년 MM월 dd일" 형식의 한글 문자열로 변환
  static String formatDateKorean(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  /// DateTime을 "a hh:mm" 형식의 문자열로 변환 (오전/오후 포함)
  static String formatTime12Hour(DateTime time) {
    return DateFormat('a hh:mm').format(time);
  }

  /// DateTime을 "HH:mm" 형식의 문자열로 변환 (24시간제)
  static String formatTime24Hour(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// "HH:mm:ss" 형식의 문자열을 초 단위로 변환
  ///
  /// 예: "01:30:45" -> 5445초
  static int timeStringToSeconds(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 3) {
      throw const FormatException('Invalid time format. Expected HH:MM:SS');
    }

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);

    return hours * 3600 + minutes * 60 + seconds;
  }

  /// 현재 시간에서 특정 시간을 더한 DateTime 반환
  ///
  /// [hours], [minutes], [seconds]를 각각 지정 가능
  static DateTime addTime({int hours = 0, int minutes = 0, int seconds = 0}) {
    final now = DateTime.now();
    return now.add(Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    ));
  }

  /// 남은 시간을 "HH:MM:SS" 형식으로 변환 (카운트다운 용도)
  ///
  /// [endTime] 종료 시간
  static String formatRemainingTime(DateTime endTime) {
    final now = DateTime.