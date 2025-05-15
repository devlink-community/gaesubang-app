// lib/core/component/error_view.dart
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconSize = 64.0,
    this.iconColor,
    this.title = '오류가 발생했습니다',
    this.showErrorDetails = true,
  });

  final dynamic error;
  final VoidCallback? onRetry;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String title;
  final bool showErrorDetails;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (showErrorDetails && error != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatError(error),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor.withAlpha(153), // 255 * 0.6 = 153
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      String errorStr = error.toString();
      // Exception: 문자열 제거
      if (errorStr.startsWith('Exception: ')) {
        errorStr = errorStr.substring('Exception: '.length);
      }
      return errorStr;
    }
    return error.toString();
  }
}