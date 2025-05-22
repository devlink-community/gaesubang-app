import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner.freezed.dart';

@freezed
class Banner with _$Banner {
  const Banner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.linkUrl,
    this.displayOrder = 0,
    this.targetAudience,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int displayOrder;
  final DateTime startDate;
  final DateTime endDate;
  final String? targetAudience;
  final DateTime createdAt;
}