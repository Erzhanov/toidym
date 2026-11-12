import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/box_card.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Полноэкранная карта боксов Астаны на OpenStreetMap (без API-ключей).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedBoxId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mapCfg = ref.watch(mapProvider);
    final district = ref.watch(selectedDistrictProvider);
    final activeFilter = ref.watch(boxFilterChipProvider);
    final boxes = ref.watch(boxesFeedProvider).valueOrNull ?? const [];
    final venuesMap = ref.watch(venuesMapProvider);
    final favorites = ref.watch(favoritesProvider);
    final userPoint = LatLng(district.centerLat, district.centerLng);
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    final isKk = ref.watch(localeProvider).languageCode == 'kk';

    final selectedBox = boxes.isEmpty
        ? null
        : boxes.cast<Box?>().firstWhere(
              (b) => b?.id == _selectedBoxId,
              orElse: () => boxes.first,
            );
    final selectedVenue =
        selectedBox == null ? null : venuesMap[selectedBox.venueId];

    // Если в одном заведении несколько боксов — слегка сдвигаем пин, чтобы все читались.
    final seenPerVenue = <String, int>{};

    Widget buildMarkersMap({required bool interactiveSelect}) {
      seenPerVenue.clear();
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: userPoint,
          initialZoom: 12.6,
        ),
        children: [
          TileLayer(
            urlTemplate: mapCfg.tileUrlTemplate,
            userAgentPackageName: 'kz.toidym.toidym',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: userPoint,
                width: 96,
                height: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: AppRadius.badgeBorderRadius,
                      ),
                      child: Text(
                        l10n.mapYouAreHere,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnPrimary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final box in boxes)
                if (venuesMap[box.venueId] != null)
                  () {
                    final venue = venuesMap[box.venueId]!;
                    final offsetIdx = seenPerVenue.update(
                      venue.id,
                      (v) => v + 1,
                      ifAbsent: () => 0,
                    );
                    final point = LatLng(
                      venue.lat + offsetIdx * 0.0014,
                      venue.lng + offsetIdx * 0.0018,
                    );
                    final isSelected = selectedBox?.id == box.id;
                    return Marker(
                      point: point,
                      width: isSelected ? 104 : 90,
                      height: isSelected ? 42 : 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedBoxId = box.id);
                          _mapController.move(point, 13.2);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : (box.isSoldOut
                                    ? AppColors.textSecondary
                                    : AppColors.primary),
                            borderRadius: AppRadius.badgeBorderRadius,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  )
                                : null,
                            boxShadow: AppColors.cardShadows,
                          ),
                          child: Text(
                            AppFormatters.formatPrice(box.discountPrice),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: isSelected ? 14 : 12,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(mapCfg.attributionLabel),
            ],
          ),
        ],
      );
    }

    if (isDesktop) {
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
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.screenMapTitle,
                                      style: AppTextStyles.displayLarge.copyWith(
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  ToidymViewSwitch(
                                    isMap: true,
                                    listLabel: isKk ? 'Тізім' : 'Список',
                                    mapLabel: l10n.navMap,
                                    onListTap: () => context.go(AppRoutes.home),
                                    onMapTap: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 44,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: BoxFilterChip.values.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final chip = BoxFilterChip.values[index];
                                    return ToidymChip(
                                      label: chip.label(l10n),
                                      selected: activeFilter == chip,
                                      onTap: () => ref
                                          .read(
                                            boxFilterChipProvider.notifier,
                                          )
                                          .state = chip,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: AppRadius.cardBorderRadius,
                                      child: SizedBox(
                                        height: 540,
                                        child: Stack(
                                          children: [
                                            buildMarkersMap(
                                              interactiveSelect: true,
                                            ),
                                            Positioned(
                                              left: 16,
                                              bottom: 16,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius: AppRadius
                                                      .badgeBorderRadius,
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: AppColors.shadow,
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        final cam =
                                                            _mapController
                                                                .camera;
                                                        _mapController.move(
                                                          cam.center,
                                                          (cam.zoom - 0.8)
                                                              .clamp(10, 17),
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.remove_rounded,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        final cam =
                                                            _mapController
                                                                .camera;
                                                        _mapController.move(
                                                          cam.center,
                                                          (cam.zoom + 0.8)
                                                              .clamp(10, 17),
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.add_rounded,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip:
                                                          l10n.mapCenterOnMe,
                                                      onPressed: () =>
                                                          _mapController.move(
                                                        userPoint,
                                                        13.0,
                                                      ),
                                                      icon: const Icon(
                                                        Icons
                                                            .my_location_rounded,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (selectedBox != null &&
                                      selectedVenue != null) ...[
                                    const SizedBox(width: 24),
                                    SizedBox(
                                      width: 368,
                                      child: Column(
                                        children: [
                                          ToidymCard(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedVenue.name,
                                                  style: AppTextStyles
                                                      .headlineMedium
                                                      .copyWith(
                                                    color:
                                                        AppColors.primaryDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accentLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${isKk ? "Таңдалды" : "Выбрано"} · ${AppFormatters.formatDistance(AppFormatters.calculateDistanceKm(fromLat: district.centerLat, fromLng: district.centerLng, toLat: selectedVenue.lat, toLng: selectedVenue.lng), l10n)}',
                                                    style: AppTextStyles
                                                        .captionSmall
                                                        .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Center(
                                                  child: ToidymCutoutArtwork(
                                                    category:
                                                        selectedBox.category,
                                                    imageUrl: selectedBox
                                                            .photos.isNotEmpty
                                                        ? selectedBox
                                                            .photos.first
                                                        : null,
                                                    size: 108,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                BoxHorizontalCard(
                                                  box: selectedBox,
                                                  venue: selectedVenue,
                                                  distanceKm: AppFormatters
                                                      .calculateDistanceKm(
                                                    fromLat: district.centerLat,
                                                    fromLng: district.centerLng,
                                                    toLat: selectedVenue.lat,
                                                    toLng: selectedVenue.lng,
                                                  ),
                                                  isFavorite: favorites
                                                      .contains(selectedBox.id),
                                                  onTap: () => context.push(
                                                    AppRoutes.boxDetailPath(
                                                      selectedBox.id,
                                                    ),
                                                  ),
                                                  onToggleFavorite: () => ref
                                                      .read(
                                                        favoritesProvider
                                                            .notifier,
                                                      )
                                                      .toggle(selectedBox.id),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      l10n.venueAddressLabel,
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        selectedVenue.address,
                                                        textAlign: TextAlign.end,
                                                        style: AppTextStyles
                                                            .label14
                                                            .copyWith(
                                                          color:
                                                              AppColors.primary,
                                                        ),
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
                                                      isKk
                                                          ? 'Бүгін беру'
                                                          : 'Выдача сегодня',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      selectedBox
                                                          .pickupWindow.formatted,
                                                      style: AppTextStyles
                                                          .label14
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 18),
                                                PrimaryButton(
                                                  label: isKk
                                                      ? 'Боксты көру'
                                                      : 'Посмотреть бокс',
                                                  onPressed: () => context.push(
                                                    AppRoutes.boxDetailPath(
                                                      selectedBox.id,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                SecondaryButton(
                                                  label: l10n.mapOpenInList,
                                                  onPressed: () =>
                                                      context.go(AppRoutes.home),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          ToidymInfoBanner(
                                            title: isKk
                                                ? 'Тек алып кету'
                                                : 'Только самовывоз',
                                            subtitle: isKk
                                                ? 'Брондау алдында мекенжай мен уақытты тексеріңіз.'
                                                : 'Проверьте адрес и окно получения перед бронированием.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
      body: Stack(
        children: [
          buildMarkersMap(interactiveSelect: true),

          // Верхняя строка поиска + фильтры (Figma 12 · Карта)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppColors.cardShadows,
                          ),
                          child: TextField(
                            onChanged: (value) => ref
                                .read(boxSearchQueryProvider.notifier)
                                .state = value,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primaryDark,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: isKk
                                  ? 'Мекемелер мен бокстар'
                                  : 'Заведения и боксы',
                              hintStyle: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToidymViewSwitch(
                        isMap: true,
                        compactWhitePill: true,
                        listLabel: isKk ? 'Тізім' : 'Список',
                        mapLabel: 'Карта',
                        onListTap: () => context.go(AppRoutes.home),
                        onMapTap: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: BoxFilterChip.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chip = BoxFilterChip.values[index];
                      return ToidymChip(
                        label: chip.label(l10n),
                        selected: activeFilter == chip,
                        onTap: () => ref
                            .read(boxFilterChipProvider.notifier)
                            .state = chip,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: selectedBox != null ? 248 : 108,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: AppColors.shadow,
              child: InkWell(
                onTap: () => _mapController.move(userPoint, 13.0),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          if (selectedBox != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: BoxHorizontalCard(
                box: selectedBox,
                venue: selectedVenue,
                distanceKm: selectedVenue == null
                    ? 0.6
                    : AppFormatters.calculateDistanceKm(
                        fromLat: district.centerLat,
                        fromLng: district.centerLng,
                        toLat: selectedVenue.lat,
                        toLng: selectedVenue.lng,
                      ),
                isFavorite: favorites.contains(selectedBox.id),
                onTap: () =>
                    context.push(AppRoutes.boxDetailPath(selectedBox.id)),
                onToggleFavorite: () => ref
                    .read(favoritesProvider.notifier)
                    .toggle(selectedBox.id),
              ),
            ),
        ],
      ),
    );
  }
}
