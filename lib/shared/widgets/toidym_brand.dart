import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/shared/models/enums.dart';

/// Логотип бренда toıdym из Design Toidym.svg.
class ToidymLogo extends StatelessWidget {
  const ToidymLogo({
    super.key,
    this.height = 34,
    this.darkText = false,
  });

  final double height;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      darkText ? 'assets/images/logo_indigo.png' : 'assets/images/logo_yellow.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, _) => Text(
        'toıdym',
        style: AppTextStyles.titleLarge.copyWith(
          color: darkText ? AppColors.primary : AppColors.accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Тёмная скруглённая сверху шапка бренда (#2B2350), как в макете Design Toidym.svg.
class ToidymDarkHeader extends StatelessWidget {
  const ToidymDarkHeader({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.md,
    ),
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(28),
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: borderRadius,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Фото бокса/заведения с локальными иллюстрациями из Design Toidym.svg в качестве
/// мгновенного фолбэка или при `asset:`-путях.
class ToidymFoodImage extends StatelessWidget {
  const ToidymFoodImage({
    required this.url,
    super.key,
    this.category,
    this.fit = BoxFit.cover,
    this.backgroundColor = AppColors.accentLight,
    this.padding = EdgeInsets.zero,
  });

  final String url;
  final BoxCategory? category;
  final BoxFit fit;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  static String fallbackAssetFor(BoxCategory? category) {
    return switch (category) {
      BoxCategory.bakery => 'assets/images/image0_93_2.png',
      BoxCategory.coffee => 'assets/images/image7_93_2.png',
      BoxCategory.hotFood => 'assets/images/image6_93_2.png',
      null => 'assets/images/food_waffles.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final fallbackAsset = fallbackAssetFor(category);
    Widget buildAsset(String path) {
      return Container(
        color: backgroundColor,
        padding: padding,
        alignment: Alignment.center,
        child: Image.asset(
          path,
          fit: fit,
          errorBuilder: (_, _, _) => Container(
            color: backgroundColor,
            alignment: Alignment.center,
            child: const Icon(
              Icons.lunch_dining_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (url.isEmpty) {
      return buildAsset(fallbackAsset);
    }
    if (url.startsWith('asset:')) {
      return buildAsset(url.substring('asset:'.length));
    }

    return Container(
      color: backgroundColor,
      padding: padding,
      child: CachedNetworkImage(
        imageUrl: url,
        memCacheWidth: 720,
        fit: fit,
        placeholder: (_, _) => Image.asset(fallbackAsset, fit: fit),
        errorWidget: (_, _, _) => Image.asset(fallbackAsset, fit: fit),
      ),
    );
  }
}

/// Переключатель-пилюля в стиле Figma («Список | Карта», «Активные | Прошедшие»).
class ToidymPillToggle<T> extends StatelessWidget {
  const ToidymPillToggle({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
    this.darkSurface = false,
  });

  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool darkSurface;

  @override
  Widget build(BuildContext context) {
    final containerBg = darkSurface
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.accentLight;
    final activeBg = darkSurface ? AppColors.accent : AppColors.primary;
    final activeFg = darkSurface ? AppColors.primary : AppColors.textOnPrimary;
    final inactiveFg = darkSurface ? AppColors.textOnPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            GestureDetector(
              onTap: () => onSelected(item.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: item.value == selected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: item.value == selected ? activeFg : inactiveFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Нижний колонтитул в стиле Figma Web (C01–C05).
class ToidymWebFooter extends StatelessWidget {
  const ToidymWebFooter({super.key, this.isKk = false});

  final bool isKk;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            spacing: 16,
            children: [
              Text(
                isKk
                    ? 'toıdym · тек алып кету · Астана'
                    : 'toıdym · только самовывоз · Астана',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                isKk
                    ? 'Көмек · Сервис шарттары'
                    : 'Помощь · Условия сервиса',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Белая карточка без обводки с мягкой тенью Figma U01 (radius 22).
class ToidymCard extends StatelessWidget {
  const ToidymCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 22,
    this.color = AppColors.surface,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: border,
        boxShadow: AppColors.cardShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Чип фильтра категории / фильтра в стиле Figma U01 (height 44, radius 20).
class ToidymChip extends StatelessWidget {
  const ToidymChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.height = 44,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.accentLight,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label14.copyWith(
                    color: selected ? AppColors.background : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Тёплый инфо-баннер/callout #FFE8A8 в стиле Figma C02 / 25.
class ToidymInfoBanner extends StatelessWidget {
  const ToidymInfoBanner({
    required this.title,
    required this.subtitle,
    super.key,
    this.icon = Icons.info_outline_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label14.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Прозрачная иллюстрация еды из Figma-набора (banana bread / bowl / pastry bag / coffee).
class ToidymCutoutArtwork extends StatelessWidget {
  const ToidymCutoutArtwork({
    super.key,
    this.category,
    this.imageUrl,
    this.size = 84,
  });

  final BoxCategory? category;
  final String? imageUrl;
  final double size;

  static String assetForCategory(BoxCategory? category) {
    return switch (category) {
      BoxCategory.bakery => 'assets/images/image0_93_2.png',
      BoxCategory.coffee => 'assets/images/image7_93_2.png',
      BoxCategory.hotFood => 'assets/images/image6_93_2.png',
      null => 'assets/images/image0_93_2.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetForCategory(category);
    final url = imageUrl?.trim() ?? '';
    // Для демо-боксов со stock Unsplash используем фирменные вырезки Figma.
    final isCustomPartnerUpload =
        url.startsWith('http') && !url.contains('images.unsplash.com');

    if (isCustomPartnerUpload) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ToidymFoodImage(
            category: category,
            url: url,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Переключатель «Список | Карта» в стиле Figma C01 / C02 / 09.
class ToidymViewSwitch extends StatelessWidget {
  const ToidymViewSwitch({
    required this.isMap,
    required this.onListTap,
    required this.onMapTap,
    required this.listLabel,
    required this.mapLabel,
    super.key,
    this.compactWhitePill = false,
  });

  final bool isMap;
  final VoidCallback onListTap;
  final VoidCallback onMapTap;
  final String listLabel;
  final String mapLabel;
  final bool compactWhitePill;

  @override
  Widget build(BuildContext context) {
    if (compactWhitePill) {
      return Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegment(label: listLabel, active: !isMap, onTap: onListTap, whiteContainer: true),
            _buildSegment(label: mapLabel, active: isMap, onTap: onMapTap, whiteContainer: true),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSegment(label: listLabel, active: !isMap, onTap: onListTap, whiteContainer: false),
        const SizedBox(width: 8),
        _buildSegment(label: mapLabel, active: isMap, onTap: onMapTap, whiteContainer: false),
      ],
    );
  }

  Widget _buildSegment({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required bool whiteContainer,
  }) {
    final bg = active
        ? AppColors.primary
        : (whiteContainer ? Colors.transparent : AppColors.accentLight);
    final fg = active
        ? AppColors.background
        : (whiteContainer ? AppColors.primaryDark : AppColors.primary);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: whiteContainer ? 32 : 44,
          padding: EdgeInsets.symmetric(horizontal: whiteContainer ? 16 : 20),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label14.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}
