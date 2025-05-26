import 'package:devlink_mobile_app/core/utils/time_formatter.dart';

import '../../domain/model/banner.dart';
import '../dto/banner_dto.dart';

extension BannerDtoMapper on BannerDto {
  Banner toModel() {
    return Banner(
      id: id ?? '',
      title: title ?? '제목 없음',
      imageUrl: imageUrl ?? '',
      linkUrl: linkUrl,
      isActive: isActive ?? false,
      displayOrder: displayOrder?.toInt() ?? 0,
      startDate: startDate ?? TimeFormatter.nowInSeoul(),
      endDate:
          endDate ?? TimeFormatter.nowInSeoul().add(const Duration(days: 1)),
      targetAudience: targetAudience,
      createdAt: createdAt ?? TimeFormatter.nowInSeoul(),
    );
  }
}

extension BannerModelMapper on Banner {
  BannerDto toDto() {
    return BannerDto(
      id: id,
      title: title,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      isActive: isActive,
      displayOrder: displayOrder,
      startDate: startDate,
      endDate: endDate,
      targetAudience: targetAudience,
      createdAt: createdAt,
    );
  }
}

extension BannerDtoListMapper on List<BannerDto>? {
  List<Banner> toModelList() =>
      this?.map((dto) => dto.toModel()).toList() ?? [];
}

extension BannerModelListMapper on List<Banner>? {
  List<BannerDto> toDtoList() =>
      this?.map((model) => model.toDto()).toList() ?? [];
}
