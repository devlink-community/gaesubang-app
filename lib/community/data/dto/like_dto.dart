// lib/community/data/dto/like_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'like_dto.freezed.dart';
part 'like_dto.g.dart';

@freezed
abstract class LikeDto with _$LikeDto {
  const factory LikeDto({
    String? userId,
    String? userName,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? timestamp,
  }) = _LikeDto;

  factory LikeDto.fromJson(Map<String, dynamic> json) =>
      _$LikeDtoFromJson(json);
}

// DateTime JSON 변환 유틸리티 함수
DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;
  
  if (value is String) {
    return DateTime.parse(value);
  }
  
  if (value is Timestamp) {
    return value.toDate();
  }
  
  return null;
}

dynamic _dateTimeToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}