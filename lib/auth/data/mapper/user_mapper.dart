import 'package:devlink_mobile_app/auth/data/dto/user_dto.dart';
import 'package:devlink_mobile_app/auth/domain/model/user.dart';

extension UserDtoMapper on UserDto {
  User toModel() {
    return User(id: id ?? '', email: email ?? '', nickname: nickname ?? '');
  }
}

extension UserModelMapper on User {
  UserDto toDto() {
    return UserDto(id: id, email: email, nickname: nickname);
  }
}

extension MapToUserDto on Map<String, dynamic> {
  UserDto toUserDto() => UserDto.fromJson(this);
}
