import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';
import 'package:toidym/shared/widgets/rating_stars.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

enum _StatsPeriod { day, week, month }

/// Экран статистики без комиссии (0%), упущенной выгоды (Lost Profit) и умных советов Құмбека.
class VenueStatsScreen extends ConsumerStatefulWidget {
  const VenueStatsScreen({super.key});

  @override
  ConsumerState<VenueStatsScreen> createState() => _VenueStatsScreenState();
}

class _VenueStatsScreenState extends ConsumerState<VenueStatsScreen> {
  _StatsPeriod _period = _StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venueId = ref.watch(managedVenueIdProvider);
    final venue = ref.watch(venuesMapProvider)[venueId];
    final allOrders = ref.watch(allPlatformOrdersProvider);
    final allBoxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];

    final venueOrders =
        allOrders.where((o) => o.venueId == venueId).toList(growable: false);
    final liveCompleted = venueOrders
        .where((o) => o.status == OrderStatus.completed)
        .toList(growable: false);
    final liveNoShow =
        venueOrders.where((o) => o.status == OrderStatus.noShow).length;

    final liveRevenue =
        liveCompleted.fold<int>(0, (sum, o) => sum + o.totalPrice);
    final liveCompletedQty =
        liveCompleted.fold<int>(0, (sum, o) => sum + o.quantity);

    final (baselineRevenue, baselineBoxes) = switch (_period) {
      _StatsPeriod.day => (0, 0),
      _StatsPeriod.week => (84500, 86),
      _StatsPeriod.month => (362000, 368),
    };

    final totalRevenue = baselineRevenue + liveRevenue;
    final totalSoldBoxes = baselineBoxes + liveCompletedQty;
    final foodKg = totalSoldBoxes * 0.65;

    final expiredBoxes = allBoxes
        .where((b) => b.venueId == venueId && b.isExpired)
        .toList(growable: false);
    final lostProfit = BoxBusinessRules.calculateLostProfit(expiredBoxes);
    final expiredCount = expiredBoxes.fold<int>(
      0,
      (sum, b) => sum + (b.quantityLeft > 0 ? b.quantityLeft : 1),
    );

    final String qumbekAdvice;
    if (expiredCount > 0) {
      qumbekAdvice = l10n.venueQumbekAdviceHighRemaining;
    } else if (liveNoShow > 0) {
      qumbekAdvice = l10n.venueQumbekAdviceHighNoShow;
    } else {
      qumbekAdvice = l10n.venueQumbekAdviceGreat;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.screenVenueStatsTitle,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            108,
          ),
          children: [
            Center(
              child: ToidymPillToggle<_StatsPeriod>(
                selected: _period,
                items: [
                  (value: _StatsPeriod.day, label: l10n.venueStatsDay),
                  (value: _StatsPeriod.week, label: l10n.venueStatsWeek),
                  (value: _StatsPeriod.month, label: l10n.venueStatsMonth),
                ],
                onSelected: (p) => setState(() => _period = p),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.55,
              children: [
                _StatTile(
                  label: l10n.venueTodayRevenue,
                  value: AppFormatters.formatPrice(totalRevenue),
                ),
                _StatTile(
                  label: l10n.venueStatsCompletedOrders,
                  value: '$totalSoldBoxes',
                ),
                _StatTile(
                  label: l10n.venueStatsFoodSaved,
                  value: AppFormatters.formatWeightKg(foodKg, l10n),
                ),
                _StatTile(
                  label: l10n.venueStatsNoShowOrders,
                  value: '$liveNoShow',
                  valueColor: liveNoShow > 0 ? AppColors.error : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Модель без комиссии (0%)
            Card(
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.venueStatsZeroCommission,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatPrice(totalRevenue),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.paymentOfflineBadge,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Карточка упущенной выгоды (Lost Profit)
            Card(
              color: lostProfit > 0 ? AppColors.warningLight : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.venueStatsLostProfitTitle,
                          style: AppTextStyles.titleMedium,
                        ),
                        Text(
                          AppFormatters.formatPrice(lostProfit),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: lostProfit > 0
                                ? AppColors.warningText
                                : AppColors.successText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.venueStatsLostProfitSubtitle(expiredCount),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Умный совет маскота Құмбек
            Card(
              color: AppColors.accentLight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const QumbekMascot(size: 60, mood: QumbekMood.tip),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        qumbekAdvice,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Рейтинг и отзывы
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.venueStatsReviews, style: AppTextStyles.titleMedium),
                if (venue != null)
                  RatingStars(
                    rating: venue.rating,
                    reviewsCount: venue.reviewsCount,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            FutureBuilder<List<Review>>(
              future: ref.read(venueRepositoryProvider).getVenueReviews(venueId),
              builder: (context, snapshot) {
                final reviews = snapshot.data ?? const [];
                return Column(
                  children: [
                    for (final review in reviews) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review.authorName,
                                    style: AppTextStyles.bodyLargeMedium,
                                  ),
                                  Text('★ ${review.rating}'),
                                ],
                              ),
                              if (review.comment.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  review.comment,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge.copyWith(
                color: valueColor ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
