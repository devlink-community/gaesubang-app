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
  static String formatElapsedTime(
    DateTime startTime, {
    bool includeSeconds = true,
  }) {
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
    DateTime endTime, {
    bool includeSeconds = true,
  }) {
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
    return now.add(Duration(hours: hours, minutes: minutes, seconds: seconds));
  }

  // ===== 새로 추가되는 헬퍼 메서드들 =====

  /// 일시정지 경과 시간이 제한 시간을 초과했는지 확인
  ///
  /// [pauseTime] 일시정지 시작 시간
  /// [limitMinutes] 제한 시간 (분 단위)
  /// 반환: 초과 여부
  static bool isPauseTimeExceeded(DateTime pauseTime, int limitMinutes) {
    final now = DateTime.now();
    final pauseDuration = now.difference(pauseTime);
    return pauseDuration.inMinutes >= limitMinutes;
  }

  /// 일시정지 경과 시간 계산 (분 단위)
  ///
  /// [pauseTime] 일시정지 시작 시간
  /// 반환: 경과 시간 (분)
  static int getPauseElapsedMinutes(DateTime pauseTime) {
    final now = DateTime.now();
    final pauseDuration = now.difference(pauseTime);
    return pauseDuration.inMinutes;
  }

  /// 자정까지 남은 시간 계산
  ///
  /// 반환: 현재 시간부터 다음날 00:00:00까지의 Duration
  static Duration timeUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// 어제의 마지막 시간 (23:59:59) 반환
  ///
  /// 반환: 어제 23:59:59의 DateTime
  static DateTime getYesterdayLastSecond() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
  }

  /// 오늘의 첫 시간 (00:00:00) 반환
  ///
  /// 반환: 오늘 00:00:00의 DateTime
  static DateTime getTodayFirstSecond() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 0, 0, 0);
  }

  /// 주어진 날짜가 오늘인지 확인
  ///
  /// [date] 확인할 날짜
  /// 반환: 오늘 여부
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 주어진 날짜가 어제인지 확인
  ///
  /// [date] 확인할 날짜
  /// 반환: 어제 여부
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// 두 날짜가 같은 날인지 확인
  ///
  /// [date1] 첫 번째 날짜
  /// [date2] 두 번째 날짜
  /// 반환: 같은 날 여부
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 타이머 자동 종료 시간 계산
  ///
  /// [pauseTime] 일시정지 시간
  /// 반환: 일시정지 시간 + 1초
  static DateTime getAutoEndTime(DateTime pauseTime) {
    return pauseTime.add(const Duration(microseconds: 1));
  }
}
