import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/formatters.dart';

/// Отображение цены: старая зачёркнутая → новая крупно (`2 970 ₸`).
class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.originalPrice,
    required this.discountPrice,
    super.key,
    this.large = false,
  });

  final int originalPrice;
  final int discountPrice;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final oldFormatted = AppFormatters.formatPrice(originalPrice);
    final newFormatted = AppFormatters.formatPrice(discountPrice);

    return Semantics(
      label: '$newFormatted (вместо $oldFormatted)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            oldFormatted,
            style: AppTextStyles.priceOld.copyWith(
              fontSize: large ? 15 : 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            newFormatted,
            style: AppTextStyles.priceNew.copyWith(
              fontSize: large ? 24 : 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Строчная версия цены для компактных мест и списков.
class InlinePriceTag extends StatelessWidget {
  const InlinePriceTag({
    required this.originalPrice,
    required this.discountPrice,
    super.key,
  });

  final int originalPrice;
  final int discountPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          AppFormatters.formatPrice(originalPrice),
          style: AppTextStyles.priceOld,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          AppFormatters.formatPrice(discountPrice),
          style: AppTextStyles.priceNew,
        ),
      ],
    );
  }
}
