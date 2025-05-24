// lib/auth/data/mapper/user_dto_mapper.dart
import '../../domain/model/user.dart';
import '../dto/user_dto.dart';
import 'summary_mapper.dart';

extension UserDtoMapper on UserDto {
  User toModel() {
    return User(
      id: uid ?? '',
      email: email ?? '',
      nickname: nickname ?? '',
      uid: uid ?? '',
      image: image ?? '',
      onAir: onAir ?? false,
      description: description ?? '',
      streakDays: streakDays ?? 0,
      position: position,
      skills: skills,
      joinedGroups: joinedGroups ?? [],
      focusStats: null, // deprecated - 추후 제거
      summary: userSummary?.toModel(), // SummaryDto를 Summary로 변환
    );
  }
}

extension UserModelMapper on User {
  UserDto toDto() {
    return UserDto(
      email: email,
      nickname: nickname,
      uid: uid,
      image: image,
      description: description,
      isServiceTermsAgreed: true, // 기본값
      isPrivacyPolicyAgreed: true, // 기본값
      isMarketingAgreed: false, // 기본값
      agreedAt: null,
      joinedGroups: joinedGroups,
      position: position,
      skills: skills,
      onAir: onAir,
      streakDays: streakDays,
      userSummary: summary?.toDto(), // Summary를 SummaryDto로 변환
    );
  }
}

// Map에서 직접 User로 변환하는 extension 추가
extension MapToUserMapper on Map<String, dynamic> {
  User toUser() {
    // UserDto를 거쳐서 변환
    final userDto = UserDto.fromJson(this);
    return userDto.toModel();
  }
}

// List 변환 확장
extension UserDtoListMapper on List<UserDto>? {
  List<User> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}

extension UserModelListMapper on List<User> {
  List<UserDto> toDtoList() => map((e) => e.toDto()).toList();
}
