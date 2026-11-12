import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:toidym/shared/widgets/box_card.dart';
import 'package:toidym/shared/widgets/error_state.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/shimmer_box.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Экран подтверждения доверительного бронирования (оплата только при получении).
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.boxId, super.key});

  final String boxId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _quantity = 1;
  bool _isReserving = false;
  String? _reservationError;

  Future<void> _confirmReservation(Box box) async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(AppRoutes.authWithNext(AppRoutes.checkoutPath(box.id)));
      return;
    }
    if (user.isBanned) {
      setState(() => _reservationError = l10n.authErrAccountBanned);
      return;
    }

    final totalPrice = box.discountPrice * _quantity;
    final originalTotal = box.originalPrice * _quantity;
    final orderRepo = ref.read(orderRepositoryProvider);

    setState(() {
      _isReserving = true;
      _reservationError = null;
    });

    try {
      final order = await orderRepo.createReservation(
        userId: user.id,
        boxId: box.id,
        venueId: box.venueId,
        quantity: _quantity,
        totalPrice: totalPrice,
        originalTotalPrice: originalTotal,
      );

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.go(AppRoutes.orderPath(order.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isReserving = false;
        _reservationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final boxesAsync = ref.watch(allBoxesStreamProvider);
    final venuesMap = ref.watch(venuesMapProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenReserveTitle)),
      body: boxesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: BoxCardSkeleton(),
        ),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(allBoxesStreamProvider),
        ),
        data: (boxes) {
          final box = boxes.cast<Box?>().firstWhere(
                (b) => b?.id == widget.boxId,
                orElse: () => null,
              );
          if (box == null) {
            return ErrorState(onRetry: () => context.go(AppRoutes.home));
          }

          final maxQty = box.quantityLeft.clamp(1, 99);
          final safeQty = _quantity.clamp(1, maxQty);
          if (safeQty != _quantity) {
            _quantity = safeQty;
          }

          final venue = venuesMap[box.venueId];
          final regularTotal = box.originalPrice * safeQty;
          final finalTotal = box.discountPrice * safeQty;
          final savedTotal = regularTotal - finalTotal;
          final isDesktop = MediaQuery.sizeOf(context).width >= 960;
          final isKk = ref.watch(localeProvider).languageCode == 'kk';

          if (isDesktop) {
            final district = ref.watch(selectedDistrictProvider);
            final favorites = ref.watch(favoritesProvider);
            final distKm = venue == null
                ? 1.2
                : AppFormatters.calculateDistanceKm(
                    fromLat: district.centerLat,
                    fromLng: district.centerLng,
                    toLat: venue.lat,
                    toLng: venue.lng,
                  );
            return Column(
              children: [
                const ToidymBuyerWebHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                24,
                                28,
                                32,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.screenReserveTitle,
                                          style: AppTextStyles.headlineLarge
                                              .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            context.go(AppRoutes.home),
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          size: 18,
                                        ),
                                        label: Text(l10n.navBoxes),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            BoxHorizontalCard(
                                              box: box,
                                              venue: venue,
                                              distanceKm: distKm,
                                              isFavorite:
                                                  favorites.contains(box.id),
                                              onTap: () {},
                                              onToggleFavorite: () => ref
                                                  .read(
                                                    favoritesProvider.notifier,
                                                  )
                                                  .toggle(box.id),
                                            ),
                                            const SizedBox(height: 16),
                                            Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      l10n.paymentQuantityLabel,
                                                      style: AppTextStyles
                                                          .titleLarge
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            l10n.pickupToday(
                                                              box.pickupWindow
                                                                  .formatted,
                                                            ),
                                                            style: AppTextStyles
                                                                .bodyMedium,
                                                          ),
                                                        ),
                                                        IconButton.filledTonal(
                                                          onPressed:
                                                              _isReserving ||
                                                                      safeQty <=
                                                                          1
                                                                  ? null
                                                                  : () => setState(
                                                                        () => _quantity =
                                                                            safeQty -
                                                                                1,
                                                                      ),
                                                          icon: const Icon(
                                                            Icons
                                                                .remove_rounded,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 14,
                                                          ),
                                                          child: Text(
                                                            '$safeQty',
                                                            style: AppTextStyles
                                                                .titleLarge,
                                                          ),
                                                        ),
                                                        IconButton.filledTonal(
                                                          onPressed:
                                                              _isReserving ||
                                                                      safeQty >=
                                                                          maxQty
                                                                  ? null
                                                                  : () => setState(
                                                                        () => _quantity =
                                                                            safeQty +
                                                                                1,
                                                                      ),
                                                          icon: const Icon(
                                                            Icons.add_rounded,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Card(
                                              color: AppColors.surface,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.payments_outlined,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            l10n.paymentOnSite,
                                                            style: AppTextStyles
                                                                .titleMedium
                                                                .copyWith(
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            l10n
                                                                .paymentOfflineBadge,
                                                            style: AppTextStyles
                                                                .caption,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 380,
                                        child: Column(
                                          children: [
                                            Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(22),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _SummaryRow(
                                                      label: l10n
                                                          .paymentRegularPrice,
                                                      value: AppFormatters
                                                          .formatPrice(
                                                        regularTotal,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _SummaryRow(
                                                      label:
                                                          l10n.paymentYouSave,
                                                      value: AppFormatters
                                                          .formatPrice(
                                                        savedTotal,
                                                      ),
                                                      valueColor:
                                                          AppColors.successText,
                                                    ),
                                                    const SizedBox(height: 14),
                                                    Text(
                                                      AppFormatters.formatPrice(
                                                        finalTotal,
                                                      ),
                                                      style: AppTextStyles
                                                          .displayLarge
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    if (_reservationError !=
                                                        null) ...[
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .errorLight,
                                                          borderRadius: AppRadius
                                                              .inputBorderRadius,
                                                        ),
                                                        child: Text(
                                                          _reservationError!,
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                            color: AppColors
                                                                .errorText,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                    ],
                                                    PrimaryButton(
                                                      label: _isReserving
                                                          ? l10n
                                                              .paymentProcessing
                                                          : l10n
                                                              .actionConfirmReserve(
                                                              AppFormatters
                                                                  .formatPrice(
                                                                finalTotal,
                                                              ),
                                                            ),
                                                      isLoading: _isReserving,
                                                      onPressed: box.isSoldOut
                                                          ? null
                                                          : () =>
                                                              _confirmReservation(
                                                                box,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(18),
                                                child: Text(
                                                  '• ${l10n.paymentRuleRefund}\n• ${l10n.paymentRuleCharity}',
                                                  style: AppTextStyles.caption,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ToidymWebFooter(isKk: isKk),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Информация о боксе
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (venue != null)
                                Text(
                                  venue.name,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              const SizedBox(height: 2),
                              Text(box.title, style: AppTextStyles.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.pickupToday(box.pickupWindow.formatted),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Количество − / +
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.paymentQuantityLabel,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    Text(
                                      l10n.badgeLeftCount(box.quantityLeft),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: _isReserving || safeQty <= 1
                                    ? null
                                    : () =>
                                        setState(() => _quantity = safeQty - 1),
                                constraints: const BoxConstraints(
                                  minWidth: AppSpacing.minTouchTarget,
                                  minHeight: AppSpacing.minTouchTarget,
                                ),
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text(
                                  '$safeQty',
                                  style: AppTextStyles.titleLarge,
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: _isReserving || safeQty >= maxQty
                                    ? null
                                    : () =>
                                        setState(() => _quantity = safeQty + 1),
                                constraints: const BoxConstraints(
                                  minWidth: AppSpacing.minTouchTarget,
                                  minHeight: AppSpacing.minTouchTarget,
                                ),
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Карточка офлайн-оплаты на месте
                      Card(
                        color: AppColors.primaryLight.withValues(alpha: 0.35),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.paymentOnSite,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.primaryDark,
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Расчёт стоимости
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              _SummaryRow(
                                label: l10n.paymentRegularPrice,
                                value: AppFormatters.formatPrice(regularTotal),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _SummaryRow(
                                label: l10n.paymentYouSave,
                                value: AppFormatters.formatPrice(savedTotal),
                                valueColor: AppColors.successText,
                              ),
                              const Divider(height: AppSpacing.lg),
                              _SummaryRow(
                                label: l10n.paymentTotal,
                                value: AppFormatters.formatPrice(finalTotal),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${l10n.profileStrikesCount(user.strikesCount)} · ${l10n.paymentRuleStrike}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      if (_reservationError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: AppRadius.inputBorderRadius,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  _reservationError!,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.errorText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        '• ${l10n.paymentRuleRefund}\n• ${l10n.paymentRuleCharity}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: PrimaryButton(
                    label: _isReserving
                        ? l10n.paymentProcessing
                        : l10n.actionConfirmReserve(
                            AppFormatters.formatPrice(finalTotal),
                          ),
                    isLoading: _isReserving,
                    onPressed: box.isSoldOut
                        ? null
                        : () => _confirmReservation(box),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyLarge,
        ),
        Text(
          value,
          style: (isBold ? AppTextStyles.titleLarge : AppTextStyles.bodyLargeMedium)
              .copyWith(color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
