import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

/// Экран владельца «Боксы сегодня»: вкладки Бүгінгі / Мұрағат (Архив), CRON-автоархивация и перевыставление в 1 клик.
class VenueBoxesTodayScreen extends ConsumerStatefulWidget {
  const VenueBoxesTodayScreen({super.key});

  @override
  ConsumerState<VenueBoxesTodayScreen> createState() =>
      _VenueBoxesTodayScreenState();
}

class _VenueBoxesTodayScreenState extends ConsumerState<VenueBoxesTodayScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref.read(boxRepositoryProvider).archiveExpiredBoxes(),
      ),
    );
  }

  PickupWindow _nextValidWindow(Venue? venue) {
    final now = DateTime.now();
    final openMin = venue?.workHours.openMinuteOfDay ?? 8 * 60;
    final closeMin = venue?.workHours.closeMinuteOfDay ?? 22 * 60;

    final candidateStart = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 3,
      0,
    );
    final candidateEnd = candidateStart.add(const Duration(hours: 1));
    final startMin = candidateStart.hour * 60 + candidateStart.minute;
    final endMin = candidateEnd.hour * 60 + candidateEnd.minute;

    if (startMin >= openMin && endMin <= closeMin) {
      return PickupWindow(start: candidateStart, end: candidateEnd);
    }

    final tomorrow = now.add(const Duration(days: 1));
    final safeStartMin = (closeMin - 120).clamp(openMin, closeMin - 60);
    final start = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      safeStartMin ~/ 60,
      safeStartMin % 60,
    );
    return PickupWindow(
      start: start,
      end: start.add(const Duration(hours: 1)),
    );
  }

  Future<void> _republishExpiredBox(Box box, Venue? venue) async {
    final l10n = context.l10n;
    final boxRepo = ref.read(boxRepositoryProvider);
    await boxRepo.republishExpiredBox(
      boxId: box.id,
      pickupWindow: _nextValidWindow(venue),
      quantity: box.quantity > 0 ? box.quantity : 5,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.venueRepublishedSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venueId = ref.watch(managedVenueIdProvider);
    final venuesMap = ref.watch(venuesMapProvider);
    final venue = venuesMap[venueId];
    final allBoxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];
    final venueBoxes =
        allBoxes.where((b) => b.venueId == venueId).toList(growable: false);
    final todayBoxes =
        venueBoxes.where((b) => !b.isExpired).toList(growable: false);
    final archiveBoxes =
        venueBoxes.where((b) => b.isExpired).toList(growable: false);

    final allOrders = ref.watch(ordersStreamProvider).valueOrNull ?? const [];
    final venueOrders = allOrders.where((o) => o.venueId == venueId).toList();

    final waitingCount = venueOrders.where((o) => o.status.isActive).length;
    final completedOrders =
        venueOrders.where((o) => o.status == OrderStatus.completed).toList();
    final soldBoxesCount =
        completedOrders.fold<int>(0, (sum, o) => sum + o.quantity);
    final todayRevenue =
        completedOrders.fold<int>(0, (sum, o) => sum + o.totalPrice);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            ToidymDarkHeader(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue?.name ?? l10n.screenVenueBoxesTodayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(activeAppModeProvider.notifier)
                            .setMode(AppMode.buyer),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: Text(
                          l10n.actionSwitchToBuyer,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.screenVenueSettingsTitle,
                        onPressed: () => context.push(AppRoutes.venueSettings),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: AppRadius.badgeBorderRadius,
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.badgeBorderRadius,
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textOnPrimary,
                      labelStyle: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: [
                        Tab(
                          height: 36,
                          text: '${l10n.venueTabToday} (${todayBoxes.length})',
                        ),
                        Tab(
                          height: 36,
                          text:
                              '${l10n.venueTabArchive} (${archiveBoxes.length})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Вкладка 1: Бүгінгі (Сегодня)
                  ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      108,
                    ),
                    children: [
                  if (venue != null && venue.status != VenueStatus.approved) ...[
                    Card(
                      color: venue.status == VenueStatus.rejected ||
                              venue.status == VenueStatus.banned
                          ? AppColors.errorLight
                          : AppColors.warningLight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.status == VenueStatus.banned
                                  ? l10n.venueStatusBanned
                                  : (venue.status == VenueStatus.rejected
                                      ? l10n.venueModerationRejectedBanner
                                      : l10n.venueModerationPendingBanner),
                              style: AppTextStyles.bodyLargeMedium.copyWith(
                                color: venue.status == VenueStatus.rejected ||
                                        venue.status == VenueStatus.banned
                                    ? AppColors.errorText
                                    : AppColors.warningText,
                              ),
                            ),
                            if (venue.rejectionComment != null &&
                                venue.rejectionComment!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                venue.rejectionComment!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.errorText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: _DayMetricCard(
                          value: '$soldBoxesCount',
                          label: l10n.venueTodaySold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _DayMetricCard(
                          value: '$waitingCount',
                          label: l10n.venueTodayWaiting,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _DayMetricCard(
                          value: AppFormatters.formatPrice(todayRevenue),
                          label: l10n.venueTodayRevenue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Card(
                    color: AppColors.accentLight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const QumbekMascot(size: 56, mood: QumbekMood.tip),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.venueQumbekTip,
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
                  PrimaryButton(
                    label: l10n.venueNewBoxButton,
                    icon: Icons.add_rounded,
                    onPressed: () => context.push(AppRoutes.venueNewBox),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (todayBoxes.isEmpty)
                    EmptyState(
                      title: l10n.stateEmptyBoxesTitle,
                      subtitle: l10n.venueQumbekTip,
                    )
                  else
                    for (final box in todayBoxes) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          box.title,
                                          style: AppTextStyles.titleMedium,
                                        ),
                                        if (box.isResale) ...[
                                          const SizedBox(height: 4),
                                          AppBadge(
                                            label: l10n.badgeResaleTag,
                                            tone: AppBadgeTone.error,
                                            icon: Icons
                                                .local_fire_department_rounded,
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(
                                          '${AppFormatters.formatPrice(box.discountPrice)} · ${box.pickupWindow.formatted}',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: box.status == BoxStatus.active,
                                    onChanged: (enabled) {
                                      ref
                                          .read(boxRepositoryProvider)
                                          .toggleBoxStatus(
                                            boxId: box.id,
                                            status: enabled
                                                ? BoxStatus.active
                                                : BoxStatus.disabled,
                                          );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  AppBadge(
                                    label:
                                        '${l10n.venueTodaySold}: ${(box.quantity - box.quantityLeft).clamp(0, box.quantity)}',
                                    tone: AppBadgeTone.neutral,
                                  ),
                                  const Spacer(),
                                  Text(
                                    l10n.venueStockLabel,
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  IconButton.filledTonal(
                                    onPressed: box.quantityLeft <= 0
                                        ? null
                                        : () => ref
                                            .read(boxRepositoryProvider)
                                            .updateBoxStock(
                                              boxId: box.id,
                                              quantityLeft:
                                                  box.quantityLeft - 1,
                                            ),
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      '${box.quantityLeft}',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: () => ref
                                        .read(boxRepositoryProvider)
                                        .updateBoxStock(
                                          boxId: box.id,
                                          quantityLeft: box.quantityLeft + 1,
                                        ),
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),

              // Вкладка 2: Мұрағат (Архив — EXPIRED) с перевыставлением в 1 клик
              archiveBoxes.isEmpty
                  ? EmptyState(
                      title: l10n.venueArchiveEmpty,
                      subtitle: l10n.venueQumbekTip,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        108,
                      ),
                      itemCount: archiveBoxes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final box = archiveBoxes[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        box.title,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                    ),
                                    AppBadge(
                                      label: box.status.label(l10n),
                                      tone: AppBadgeTone.neutral,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppFormatters.formatPrice(box.discountPrice)} · ${box.pickupWindow.formatted}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.venueStatsLostProfitSubtitle(
                                    box.quantityLeft,
                                  ),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PrimaryButton(
                                  label: l10n.venueRepublishButton,
                                  icon: Icons.refresh_rounded,
                                  onPressed: () =>
                                      _republishExpiredBox(box, venue),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayMetricCard extends StatelessWidget {
  const _DayMetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
