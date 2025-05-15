import 'package:freezed_annotation/freezed_annotation.dart';

part 'notice.freezed.dart';

@freezed
class Notice with _$Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.linkUrl,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? linkUrl;
}
