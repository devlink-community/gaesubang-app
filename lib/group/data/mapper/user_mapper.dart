
import '../../domain/model/user_model.dart';
import '../dto/user_dto.dart';

extension UserDtoMapper on UserDto {
  UserModel toModel() {
    return UserModel(id: id ?? '', email: email ?? '', nickname: nickname ?? '');
  }
}

extension UserModelMapper on UserModel {
  UserDto toDto() {
    return UserDto(id: id, email: email, nickname: nickname);
  }
}

extension MapToUserDto on Map<String, dynamic> {
  UserDto toUserDto() => UserDto.fromJson(this);
}
