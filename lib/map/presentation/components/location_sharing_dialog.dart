// lib/map/presentation/components/location_sharing_dialog.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class LocationSharingDialog extends StatefulWidget {
  final String groupName;
  final double initialRadius;
  final void Function(bool shareLocation, double radius) onResult;

  const LocationSharingDialog({
    super.key,
    required this.groupName,
    required this.initialRadius,
    required this.onResult,
  });

  @override
  State<LocationSharingDialog> createState() => _LocationSharingDialogState();
}

class _LocationSharingDialogState extends State<LocationSharingDialog> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('위치 공유 동의', style: AppTextStyles.heading6Bold),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.groupName}" 그룹 내 위치를 공유하시겠습니까?',
            style: AppTextStyles.body1Regular,
          ),
          const SizedBox(height: 16),
          Text(
            '위치 정보는 그룹 멤버들에게만 표시되며, 앱을 종료하거나 그룹을 나가면 자동으로 공유가 중단됩니다.',
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '검색 반경 설정: ${_radius.toStringAsFixed(1)}km',
            style: AppTextStyles.subtitle1Bold,
          ),
          Slider(
            value: _radius,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            activeColor: AppColorStyles.primary100,
            label: '${_radius.toStringAsFixed(1)}km',
            onChanged: (value) {
              setState(() {
                _radius = value;
              });
            },
          ),
          Text(
            '설정한 반경 내의 그룹 멤버들만 지도에 표시됩니다.',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onResult(false, _radius),
          child: Text(
            '거부',
            style: AppTextStyles.button1Medium.copyWith(
              color: AppColorStyles.error,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorStyles.primary100,
            foregroundColor: Colors.white,
          ),
          onPressed: () => widget.onResult(true, _radius),
          child: Text('동의하기', style: AppTextStyles.button1Medium),
        ),
      ],
    );
  }
}
