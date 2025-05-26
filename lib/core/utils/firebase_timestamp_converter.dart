// lib/core/utils/firebase_timestamp_converter.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;

/// Firebase Timestamp와 DateTime 간의 변환을 담당하는 유틸리티 클래스
class FirebaseTimestampConverter {
  FirebaseTimestampConverter._(); // 인스턴스화 방지

  // 한국 시간대 설정
  static final _seoulTimeZone = tz.getLocation('Asia/Seoul');

  /// Firebase Timestamp, String, int를 DateTime으로 변환
  /// 모든 시간은 한국 시간(Asia/Seoul)으로 변환됨
  static DateTime? timestampFromJson(dynamic value) {
    if (value == null) return null;

    DateTime? utcTime;

    // Firebase Timestamp 객체인 경우
    if (value is Timestamp) {
      utcTime = value.toDate();
    }
    // ISO 8601 문자열인 경우
    else if (value is String) {
      try {
        utcTime = DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    // Unix timestamp (밀리초)인 경우
    else if (value is int) {
      try {
        utcTime = DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }

    if (utcTime == null) return null;

    // UTC 시간을 한국 시간대로 변환
    return tz.TZDateTime.from(utcTime, _seoulTimeZone);
  }

  /// DateTime을 Firebase Timestamp로 변환
  /// 한국 시간을 UTC로 변환하여 Timestamp 생성
  static dynamic timestampToJson(DateTime? dateTime) {
    if (dateTime == null) return null;

    // 한국 시간을 UTC로 변환
    final utcTime = dateTime.toUtc();
    return Timestamp.fromDate(utcTime);
  }

  /// 서버 타임스탬프 필드값 반환
  /// Firestore 서버의 현재 시간을 사용할 때 사용
  static FieldValue serverTimestamp() {
    return FieldValue.serverTimestamp();
  }

  /// Firebase 타임스탬프를 한국 날짜 문자열(YYYY-MM-DD)로 변환
  static String formatTimestampToDateString(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final datetime = timestampFromJson(timestamp);
    if (datetime == null) return '';

    return '${datetime.year}-${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')}';
  }

  /// Firebase 타임스탬프를 한국 시간 문자열(YYYY-MM-DD HH:MM)로 변환
  static String formatTimestampToDateTimeString(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final datetime = timestampFromJson(timestamp);
    if (datetime == null) return '';

    return '${datetime.year}-${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')} '
        '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
  }
}
