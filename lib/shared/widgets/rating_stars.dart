import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';

/// Блок рейтинга заведения: звезда + оценка + количество отзывов.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    required this.reviewsCount,
    super.key,
    this.compact = false,
  });

  final double rating;
  final int reviewsCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Рейтинг ${rating.toStringAsFixed(1)}, отзывов $reviewsCount',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: compact ? 16 : 18,
            color: AppColors.accentDark,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            rating.toStringAsFixed(1),
            style: (compact ? AppTextStyles.caption : AppTextStyles.bodyMedium)
                .copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($reviewsCount)',
            style: compact ? AppTextStyles.caption : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
