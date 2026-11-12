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
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/features/auth/presentation/auth_modal_screen.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/complaint_bottom_sheet.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Экран заказов покупателя с табами «Активные / Прошедшие».
class OrdersHistoryScreen extends ConsumerWidget {
  const OrdersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: isDesktop ? null : AppBar(title: Text(l10n.screenOrdersHistoryTitle)),
        body: Column(
          children: [
            if (isDesktop) const ToidymBuyerWebHeader(),
            Expanded(
              child: EmptyState(
                title: l10n.guestBenefitsTitle,
                subtitle: l10n.guestBenefitOrders,
                actionLabel: l10n.actionLogin,
                onAction: () => showAuthBottomSheet(context),
              ),
            ),
          ],
        ),
      );
    }

    final orders = ref.watch(buyerOrdersProvider);
    final activeOrders =
        orders.where((o) => o.status.isActive).toList(growable: false);
    final pastOrders =
        orders.where((o) => !o.status.isActive).toList(growable: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            if (isDesktop) ...[
              const ToidymBuyerWebHeader(),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.screenOrdersHistoryTitle,
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: AppRadius.badgeBorderRadius,
                          ),
                          child: TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadius.badgeBorderRadius,
                            ),
                            labelColor: AppColors.textOnPrimary,
                            unselectedLabelColor: AppColors.primary,
                            labelStyle: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: [
                              Tab(
                                height: 36,
                                text:
                                    '${l10n.ordersTabActive} (${activeOrders.length})',
                              ),
                              Tab(
                                height: 36,
                                text:
                                    '${l10n.ordersTabPast} (${pastOrders.length})',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ToidymDarkHeader(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.sheet),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 14,
                  16,
                  20,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.screenOrdersHistoryTitle,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
                  splashBorderRadius: BorderRadius.circular(AppRadius.chip),
                  labelColor: AppColors.background,
                  unselectedLabelColor: AppColors.primary,
                  labelStyle: AppTextStyles.label14,
                  unselectedLabelStyle: AppTextStyles.label14,
                  tabs: [
                    Tab(
                      height: 44,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          '${l10n.ordersTabActive} · ${activeOrders.length}',
                        ),
                      ),
                    ),
                    Tab(
                      height: 44,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          '${l10n.ordersTabPast} · ${pastOrders.length}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: TabBarView(
                    children: [
                      _OrdersList(
                        orders: activeOrders,
                        emptyTitle: l10n.ordersEmptyActiveTitle,
                        emptySubtitle: l10n.ordersEmptyActiveSubtitle,
                        showBrowseCta: true,
                      ),
                      _OrdersList(
                        orders: pastOrders,
                        emptyTitle: l10n.ordersEmptyPastTitle,
                        emptySubtitle: l10n.ordersEmptyPastSubtitle,
                        showBrowseCta: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.showBrowseCta,
  });

  final List<Order> orders;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showBrowseCta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (orders.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: showBrowseCta ? l10n.navBoxes : null,
        onAction: showBrowseCta ? () => context.go(AppRoutes.home) : null,
      );
    }

    final boxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];
    final venuesMap = ref.watch(venuesMapProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        108,
      ),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final order = orders[index];
        final box = boxes.cast<Box?>().firstWhere(
              (b) => b?.id == order.boxId,
              orElse: () => null,
            );
        final venue = venuesMap[order.venueId];

        final tone = switch (order.status) {
          OrderStatus.reserved => AppBadgeTone.success,
          OrderStatus.completed => AppBadgeTone.primary,
          OrderStatus.cancelledByUser ||
          OrderStatus.cancelledByVenue ||
          OrderStatus.noShow =>
            AppBadgeTone.error,
        };

        final canComplain = BoxBusinessRules.canSubmitComplaint(order: order);

        return Card(
          child: InkWell(
            borderRadius: AppRadius.cardBorderRadius,
            onTap: order.status.isActive
                ? () => context.push(AppRoutes.orderPath(order.id))
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.orderTitle(order.orderNumber),
                        style: AppTextStyles.titleMedium,
                      ),
                      AppBadge(label: order.status.label(l10n), tone: tone),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    order.isCharityBox
                        ? l10n.profileCharityTitle
                        : (box?.title ?? ''),
                    style: AppTextStyles.bodyLargeMedium,
                  ),
                  if (venue != null)
                    Text(
                      '${venue.name} · ${venue.address}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  if (order.cancellationReason != null &&
                      order.cancellationReason!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      order.cancellationReason!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.errorText,
                      ),
                    ),
                  ],
                  if (order.complaintSubmitted) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        AppBadge(
                          label: order.complaintStatus.label(l10n),
                          tone: order.complaintStatus.isOpen
                              ? AppBadgeTone.warning
                              : AppBadgeTone.success,
                        ),
                      ],
                    ),
                    if (order.complaintResolutionNote != null &&
                        order.complaintResolutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        order.complaintResolutionNote!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successText,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        box != null
                            ? '${box.pickupWindow.formatted} · ×${order.quantity}'
                            : '×${order.quantity}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        AppFormatters.formatPrice(order.totalPrice),
                        style: AppTextStyles.priceNew.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  if (order.status.isActive) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PIN: ${order.formattedPin}',
                          style: AppTextStyles.bodyLargeMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.orderPath(order.id)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primary,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: Text(l10n.ordersOpenQr),
                        ),
                      ],
                    ),
                  ] else if (canComplain || order.complaintSubmitted) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: order.complaintSubmitted
                            ? null
                            : () async {
                                final sent = await showComplaintBottomSheet(
                                  context,
                                  order: order,
                                );
                                if (sent && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.complaintSubmittedToast,
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(
                          Icons.report_problem_outlined,
                          size: 18,
                        ),
                        label: Text(
                          order.complaintSubmitted
                              ? l10n.complaintAlreadySent
                              : l10n.orderProblemButton,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
