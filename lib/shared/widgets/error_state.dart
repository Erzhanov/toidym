import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';

/// Состояние ошибки с кнопкой «Повторить».
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.onRetry,
    super.key,
    this.title,
    this.subtitle,
  });

  final VoidCallback onRetry;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - AppSpacing.md * 2).clamp(
                0.0,
                double.infinity,
              )
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const QumbekMascot(size: 72, mood: QumbekMood.tip),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title ?? l10n.stateErrorTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle ?? l10n.stateErrorSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnCreamSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 220,
                    child: PrimaryButton(
                      label: l10n.actionRetry,
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
