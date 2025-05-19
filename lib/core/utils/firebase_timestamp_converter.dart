import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Timestamp와 DateTime 간의 변환을 담당하는 유틸리티 클래스
class FirebaseTimestampConverter {
  FirebaseTimestampConverter._(); // 인스턴스화 방지

  /// Firebase Timestamp, String, int를 DateTime으로 변환
  static DateTime? timestampFromJson(dynamic value) {
    if (value == null) return null;

    // Firebase Timestamp 객체인 경우
    if (value is Timestamp) {
      return value.toDate();
    }

    // ISO 8601 문자열인 경우
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    // Unix timestamp (밀리초)인 경우
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// DateTime을 Firebase Timestamp로 변환
  static dynamic timestampToJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}
