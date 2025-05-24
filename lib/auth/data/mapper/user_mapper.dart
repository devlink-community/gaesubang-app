// lib/auth/data/mapper/user_dto_mapper.dart
import '../../domain/model/user.dart';
import '../dto/user_dto.dart';

extension UserDtoMapper on UserDto {
  User toModel() {
    return User(
      id: uid ?? '',
      email: email ?? '',
      nickname: nickname ?? '',
      uid: uid ?? '',
      image: image ?? '',
      onAir: false, // UserDto에 없는 필드는 기본값
      agreedTermsId: agreedTermId,
      description: description ?? '',
      streakDays: 0, // UserDto에 없는 필드는 기본값
      position: position,
      skills: skills,
      joinedGroups: joinedGroups ?? [],
      focusStats: null, // deprecated - 추후 제거
      summary: null, // 별도로 조회하여 설정
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
      agreedTermId: agreedTermsId,
      description: description,
      isServiceTermsAgreed: true, // 기본값
      isPrivacyPolicyAgreed: true, // 기본값
      isMarketingAgreed: false, // 기본값
      agreedAt: null,
      joinedGroups: joinedGroups,
      position: position,
      skills: skills,
    );
  }
}

// List 변환 확장
extension UserDtoListMapper on List<UserDto>? {
  List<User> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}

extension UserModelListMapper on List<User> {
  List<UserDto> toDtoList() => map((e) => e.toDto()).toList();
}
