import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';

enum AppBadgeTone {
  halal,
  warning,
  accent,
  primary,
  success,
  error,
  neutral,
}

/// Бейдж статусов и меток («Халал», «Осталось N», «−67%», статус заказа).
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    required this.tone,
    super.key,
    this.icon,
    this.large = false,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppBadgeTone.halal => (AppColors.successLight, AppColors.successText),
      AppBadgeTone.warning => (AppColors.accentLight, AppColors.primary),
      AppBadgeTone.accent => (AppColors.accent, AppColors.textOnAccent),
      AppBadgeTone.primary => (AppColors.primary, AppColors.textOnPrimary),
      AppBadgeTone.success => (AppColors.success, AppColors.textOnPrimary),
      AppBadgeTone.error => (AppColors.errorLight, AppColors.errorText),
      AppBadgeTone.neutral => (AppColors.primaryLight, AppColors.primary),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppSpacing.sm : AppSpacing.xs + 2,
        vertical: large ? AppSpacing.xs - 2 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.badgeBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: large ? 15 : 13, color: fg),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: (large ? AppTextStyles.bodyMedium : AppTextStyles.caption)
                .copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
