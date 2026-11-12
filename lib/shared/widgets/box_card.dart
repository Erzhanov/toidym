import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

/// Вертикальная / широкая карточка бокса в стиле Figma U01/C01/09.
class BoxCard extends StatelessWidget {
  const BoxCard({
    required this.box,
    required this.venue,
    required this.distanceKm,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
    this.compact = false,
    this.dietaryMismatch = false,
  });

  final Box box;
  final Venue? venue;
  final double distanceKm;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool compact;
  final bool dietaryMismatch;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return BoxTallCard(
        box: box,
        venue: venue,
        distanceKm: distanceKm,
        isFavorite: isFavorite,
        onTap: onTap,
        onToggleFavorite: onToggleFavorite,
        dietaryMismatch: dietaryMismatch,
      );
    }

    return BoxHorizontalCard(
      box: box,
      venue: venue,
      distanceKm: distanceKm,
      isFavorite: isFavorite,
      onTap: onTap,
      onToggleFavorite: onToggleFavorite,
      dietaryMismatch: dietaryMismatch,
    );
  }
}

/// Узкая вертикальная карточка «Забрать сейчас» (Figma Box Card Tall: 240px, p8, r22).
class BoxTallCard extends StatelessWidget {
  const BoxTallCard({
    required this.box,
    required this.venue,
    required this.distanceKm,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
    this.dietaryMismatch = false,
  });

  final Box box;
  final Venue? venue;
  final double distanceKm;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool dietaryMismatch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isKk = Localizations.localeOf(context).languageCode == 'kk';
    final photoUrl = box.photos.isNotEmpty ? box.photos.first : '';
    final isApproved = venue == null || venue!.status == VenueStatus.approved;
    final leftLabel = isKk
        ? 'қалды ${box.quantityLeft}'
        : 'осталось ${box.quantityLeft}';

    return Opacity(
      opacity: dietaryMismatch ? 0.62 : 1.0,
      child: ToidymCard(
        borderRadius: 22,
        padding: const EdgeInsets.all(8),
        border: !isApproved
            ? Border.all(color: AppColors.error, width: 2)
            : null,
        onTap: onTap,
        child: SizedBox(
          width: 224,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: ToidymCutoutArtwork(
                      category: box.category,
                      imageUrl: photoUrl,
                      size: 112,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _HeartButton(
                      isFavorite: isFavorite,
                      onToggle: onToggleFavorite,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: box.isResale
                        ? _PulsingResaleBadge(
                            label: isKk ? 'Шұғыл' : 'Срочно',
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              leftLabel,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue?.name ?? box.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${box.pickupWindow.formatted} · ${AppFormatters.formatDistance(distanceKm, l10n)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            AppFormatters.formatPrice(box.discountPrice),
                            style: AppTextStyles.priceNew,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.formatPrice(box.originalPrice),
                            style: AppTextStyles.priceOld,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Горизонтальная карточка предложения (Figma Box offer: p12, r22, плитка 96×96).
class BoxHorizontalCard extends StatelessWidget {
  const BoxHorizontalCard({
    required this.box,
    required this.venue,
    required this.distanceKm,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
    this.dietaryMismatch = false,
  });

  final Box box;
  final Venue? venue;
  final double distanceKm;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool dietaryMismatch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isKk = Localizations.localeOf(context).languageCode == 'kk';
    final photoUrl = box.photos.isNotEmpty ? box.photos.first : '';
    final isApproved = venue == null || venue!.status == VenueStatus.approved;
    final ratingText = venue != null
        ? ' · ★ ${venue!.rating.toStringAsFixed(1).replaceAll('.', ',')}'
        : '';
    final leftText = isKk
        ? 'қалды ${box.quantityLeft}'
        : 'осталось ${box.quantityLeft}';

    return Opacity(
      opacity: dietaryMismatch ? 0.62 : 1.0,
      child: ToidymCard(
        borderRadius: 22,
        padding: const EdgeInsets.all(12),
        border: !isApproved
            ? Border.all(color: AppColors.error, width: 2)
            : null,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: ToidymCutoutArtwork(
                    category: box.category,
                    imageUrl: photoUrl,
                    size: 86,
                  ),
                ),
                if (box.isResale)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _PulsingResaleBadge(
                      label: isKk ? 'Шұғыл' : 'Срочно',
                    ),
                  )
                else if (box.isHalal)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.badgeHalal,
                        style: AppTextStyles.captionSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue?.name ?? box.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _HeartButton(
                        isFavorite: isFavorite,
                        onToggle: onToggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    box.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${box.pickupWindow.formatted} · ${AppFormatters.formatDistance(distanceKm, l10n)}$ratingText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppFormatters.formatPrice(box.discountPrice),
                                style: AppTextStyles.priceNew.copyWith(
                                  color: box.isResale
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppFormatters.formatPrice(box.originalPrice),
                                style: AppTextStyles.priceOld,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          leftText,
                          style: AppTextStyles.captionSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
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

class _HeartButton extends StatelessWidget {
  const _HeartButton({
    required this.isFavorite,
    required this.onToggle,
  });

  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      toggled: isFavorite,
      label: isFavorite
          ? l10n.actionRemoveFromFavorites
          : l10n.actionAddToFavorites,
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onToggle();
        },
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 22,
            color: isFavorite ? AppColors.error : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _PulsingResaleBadge extends StatefulWidget {
  const _PulsingResaleBadge({required this.label});

  final String label;

  @override
  State<_PulsingResaleBadge> createState() => _PulsingResaleBadgeState();
}

class _PulsingResaleBadgeState extends State<_PulsingResaleBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.78, end: 1.0).animate(_controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.label,
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.textOnPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
