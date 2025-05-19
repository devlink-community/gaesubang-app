import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupDto {
  const GroupDto({
    this.name,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.createdBy,
    this.maxMemberCount,
    this.hashTags,
  });

  final String? name;
  final String? description;
  final String? imageUrl;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? createdAt;
  final String? createdBy;
  final int? maxMemberCount;
  final List<String>? hashTags;

  factory GroupDto.fromJson(Map<String, dynamic> json) =>
      _$GroupDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDtoToJson(this);
}

// Timestamp 변환 유틸리티 함수
DateTime? _timestampFromJson(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

dynamic _timestampToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
