import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/box_card.dart';
import 'package:toidym/shared/widgets/complaint_bottom_sheet.dart';
import 'package:toidym/shared/widgets/error_state.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/shimmer_box.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Экран активного заказа с QR-кодом, 4-значным кодом, таймером и автопереходом к «Ас болсын!».
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  late Timer _ticker;
  DateTime _now = DateTime.now();
  bool _navigatedToSuccess = false;
  bool _sprintExpireTriggered = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _confirmCancel(Order order) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.orderCancelConfirmTitle),
        content: Text(l10n.orderCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.orderCancelButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrderByBuyer(order.id);
      if (!mounted) return;
      context.go(AppRoutes.orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _triggerSprintTimeout(Order order) async {
    if (_sprintExpireTriggered || !mounted) return;
    _sprintExpireTriggered = true;
    final l10n = context.l10n;
    final cron = ref.read(resaleCronProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);
    await cron.expireOrderSprint(order.id, _now);
    if (!mounted) return;
    setState(() => _isBusy = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.fcmStrikeBody)));
  }

  Duration _sprintRemaining(Order order, Box? box) {
    if (box == null) return Duration.zero;
    if (box.isResale) {
      final diff = box.pickupWindow.end.difference(_now);
      return diff.isNegative ? Duration.zero : diff;
    }
    final useWindowEnd = !_now.isBefore(box.pickupWindow.start) &&
        box.pickupWindow.duration.inMinutes <=
            BusinessRulesConfig.sprintWindowMinutes;
    final deadline = useWindowEnd
        ? box.pickupWindow.end
        : order.createdAt.add(
            const Duration(minutes: BusinessRulesConfig.sprintWindowMinutes),
          );
    final diff = deadline.difference(_now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatMmSs(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _showRouteChoiceDialog(Venue venue) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.orderRouteChooseMap, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(venue.address, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: AppColors.primary),
                title: Text(l10n.orderOpen2Gis),
                subtitle: Text('2gis.kz/astana/geo/${venue.lng},${venue.lat}'),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'https://2gis.kz/astana/geo/${venue.lng},${venue.lat}',
                    ),
                  );
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.boxDetailRouteOpening(
                          venue.address,
                          venue.lat.toStringAsFixed(4),
                          venue.lng.toStringAsFixed(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.navigation_rounded,
                  color: AppColors.warning,
                ),
                title: Text(l10n.orderOpenYandexMaps),
                subtitle: Text(
                  'yandex.kz/maps/?pt=${venue.lng},${venue.lat}&z=16',
                ),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'https://yandex.kz/maps/?pt=${venue.lng},${venue.lat}&z=16',
                    ),
                  );
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.boxDetailRouteOpening(
                          venue.address,
                          venue.lat.toStringAsFixed(4),
                          venue.lng.toStringAsFixed(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isUrgentRed(Order order, Box? box) {
    if (box == null) return false;
    final remaining = _sprintRemaining(order, box);
    return remaining.inMinutes <= 10;
  }

  String _countdownLabel(Order order, Box? box) {
    final l10n = context.l10n;
    if (box == null) return '';
    final remaining = _sprintRemaining(order, box);
    if (remaining <= Duration.zero) {
      return l10n.orderCountdownEnded;
    }
    if (!box.isResale) {
      return l10n.orderSprintTimerLabel(_formatMmSs(remaining));
    }
    if (remaining.inMinutes <= 10) {
      return l10n.orderUrgentClosing(
        AppFormatters.formatRemainingDuration(remaining, l10n),
      );
    }
    return l10n.orderCountdownDuring(
      AppFormatters.formatRemainingDuration(remaining, l10n),
    );
  }

  String? _reminderBannerText(Box? box) {
    final l10n = context.l10n;
    if (box == null) return null;
    if (_now.isBefore(box.pickupWindow.start)) {
      final minsToStart = box.pickupWindow.start.difference(_now).inMinutes;
      if (minsToStart <= 30) {
        return l10n.orderReminder30m;
      }
    } else if (_now.isBefore(box.pickupWindow.end)) {
      final minsToEnd = box.pickupWindow.end.difference(_now).inMinutes;
      if (minsToEnd <= 15) {
        return l10n.orderReminder15m;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ordersAsync = ref.watch(ordersStreamProvider);
    final boxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];
    final venuesMap = ref.watch(venuesMapProvider);

    // Автопереход к экрану «Ас болсын!», когда заведение выдаёт заказ
    ref.listen<AsyncValue<List<Order>>>(ordersStreamProvider, (_, next) {
      final list = next.valueOrNull ?? const [];
      final current = list.cast<Order?>().firstWhere(
            (o) => o?.id == widget.orderId,
            orElse: () => null,
          );
      if (current != null &&
          current.status == OrderStatus.completed &&
          !_navigatedToSuccess &&
          mounted) {
        _navigatedToSuccess = true;
        HapticFeedback.heavyImpact();
        context.go(AppRoutes.successPath(current.id));
      }
    });

    return ordersAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: BoxCardSkeleton(),
          ),
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(onRetry: () => ref.invalidate(ordersStreamProvider)),
      ),
      data: (orders) {
        final order = orders.cast<Order?>().firstWhere(
              (o) => o?.id == widget.orderId,
              orElse: () => null,
            );
        if (order == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(onRetry: () => context.go(AppRoutes.orders)),
          );
        }

        if (order.status == OrderStatus.noShow) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.orderTitle(order.orderNumber))),
            body: ErrorState(
              title: l10n.orderResaleErrorMessage,
              subtitle: l10n.fcmStrikeBody,
              onRetry: () => context.go(AppRoutes.home),
            ),
          );
        }

        final box = boxes.cast<Box?>().firstWhere(
              (b) => b?.id == order.boxId,
              orElse: () => null,
            );
        if (order.status == OrderStatus.reserved &&
            box != null &&
            _sprintRemaining(order, box) <= Duration.zero &&
            !_sprintExpireTriggered) {
          unawaited(Future.microtask(() => _triggerSprintTimeout(order)));
        }
        final venue = venuesMap[order.venueId];
        final canCancel = box != null &&
            BoxBusinessRules.canBuyerCancelOrder(
              order: order,
              box: box,
              now: _now,
            );
        final isDesktop = MediaQuery.sizeOf(context).width >= 960;
        final isKk = ref.watch(localeProvider).languageCode == 'kk';

        if (isDesktop) {
          final district = ref.watch(selectedDistrictProvider);
          final favorites = ref.watch(favoritesProvider);
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
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
                                          l10n.orderTitle(order.orderNumber),
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
                                      // Левая колонка C05: статус + QR + PIN
                                      SizedBox(
                                        width: 360,
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              children: [
                                                AppBadge(
                                                  label: order.status
                                                      .label(l10n),
                                                  tone: !order.status.isActive &&
                                                          order.status !=
                                                              OrderStatus
                                                                  .completed
                                                      ? AppBadgeTone.error
                                                      : AppBadgeTone.halal,
                                                  large: true,
                                                ),
                                                const SizedBox(height: 18),
                                                RepaintBoundary(
                                                  child: QrImageView(
                                                    data: order.qrCode,
                                                    size: 200,
                                                    eyeStyle: const QrEyeStyle(
                                                      eyeShape: QrEyeShape.square,
                                                      color: AppColors.primary,
                                                    ),
                                                    dataModuleStyle:
                                                        const QrDataModuleStyle(
                                                      dataModuleShape:
                                                          QrDataModuleShape
                                                              .square,
                                                      color: AppColors.primary,
                                                    ),
                                                    backgroundColor:
                                                        AppColors.surface,
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  order.formattedPin,
                                                  style: AppTextStyles
                                                      .displayLarge
                                                      .copyWith(
                                                    color: AppColors.primary,
                                                    letterSpacing: 6,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  l10n.orderShowQrHint,
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                                const SizedBox(height: 16),
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.accentLight,
                                                    borderRadius: AppRadius
                                                        .inputBorderRadius,
                                                  ),
                                                  child: Text(
                                                    '${l10n.paymentOnSite} · ${AppFormatters.formatPrice(order.totalPrice)}',
                                                    textAlign: TextAlign.center,
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Правая колонка C05: детали заказа + маршрут/звонок + отмена
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(22),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${order.orderNumber} · ${venue?.name ?? ''}',
                                                      style: AppTextStyles
                                                          .titleLarge
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    if (box != null) ...[
                                                      const SizedBox(
                                                        height: 14,
                                                      ),
                                                      BoxHorizontalCard(
                                                        box: box,
                                                        venue: venue,
                                                        distanceKm: venue == null
                                                            ? 1.2
                                                            : AppFormatters
                                                                .calculateDistanceKm(
                                                                fromLat: district
                                                                    .centerLat,
                                                                fromLng: district
                                                                    .centerLng,
                                                                toLat: venue.lat,
                                                                toLng: venue.lng,
                                                              ),
                                                        isFavorite: favorites
                                                            .contains(box.id),
                                                        onTap: () =>
                                                            context.push(
                                                          AppRoutes
                                                              .boxDetailPath(
                                                            box.id,
                                                          ),
                                                        ),
                                                        onToggleFavorite: () =>
                                                            ref
                                                                .read(
                                                                  favoritesProvider
                                                                      .notifier,
                                                                )
                                                                .toggle(box.id),
                                                      ),
                                                      const SizedBox(
                                                        height: 14,
                                                      ),
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(14),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _isUrgentRed(
                                                            order,
                                                            box,
                                                          )
                                                              ? AppColors
                                                                  .errorLight
                                                              : AppColors
                                                                  .primaryLight,
                                                          borderRadius: AppRadius
                                                              .inputBorderRadius,
                                                        ),
                                                        child: Text(
                                                          _countdownLabel(
                                                            order,
                                                            box,
                                                          ),
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                            color: _isUrgentRed(
                                                              order,
                                                              box,
                                                            )
                                                                ? AppColors
                                                                    .errorText
                                                                : AppColors
                                                                    .primary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    if (venue != null) ...[
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: PrimaryButton(
                                                              label: l10n
                                                                  .actionRoute,
                                                              icon: Icons
                                                                  .directions_outlined,
                                                              onPressed: () =>
                                                                  _showRouteChoiceDialog(
                                                                venue,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                PrimaryButton(
                                                              label: l10n
                                                                  .actionCall,
                                                              icon: Icons
                                                                  .call_outlined,
                                                              onPressed: () =>
                                                                  _showCallDialog(
                                                                venue,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (order.status.isActive) ...[
                                              const SizedBox(height: 16),
                                              Card(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(22),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      SecondaryButton(
                                                        label: l10n
                                                            .orderCancelButton,
                                                        onPressed: _isBusy ||
                                                                !canCancel
                                                            ? null
                                                            : () =>
                                                                _confirmCancel(
                                                                  order,
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
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
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primary,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: context.canPop()
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Center(
                      child: Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.pop(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            title: Text(
              l10n.orderTitle(order.orderNumber),
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.primary,
                fontSize: 22,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: AppBadge(
                  label: order.status.label(l10n),
                  tone: !order.status.isActive &&
                          order.status != OrderStatus.completed
                      ? AppBadgeTone.error
                      : AppBadgeTone.accent,
                  large: true,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // QR-код и 4-значный PIN
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.cardBorderRadius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: RepaintBoundary(
                            child: QrImageView(
                              data: order.qrCode,
                              size: 200,
                              backgroundColor: AppColors.surface,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.orderPinLabel, style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          order.formattedPin,
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.orderShowQrHint,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppBadge(
                          label:
                              '${l10n.paymentOnSite} · ${AppFormatters.formatPrice(order.totalPrice)}',
                          tone: AppBadgeTone.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Обратный отсчёт (краснеет <= 10 мин до конца) и напоминание 15/30 мин
                if (box != null) ...[
                  Builder(
                    builder: (context) {
                      final isRed = _isUrgentRed(order, box);
                      final reminder = _reminderBannerText(box);
                      return Card(
                        color: isRed ? AppColors.errorLight : null,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isRed
                                        ? AppColors.error.withValues(alpha: 0.16)
                                        : AppColors.accentLight,
                                    child: Icon(
                                      Icons.timer_outlined,
                                      color: isRed
                                          ? AppColors.error
                                          : AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _countdownLabel(order, box),
                                          style:
                                              AppTextStyles.titleMedium.copyWith(
                                            color: isRed
                                                ? AppColors.errorText
                                                : AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          l10n.pickupToday(
                                            box.pickupWindow.formatted,
                                          ),
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (reminder != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRed
                                        ? AppColors.surface
                                        : AppColors.warningLight,
                                    borderRadius: AppRadius.badgeBorderRadius,
                                  ),
                                  child: Text(
                                    reminder,
                                    style: AppTextStyles.caption.copyWith(
                                      color: isRed
                                          ? AppColors.errorText
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Адрес, Маршрут, Позвонить
                if (venue != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(venue.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${venue.address} · ${venue.district.label(l10n)}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showRouteChoiceDialog(venue),
                                  icon: const Icon(Icons.directions_outlined),
                                  label: Text(l10n.actionRoute),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCallDialog(venue),
                                  icon: const Icon(Icons.call_outlined),
                                  label: Text(l10n.actionCall),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),

                if (order.status.isActive) ...[
                  OutlinedButton(
                    onPressed: _isBusy || !canCancel
                        ? null
                        : () => _confirmCancel(order),
                    child: Text(l10n.orderCancelButton),
                  ),
                  if (!canCancel) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.orderCancelBlockedHint,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                ],

                TextButton.icon(
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
                                content: Text(l10n.complaintSubmittedToast),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(
                    order.complaintSubmitted
                        ? l10n.complaintAlreadySent
                        : l10n.orderProblemButton,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCallDialog(Venue venue) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.orderCallDialogTitle),
        content: Text(l10n.orderCallDialogBody(venue.phone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionDone),
          ),
        ],
      ),
    );
  }
}
