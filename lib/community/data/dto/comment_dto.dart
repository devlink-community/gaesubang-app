// lib/community/data/dto/comment_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

@freezed
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    String? userId,
    String? userName,
    String? userProfileImage,
    String? text,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? createdAt,
    int? likeCount,
  }) = _CommentDto;

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
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