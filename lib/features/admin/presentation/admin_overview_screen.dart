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
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';

/// Главный экран администратора: KPI без комиссии (0%), очередь модерации и заказы.
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final venues = ref.watch(venuesStreamProvider).valueOrNull ?? const [];
    final users = ref.watch(allUsersProvider);
    final boxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];
    final orders = ref.watch(allPlatformOrdersProvider);
    final pendingVenuesCount = ref.watch(adminPendingVenuesCountProvider);
    final openComplaintsCount = ref.watch(adminOpenComplaintsCountProvider);

    final approvedVenues =
        venues.where((v) => v.status == VenueStatus.approved).length;
    final activeBuyers =
        users.where((u) => u.role == UserRole.buyer).length;
    final activeBoxes = boxes.where((b) => b.isAvailable).length;

    final completedOrders =
        orders.where((o) => o.status == OrderStatus.completed).toList();
    final completedCount =
        completedOrders.fold<int>(0, (sum, o) => sum + o.quantity);
    final gmv = completedOrders.fold<int>(0, (sum, o) => sum + o.totalPrice);
    final venuesMap = {for (final v in venues) v.id: v};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.screenAdminOverviewTitle,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final next = locale.languageCode == 'ru'
                  ? AppLanguage.kk
                  : AppLanguage.ru;
              ref.read(localeProvider.notifier).setLanguage(next);
            },
            child: Text(locale.languageCode == 'ru' ? 'ҚАЗ' : 'РУС'),
          ),
          IconButton(
            tooltip: l10n.actionSwitchToBuyer,
            onPressed: () => ref
                .read(activeAppModeProvider.notifier)
                .setMode(AppMode.buyer),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          IconButton(
            tooltip: l10n.actionLogout,
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              final modeNotifier = ref.read(activeAppModeProvider.notifier);
              final router = GoRouter.of(context);
              await modeNotifier.setMode(AppMode.buyer);
              await authRepo.logout();
              if (!context.mounted) return;
              router.go(AppRoutes.home);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
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
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  avatar: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                  ),
                  label: Text(l10n.actionSwitchToAdmin),
                  selected: true,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(l10n.actionSwitchToVenue),
                  selected: false,
                  onSelected: (_) => ref
                      .read(activeAppModeProvider.notifier)
                      .setMode(AppMode.venue),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(l10n.actionSwitchToBuyer),
                  selected: false,
                  onSelected: (_) => ref
                      .read(activeAppModeProvider.notifier)
                      .setMode(AppMode.buyer),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(l10n.adminZeroCommissionBadge),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Приветственный баннер
            Card(
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const QumbekMascot(size: 64, mood: QumbekMood.happy),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.appName} · ${l10n.cityAstana}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.profileBoxesSaved}: $completedCount · ${AppFormatters.formatWeightKg(completedCount * 0.65, l10n)} · $activeBoxes ${l10n.navBoxes.toLowerCase()}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // KPI-сетка (0% комиссия)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 720 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: columns == 4 ? 1.65 : 1.55,
                  children: [
                    _KpiCard(
                      title: l10n.adminCompletedBoxesLabel,
                      value: '$completedCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                    _KpiCard(
                      title: l10n.adminGmvLabel,
                      value: AppFormatters.formatPrice(gmv),
                      icon: Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    _KpiCard(
                      title: l10n.adminActiveVenuesUsersLabel,
                      value: '$approvedVenues / $activeBuyers',
                      icon: Icons.storefront_rounded,
                      color: AppColors.primaryDark,
                    ),
                    _KpiCard(
                      title: l10n.adminOpenComplaintsLabel,
                      value: '$openComplaintsCount',
                      icon: Icons.report_problem_outlined,
                      color: openComplaintsCount > 0
                          ? AppColors.error
                          : AppColors.success,
                      cardColor: openComplaintsCount > 0
                          ? AppColors.errorLight
                          : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(l10n.adminPendingQueueTitle, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.warningLight,
                      child: Icon(
                        Icons.store_mall_directory_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    title: Text(l10n.screenAdminVenuesTitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBadge(
                          label: '$pendingVenuesCount',
                          tone: pendingVenuesCount > 0
                              ? AppBadgeTone.warning
                              : AppBadgeTone.success,
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.go(AppRoutes.adminVenues),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.errorLight,
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    title: Text(l10n.screenAdminComplaintsTitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBadge(
                          label: '$openComplaintsCount',
                          tone: openComplaintsCount > 0
                              ? AppBadgeTone.error
                              : AppBadgeTone.success,
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.go(AppRoutes.adminComplaints),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(l10n.adminRecentOrdersTitle, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < orders.take(6).length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    () {
                      final order = orders[i];
                      final venue = venuesMap[order.venueId];
                      final isErr = order.status == OrderStatus.cancelledByUser ||
                          order.status == OrderStatus.cancelledByVenue ||
                          order.status == OrderStatus.noShow;
                      return ListTile(
                        title: Text(
                          '${order.orderNumber} · ${venue?.name ?? order.venueId}',
                          style: AppTextStyles.bodyLargeMedium,
                        ),
                        subtitle: Text(
                          '${order.paymentMethod.label(l10n)} · ×${order.quantity}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.formatPrice(order.totalPrice),
                              style: AppTextStyles.bodyLargeMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AppBadge(
                              label: order.status.label(l10n),
                              tone: isErr
                                  ? AppBadgeTone.error
                                  : (order.status.isActive
                                      ? AppBadgeTone.success
                                      : AppBadgeTone.neutral),
                            ),
                          ],
                        ),
                      );
                    }(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.cardColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? cardColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
