import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';

/// Основная кнопка действия (Design Toidym.svg: золотая пилюля #FFC94D с текстом #2B2350).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.enableHaptics = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading || onPressed == null
              ? null
              : () {
                  if (enableHaptics) {
                    HapticFeedback.lightImpact();
                  }
                  onPressed!();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnAccent,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.45),
            disabledForegroundColor: AppColors.textOnAccent.withValues(alpha: 0.6),
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonBorderRadius,
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.textOnAccent,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: AppColors.textOnAccent),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textOnAccent,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Вторичная кнопка бренда (Figma Design Toidym: белый фон #FFFFFF, обводка #2B2350, текст #2B2350).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.enableHaptics = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading || onPressed == null
              ? null
              : () {
                  if (enableHaptics) {
                    HapticFeedback.lightImpact();
                  }
                  onPressed!();
                },
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.primary.withValues(alpha: 0.45),
            side: BorderSide(
              color: onPressed == null
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.primary,
              width: 1.5,
            ),
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonBorderRadius,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
