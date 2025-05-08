// lib/map/presentation/components/radius_slider.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class RadiusSlider extends StatelessWidget {
  final double radius;
  final Function(double) onRadiusChanged;

  const RadiusSlider({
    super.key,
    required this.radius,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('검색 반경', style: AppTextStyles.body2Regular),
              const Spacer(),
              Text(
                '${radius.toStringAsFixed(1)}km',
                style: AppTextStyles.subtitle2Regular.copyWith(
                  color: AppColorStyles.primary100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: radius,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            activeColor: AppColorStyles.primary100,
            label: '${radius.toStringAsFixed(1)}km',
            onChanged: onRadiusChanged,
          ),
        ],
      ),
    );
  }
}
