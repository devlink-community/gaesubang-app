import 'package:json_annotation/json_annotation.dart';

import '../../../core/utils/firebase_timestamp_converter.dart';

part 'post_like_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class PostLikeDto {
  const PostLikeDto({this.userId, this.userName, this.timestamp});

  final String? userId;
  final String? userName;
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timestamp;

  factory PostLikeDto.fromJson(Map<String, dynamic> json) =>
      _$PostLikeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostLikeDtoToJson(this);
}
