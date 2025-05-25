import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Timestamp와 DateTime 간의 변환을 담당하는 유틸리티 클래스
class FirebaseTimestampConverter {
  FirebaseTimestampConverter._(); // 인스턴스화 방지

  /// 일관된 서버 타임스탬프 생성
  static dynamic createServerTimestamp() {
    return FieldValue.serverTimestamp();
  }

  /// 안전한 DateTime 변환 (Timestamp, DateTime, int, String 지원)
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }

    if (value is String) {
      // ISO 8601 등 지원
      return DateTime.tryParse(value);
    }

    return null;
  }

  /// 모든 입력 값을 Firebase Timestamp로 변환
  static Timestamp? toFirebaseTimestamp(dynamic value) {
    final dateTime = toDateTime(value);
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}