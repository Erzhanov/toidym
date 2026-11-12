import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/features/auth/presentation/auth_modal_screen.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/booking_warning_sheet.dart';
import 'package:toidym/shared/widgets/error_state.dart';
import 'package:toidym/shared/widgets/price_tag.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/rating_stars.dart';
import 'package:toidym/shared/widgets/shimmer_box.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Карточка бокса с каруселью фото, описанием, аллергенами и кнопкой бронирования.
class BoxDetailScreen extends ConsumerStatefulWidget {
  const BoxDetailScreen({required this.boxId, super.key});

  final String boxId;

  @override
  ConsumerState<BoxDetailScreen> createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends ConsumerState<BoxDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onReservePressed(Box box) async {
    final l10n = context.l10n;
    var user = ref.read(currentUserProvider);
    if (user == null) {
      final loggedIn = await showAuthBottomSheet(context);
      if (!loggedIn || !mounted) return;
      user = ref.read(currentUserProvider);
      if (user == null || user.role != UserRole.buyer) return;
    }
    if (user.isBanned) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authErrAccountBanned)),
      );
      return;
    }
    if (!mounted) return;
    final accepted = await showOfflineBookingWarningSheet(context);
    if (!accepted || !mounted) return;
    context.push(AppRoutes.checkoutPath(box.id));
  }

  void _showRouteSheet(Venue venue) {
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
                subtitle: Text('https://2gis.kz/astana/geo/${venue.lng},${venue.lat}'),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: 'https://2gis.kz/astana/geo/${venue.lng},${venue.lat}',
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
                  'https://yandex.kz/maps/?pt=${venue.lng},${venue.lat}&z=16',
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

  Future<void> _shareBox(Box box, Venue? venue) async {
    final l10n = context.l10n;
    final text = l10n.boxDetailShareMessage(
      box.title,
      venue?.name ?? l10n.appName,
      AppFormatters.formatPrice(box.discountPrice),
    );
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allBoxesAsync = ref.watch(allBoxesStreamProvider);
    final venuesMap = ref.watch(venuesMapProvider);
    final favorites = ref.watch(favoritesProvider);
    final district = ref.watch(selectedDistrictProvider);

    return allBoxesAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                ShimmerBox(width: double.infinity, height: 240),
                SizedBox(height: AppSpacing.md),
                ShimmerBox(width: double.infinity, height: 28),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(width: double.infinity, height: 120),
              ],
            ),
          ),
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          onRetry: () => ref.invalidate(allBoxesStreamProvider),
        ),
      ),
      data: (boxes) {
        final box = boxes.cast<Box?>().firstWhere(
              (b) => b?.id == widget.boxId,
              orElse: () => null,
            );
        if (box == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              onRetry: () => context.go(AppRoutes.home),
            ),
          );
        }

        final venue = venuesMap[box.venueId];
        final isFavorite = favorites.contains(box.id);
        final photos = box.photos.isNotEmpty
            ? box.photos
            : [if (venue != null && venue.photo.isNotEmpty) venue.photo];
        final distanceKm = venue == null
            ? 1.2
            : AppFormatters.calculateDistanceKm(
                fromLat: district.centerLat,
                fromLng: district.centerLng,
                toLat: venue.lat,
                toLng: venue.lng,
              );
        final isDesktop = MediaQuery.sizeOf(context).width >= 960;
        final isKk = ref.watch(localeProvider).languageCode == 'kk';

        if (isDesktop) {
          final savings =
              (box.originalPrice - box.discountPrice).clamp(0, box.originalPrice);
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
                                          box.title,
                                          style: AppTextStyles.headlineLarge
                                              .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => context.canPop()
                                            ? context.pop()
                                            : context.go(AppRoutes.home),
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
                                      // Левая колонка: фото + описание + аллергены
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  AppRadius.cardBorderRadius,
                                              child: SizedBox(
                                                height: 340,
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    if (photos.isEmpty)
                                                      ToidymFoodImage(
                                                        url: '',
                                                        category: box.category,
                                                      )
                                                    else
                                                      PageView.builder(
                                                        controller:
                                                            _pageController,
                                                        itemCount: photos.length,
                                                        onPageChanged: (idx) =>
                                                            setState(
                                                          () =>
                                                              _currentPage = idx,
                                                        ),
                                                        itemBuilder:
                                                            (context, idx) {
                                                          return ToidymFoodImage(
                                                            url: photos[idx],
                                                            category:
                                                                box.category,
                                                          );
                                                        },
                                                      ),
                                                    Positioned(
                                                      top: 14,
                                                      right: 14,
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundColor:
                                                                AppColors.surface,
                                                            child: IconButton(
                                                              tooltip: l10n
                                                                  .actionShare,
                                                              icon: const Icon(
                                                                Icons
                                                                    .share_outlined,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                              onPressed: () =>
                                                                  _shareBox(
                                                                box,
                                                                venue,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          CircleAvatar(
                                                            backgroundColor:
                                                                AppColors.surface,
                                                            child: IconButton(
                                                              icon: Icon(
                                                                isFavorite
                                                                    ? Icons
                                                                        .favorite_rounded
                                                                    : Icons
                                                                        .favorite_border_rounded,
                                                                color: isFavorite
                                                                    ? AppColors
                                                                        .error
                                                                    : AppColors
                                                                        .primary,
                                                              ),
                                                              onPressed: () {
                                                                HapticFeedback
                                                                    .selectionClick();
                                                                ref
                                                                    .read(
                                                                      favoritesProvider
                                                                          .notifier,
                                                                    )
                                                                    .toggle(
                                                                      box.id,
                                                                    );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(22),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      l10n
                                                          .boxDetailSurpriseTitle,
                                                      style: AppTextStyles
                                                          .titleLarge
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      box.description,
                                                      style: AppTextStyles
                                                          .bodyLarge,
                                                    ),
                                                    const SizedBox(height: 14),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        AppBadge(
                                                          label: box.category
                                                              .label(l10n),
                                                          tone: AppBadgeTone
                                                              .primary,
                                                          large: true,
                                                        ),
                                                        AppBadge(
                                                          label: l10n
                                                              .boxDetailPickupOnlyBadge,
                                                          tone: AppBadgeTone
                                                              .warning,
                                                          large: true,
                                                        ),
                                                        if (box.isHalal)
                                                          AppBadge(
                                                            label:
                                                                l10n.badgeHalal,
                                                            tone: AppBadgeTone
                                                                .halal,
                                                            icon: Icons
                                                                .verified_rounded,
                                                            large: true,
                                                          ),
                                                      ],
                                                    ),
                                                    if (box.type ==
                                                        BoxType.surprise) ...[
                                                      const SizedBox(
                                                        height: 14,
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .accentLight,
                                                          borderRadius: AppRadius
                                                              .inputBorderRadius,
                                                        ),
                                                        child: Text(
                                                          l10n
                                                              .boxDetailSurpriseDisclaimer,
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(22),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      l10n
                                                          .boxDetailAllergensTitle,
                                                      style: AppTextStyles
                                                          .titleLarge
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (box.allergens.isEmpty)
                                                      Text(
                                                        l10n
                                                            .boxDetailAllergensEmpty,
                                                        style: AppTextStyles
                                                            .bodyMedium,
                                                      )
                                                    else
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: [
                                                          for (final a
                                                              in box.allergens)
                                                            Chip(
                                                              label: Text(a),
                                                            ),
                                                        ],
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      l10n
                                                          .boxDetailAllergensNote,
                                                      style:
                                                          AppTextStyles.caption,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Правая колонка: карточка цены + бронь + отзывы (C03)
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
                                                    if (venue != null) ...[
                                                      Text(
                                                        venue.name,
                                                        style: AppTextStyles
                                                            .titleLarge
                                                            .copyWith(
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      RatingStars(
                                                        rating: venue.rating,
                                                        reviewsCount:
                                                            venue.reviewsCount,
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                    ],
                                                    if (box.isHalal) ...[
                                                      AppBadge(
                                                        label: l10n.badgeHalal,
                                                        tone: AppBadgeTone
                                                            .warning,
                                                        icon: Icons
                                                            .verified_rounded,
                                                      ),
                                                      const SizedBox(
                                                        height: 14,
                                                      ),
                                                    ],
                                                    if (venue != null) ...[
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            l10n
                                                                .venueAddressLabel,
                                                            style: AppTextStyles
                                                                .caption,
                                                          ),
                                                          Flexible(
                                                            child: InkWell(
                                                              onTap: () =>
                                                                  _showRouteSheet(
                                                                venue,
                                                              ),
                                                              child: Text(
                                                                '${venue.address} · ${AppFormatters.formatDistance(distanceKm, l10n)}',
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                                style: AppTextStyles
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                  color: AppColors
                                                                      .primary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                    ],
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          l10n.navVenuePickup,
                                                          style: AppTextStyles
                                                              .caption,
                                                        ),
                                                        Text(
                                                          box.pickupWindow
                                                              .formatted,
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          l10n
                                                              .paymentRegularPrice,
                                                          style: AppTextStyles
                                                              .caption,
                                                        ),
                                                        Text(
                                                          AppFormatters
                                                              .formatPrice(
                                                            box.originalPrice,
                                                          ),
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      AppFormatters.formatPrice(
                                                        box.discountPrice,
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
                                                    const SizedBox(height: 8),
                                                    AppBadge(
                                                      label:
                                                          '${AppFormatters.formatDiscount(box.discountPercent)} · −${AppFormatters.formatPrice(savings)}',
                                                      tone:
                                                          AppBadgeTone.warning,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      box.isSoldOut
                                                          ? l10n.badgeSoldOut
                                                          : '${l10n.badgeLeftCount(box.quantityLeft)} · ${l10n.boxDetailPickupOnlyBadge}',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 14),
                                                    PrimaryButton(
                                                      label: box.isSoldOut
                                                          ? l10n.badgeSoldOut
                                                          : l10n
                                                              .actionReserveFor(
                                                              AppFormatters
                                                                  .formatPrice(
                                                                box.discountPrice,
                                                              ),
                                                            ),
                                                      onPressed: box.isSoldOut
                                                          ? null
                                                          : () =>
                                                              _onReservePressed(
                                                                box,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (venue != null) ...[
                                              const SizedBox(height: 16),
                                              _VenueReviewsPreview(
                                                venueId: venue.id,
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
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 270,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surface,
                      child: IconButton(
                        tooltip: l10n.actionShare,
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => _shareBox(box, venue),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, AppSpacing.sm, 6),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surface,
                      child: IconButton(
                        tooltip: isFavorite
                            ? l10n.actionRemoveFromFavorites
                            : l10n.actionAddToFavorites,
                        icon: AnimatedScale(
                          scale: isFavorite ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref.read(favoritesProvider.notifier).toggle(box.id);
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photos.isEmpty)
                        ToidymFoodImage(
                          url: '',
                          category: box.category,
                        )
                      else
                        PageView.builder(
                          controller: _pageController,
                          itemCount: photos.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) {
                            return ToidymFoodImage(
                              url: photos[index],
                              category: box.category,
                            );
                          },
                        ),
                      Positioned(
                        left: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.badgeBorderRadius,
                          ),
                          child: Text(
                            AppFormatters.formatDiscount(box.discountPercent),
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textOnAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (photos.length > 1)
                        Positioned(
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.scrim,
                              borderRadius: AppRadius.badgeBorderRadius,
                            ),
                            child: Text(
                              '${_currentPage + 1}/${photos.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList.list(
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (box.isSoldOut)
                          AppBadge(
                            label: l10n.badgeSoldOut,
                            tone: AppBadgeTone.neutral,
                            large: true,
                          )
                        else
                          AppBadge(
                            label: l10n.badgeLeftCount(box.quantityLeft),
                            tone: box.isEndingSoon
                                ? AppBadgeTone.warning
                                : AppBadgeTone.primary,
                            large: true,
                          ),
                        if (box.isHalal)
                          AppBadge(
                            label: l10n.badgeHalal,
                            tone: AppBadgeTone.halal,
                            icon: Icons.verified_rounded,
                            large: true,
                          ),
                        AppBadge(
                          label: box.category.label(l10n),
                          tone: AppBadgeTone.neutral,
                          large: true,
                        ),
                        AppBadge(
                          label: l10n.boxDetailPickupOnlyBadge,
                          tone: AppBadgeTone.neutral,
                          icon: Icons.storefront_outlined,
                          large: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(box.title, style: AppTextStyles.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    if (venue != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${venue.name} · ${venue.district.label(l10n)}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          RatingStars(
                            rating: venue.rating,
                            reviewsCount: venue.reviewsCount,
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // Карточка самовывоза и маршрута
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    l10n.pickupToday(
                                      box.pickupWindow.formatted,
                                    ),
                                    style: AppTextStyles.bodyLargeMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (venue != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      '${venue.address} · ${AppFormatters.formatDistance(distanceKm, l10n)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showRouteSheet(venue),
                                    icon: const Icon(
                                      Icons.directions_outlined,
                                      size: 18,
                                    ),
                                    label: Text(l10n.actionRoute),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Что обычно внутри + пояснение сюрприз-бокса
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.boxDetailSurpriseTitle,
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              box.description,
                              style: AppTextStyles.bodyLarge,
                            ),
                            if (box.type == BoxType.surprise) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.inputBorderRadius,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        l10n.boxDetailSurpriseDisclaimer,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Аллергены
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.boxDetailAllergensTitle,
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            if (box.allergens.isEmpty)
                              Text(
                                l10n.boxDetailAllergensEmpty,
                                style: AppTextStyles.bodyMedium,
                              )
                            else
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  for (final allergen in box.allergens)
                                    Chip(label: Text(allergen)),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.boxDetailAllergensNote,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (venue != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _VenueReviewsPreview(venueId: venue.id),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  PriceTag(
                    originalPrice: box.originalPrice,
                    discountPrice: box.discountPrice,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: box.isSoldOut
                          ? l10n.badgeSoldOut
                          : l10n.actionReserveFor(
                              AppFormatters.formatPrice(box.discountPrice),
                            ),
                      onPressed:
                          box.isSoldOut ? null : () => _onReservePressed(box),
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

class _VenueReviewsPreview extends ConsumerWidget {
  const _VenueReviewsPreview({required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return FutureBuilder<List<Review>>(
      future: ref.read(venueRepositoryProvider).getVenueReviews(venueId),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const [];
        if (reviews.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.boxDetailReviewsTitle,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final review in reviews.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.authorName,
                              style: AppTextStyles.bodyLargeMedium,
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.accentDark,
                                ),
                                const SizedBox(width: 2),
                                Text('${review.rating}'),
                              ],
                            ),
                          ],
                        ),
                        if (review.comment.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            review.comment,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
