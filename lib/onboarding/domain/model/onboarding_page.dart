// lib/onboarding/domain/model/onboarding_page_model.dart
import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final String? actionButtonText;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.actionButtonText,
  });
}
