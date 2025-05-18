// lib/community/domain/model/like.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'like.freezed.dart';

@freezed
class Like with _$Like {
  const Like({
    required this.userId, 
    required this.userName,
    required this.timestamp,
  });

  final String userId;
  final String userName;
  final DateTime timestamp;
}