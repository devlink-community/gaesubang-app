import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';

@freezed
class Location with _$Location {
  const Location({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final String address;
  final int? timestamp;
}
