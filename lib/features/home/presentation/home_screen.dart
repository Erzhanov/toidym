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
import 'package:toidym/shared/widgets/box_card.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/error_state.dart';
import 'package:toidym/shared/widgets/shimmer_box.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Главный экран покупателя («Боксы рядом»: Desktop Web C01 / Mobile 09).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(boxSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _distanceKm(
    Venue? venue,
    AstanaDistrict district,
    ({double lat, double lng})? userCoords,
  ) {
    if (venue == null) return 0.6;
    final fromLat = userCoords?.lat ?? district.centerLat;
    final fromLng = userCoords?.lng ?? district.centerLng;
    return AppFormatters.calculateDistanceKm(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: venue.lat,
      toLng: venue.lng,
    );
  }

  String _eveningCountLabel(int count, bool isKk) {
    if (isKk) {
      return 'Бүгін кешке · $count ұсыныс';
    }
    final mod100 = count % 100;
    final mod10 = count % 10;
    final word = (mod100 >= 11 && mod100 <= 14)
        ? 'предложений'
        : mod10 == 1
            ? 'предложение'
            : (mod10 >= 2 && mod10 <= 4)
                ? 'предложения'
                : 'предложений';
    return 'Сегодня вечером · $count $word';
  }

  void _openDistrictPicker() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final current = sheetRef.watch(selectedDistrictProvider);
            final strict = sheetRef.watch(filterStrictlyByDistrictProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderChip,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.onboardingOrChooseDistrict,
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 14),
                    ToidymCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      onTap: () {
                        sheetRef
                            .read(filterStrictlyByDistrictProvider.notifier)
                            .state = false;
                        Navigator.pop(ctx);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.districtAllAstana,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          if (!strict)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final d in AstanaDistrict.values) ...[
                      ToidymCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        onTap: () async {
                          await sheetRef
                              .read(selectedDistrictProvider.notifier)
                              .selectDistrict(d);
                          sheetRef
                              .read(filterStrictlyByDistrictProvider.notifier)
                              .state = true;
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                d.label(l10n),
                                style: AppTextStyles.titleMedium,
                              ),
                            ),
                            if (strict && current == d)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterSortSheet() {
    final l10n = context.l10n;
    final isKk = ref.read(localeProvider).languageCode == 'kk';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final sortOption = sheetRef.watch(boxSortOptionProvider);
            final dietary = sheetRef.watch(dietaryPreferencesProvider);
            final strictDistrict = sheetRef.watch(
              filterStrictlyByDistrictProvider,
            );
            final district = sheetRef.watch(selectedDistrictProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderChip,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isKk ? 'Сұрыптау және сүзгі' : 'Сортировка и фильтры',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isKk ? 'Сұрыптау' : 'Сортировка',
                      style: AppTextStyles.label14,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BoxSortOption.values.map((opt) {
                        return ToidymChip(
                          label: opt.label(l10n),
                          selected: sortOption == opt,
                          onTap: () {
                            sheetRef
                                .read(boxSortOptionProvider.notifier)
                                .state = opt;
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isKk ? 'Тағам ерекшеліктері' : 'Предпочтения',
                      style: AppTextStyles.label14,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ToidymChip(
                          label: DietaryPreference.halalOnly.label(l10n),
                          selected: dietary.contains(
                            DietaryPreference.halalOnly,
                          ),
                          onTap: () => sheetRef
                              .read(dietaryPreferencesProvider.notifier)
                              .toggle(DietaryPreference.halalOnly),
                        ),
                        ToidymChip(
                          label: DietaryPreference.vegetarian.label(l10n),
                          selected: dietary.contains(
                            DietaryPreference.vegetarian,
                          ),
                          onTap: () => sheetRef
                              .read(dietaryPreferencesProvider.notifier)
                              .toggle(DietaryPreference.vegetarian),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ToidymCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openDistrictPicker();
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strictDistrict
                                  ? 'Астана, ${district.label(l10n)}'
                                  : 'Астана, ${l10n.districtAllAstana}',
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isKk ? 'Қолдану' : 'Показать боксы'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openNotificationsSheet() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final lang = sheetRef.watch(localeProvider).languageCode;
            final notifications = sheetRef.watch(notificationsProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderChip,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.homeNotificationsTitle,
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                        if (notifications.any((n) => !n.isRead))
                          TextButton(
                            onPressed: () => sheetRef
                                .read(notificationsProvider.notifier)
                                .markAllRead(),
                            child: Text(
                              lang == 'kk'
                                  ? 'Бәрін оқу'
                                  : 'Прочитать все',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          lang == 'kk'
                              ? 'Әзірше хабарламалар жоқ'
                              : 'Пока нет уведомлений',
                          style: AppTextStyles.bodyMedium,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = notifications[index];
                            return ToidymCard(
                              padding: const EdgeInsets.all(14),
                              color: item.isRead
                                  ? AppColors.surface
                                  : AppColors.accentLight,
                              onTap: () => sheetRef
                                  .read(notificationsProvider.notifier)
                                  .markAllRead(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title(lang),
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body(lang),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(boxSearchQueryProvider.notifier).state = '';
    ref.read(boxFilterChipProvider.notifier).state = BoxFilterChip.all;
    ref.read(filterStrictlyByDistrictProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final boxesAsync = ref.watch(boxesFeedProvider);
    final venuesMap = ref.watch(venuesMapProvider);
    final favorites = ref.watch(favoritesProvider);
    final district = ref.watch(selectedDistrictProvider);
    final strictDistrict = ref.watch(filterStrictlyByDistrictProvider);
    final activeFilter = ref.watch(boxFilterChipProvider);
    final sortOption = ref.watch(boxSortOptionProvider);
    final userCoords = ref.watch(userCoordinatesProvider);
    final user = ref.watch(currentUserProvider);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final isKk = ref.watch(localeProvider).languageCode == 'kk';
    final l10n = context.l10n;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    if (isDesktop) {
      return _buildDesktopView(
        context: context,
        boxesAsync: boxesAsync,
        venuesMap: venuesMap,
        favorites: favorites,
        district: district,
        strictDistrict: strictDistrict,
        activeFilter: activeFilter,
        sortOption: sortOption,
        userCoords: userCoords,
        isKk: isKk,
        l10n: l10n,
        screenWidth: screenWidth,
      );
    }

    return _buildMobileView(
      context: context,
      boxesAsync: boxesAsync,
      venuesMap: venuesMap,
      favorites: favorites,
      district: district,
      strictDistrict: strictDistrict,
      activeFilter: activeFilter,
      sortOption: sortOption,
      userCoords: userCoords,
      user: user,
      unreadCount: unreadCount,
      isKk: isKk,
      l10n: l10n,
    );
  }

  Widget _buildDesktopView({
    required BuildContext context,
    required AsyncValue<List<Box>> boxesAsync,
    required Map<String, Venue> venuesMap,
    required Set<String> favorites,
    required AstanaDistrict district,
    required bool strictDistrict,
    required BoxFilterChip activeFilter,
    required BoxSortOption sortOption,
    required ({double lat, double lng})? userCoords,
    required bool isKk,
    required dynamic l10n,
    required double screenWidth,
  }) {
    final horizontalPad = screenWidth >= 1200 ? 64.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ToidymBuyerWebHeader(
              searchController: _searchController,
              onSearchChanged: (value) =>
                  ref.read(boxSearchQueryProvider.notifier).state = value,
              onDistrictTap: _openDistrictPicker,
              onNotificationsTap: _openNotificationsSheet,
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    28,
                    horizontalPad,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Список / Карта toggle
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isKk ? 'Жақын бокстар' : 'Боксы рядом',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          ToidymViewSwitch(
                            isMap: false,
                            listLabel: isKk ? 'Тізім' : 'Список',
                            mapLabel: isKk ? 'Карта' : 'Карта',
                            onListTap: () {},
                            onMapTap: () => context.go(AppRoutes.map),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Category chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final chip in BoxFilterChip.values)
                            ToidymChip(
                              label: chip.label(l10n),
                              selected: activeFilter == chip,
                              onTap: () => ref
                                  .read(boxFilterChipProvider.notifier)
                                  .state = chip,
                            ),
                          ToidymChip(
                            label: isKk ? 'Сүзгі' : 'Фильтры',
                            selected: false,
                            onTap: _openFilterSortSheet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Hero #FFE8A8 Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/image0_93_2.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isKk
                                        ? 'Тағамды −70% дейін сақта'
                                        : 'Спасай еду до −70%',
                                    style: AppTextStyles.headlineMedium
                                        .copyWith(
                                          color: AppColors.primaryDark,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isKk
                                        ? 'Аккаунт тек тапсырыс үшін. Боксты көрсетілген уақытта алып кетіңіз — жеткізусіз.'
                                        : 'Аккаунт нужен только для заказа. Заберите бокс в указанное время — без доставки.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Material(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                onTap: _openDistrictPicker,
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        strictDistrict
                                            ? district.label(l10n)
                                            : (isKk ? 'Бүгін' : 'Сегодня'),
                                        style: AppTextStyles.label14.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ...boxesAsync.when(
            loading: () => [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPad,
                        vertical: 20,
                      ),
                      child: const Column(
                        children: [
                          BoxCardSkeleton(),
                          SizedBox(height: 12),
                          BoxCardSkeleton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            error: (_, _) => [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: ErrorState(
                        onRetry: () => ref.invalidate(boxesFeedProvider),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            data: (boxes) {
              if (boxes.isEmpty) {
                return [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: EmptyState(
                            title: isKk
                                ? 'Бокстар табылмады'
                                : 'Подходящих боксов не найдено',
                            subtitle: isKk
                                ? 'Сүзгіні немесе ауданды өзгертіп көріңіз'
                                : 'Попробуйте сбросить фильтры или выбрать весь город',
                            actionLabel:
                                isKk ? 'Сүзгіні тазарту' : 'Сбросить фильтры',
                            onAction: _resetFilters,
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              }

              final pickupNowBoxes = [
                ...boxes.where((b) => b.isResale),
                ...boxes.where((b) => !b.isResale),
              ].take(6).toList();
              final cols = screenWidth >= 1120 ? 3 : 2;

              return [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section title + sort dropdown
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _eveningCountLabel(boxes.length, isKk),
                                    style: AppTextStyles.headlineMedium
                                        .copyWith(
                                          color: AppColors.primaryDark,
                                        ),
                                  ),
                                ),
                                PopupMenuButton<BoxSortOption>(
                                  initialValue: sortOption,
                                  color: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  onSelected: (opt) => ref
                                      .read(boxSortOptionProvider.notifier)
                                      .state = opt,
                                  itemBuilder: (_) => BoxSortOption.values
                                      .map(
                                        (opt) => PopupMenuItem<BoxSortOption>(
                                          value: opt,
                                          child: Text(
                                            opt.label(l10n),
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.primaryDark,
                                                  fontWeight: opt == sortOption
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          sortOption == BoxSortOption.nearest
                                              ? (isKk
                                                  ? 'Қашықтық бойынша'
                                                  : 'По расстоянию')
                                              : sortOption.label(l10n),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 3-column BoxHorizontalCard grid
                            _ResponsiveCardGrid(
                              columns: cols,
                              spacing: 16,
                              children: boxes.map((box) {
                                final venue = venuesMap[box.venueId];
                                final km = _distanceKm(
                                  venue,
                                  district,
                                  userCoords,
                                );
                                return BoxHorizontalCard(
                                  box: box,
                                  venue: venue,
                                  distanceKm: km,
                                  isFavorite: favorites.contains(box.id),
                                  onTap: () => context.push(
                                    AppRoutes.boxDetailPath(box.id),
                                  ),
                                  onToggleFavorite: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggle(box.id),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              isKk ? 'Қазір алып кету' : 'Забрать сейчас',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    clipBehavior: Clip.none,
                                    child: Row(
                                      children: [
                                        for (var i = 0;
                                            i < pickupNowBoxes.length;
                                            i++) ...[
                                          if (i > 0) const SizedBox(width: 16),
                                          BoxTallCard(
                                            box: pickupNowBoxes[i],
                                            venue:
                                                venuesMap[pickupNowBoxes[i]
                                                    .venueId],
                                            distanceKm: _distanceKm(
                                              venuesMap[
                                                  pickupNowBoxes[i].venueId],
                                              district,
                                              userCoords,
                                            ),
                                            isFavorite: favorites.contains(
                                              pickupNowBoxes[i].id,
                                            ),
                                            onTap: () => context.push(
                                              AppRoutes.boxDetailPath(
                                                pickupNowBoxes[i].id,
                                              ),
                                            ),
                                            onToggleFavorite: () => ref
                                                .read(
                                                  favoritesProvider.notifier,
                                                )
                                                .toggle(pickupNowBoxes[i].id),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (screenWidth >= 1080) ...[
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    width: 320,
                                    child: ToidymCard(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isKk
                                                ? 'Таңдаңыз және алып кетіңіз'
                                                : 'Выберите и заберите',
                                            style: AppTextStyles.titleLarge
                                                .copyWith(
                                                  color: AppColors.primaryDark,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            isKk
                                                ? 'Тек көрсетілген уақытта үлгеретін боксты брондаңыз. Нақты құрамы — тосынсый.'
                                                : 'Бронируйте только то, что успеете забрать в указанное окно. Точный состав — сюрприз.',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            isKk
                                                ? 'Себетсіз және жеткізусіз · таңдалған бокс үшін төлем'
                                                : 'Без корзины и доставки · оплата за выбранный бокс',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
          ),
          SliverToBoxAdapter(child: ToidymWebFooter(isKk: isKk)),
        ],
      ),
    );
  }

  Widget _buildMobileView({
    required BuildContext context,
    required AsyncValue<List<Box>> boxesAsync,
    required Map<String, Venue> venuesMap,
    required Set<String> favorites,
    required AstanaDistrict district,
    required bool strictDistrict,
    required BoxFilterChip activeFilter,
    required BoxSortOption sortOption,
    required ({double lat, double lng})? userCoords,
    required dynamic user,
    required int unreadCount,
    required bool isKk,
    required dynamic l10n,
  }) {
    final districtText = strictDistrict
        ? district.label(l10n)
        : l10n.districtAllAstana;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(boxesFeedProvider),
        child: CustomScrollView(
          slivers: [
            // Indigo Figma 09 Header
            SliverToBoxAdapter(
              child: ToidymDarkHeader(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.sheet),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 12,
                  16,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go(
                            user != null ? AppRoutes.profile : AppRoutes.auth,
                          ),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.raisedIndigo,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: user != null
                                ? Text(
                                    user.name.trim().isNotEmpty
                                        ? user.name.trim()[0].toUpperCase()
                                        : 'A',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.accent,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.background,
                                    size: 22,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user != null
                                    ? 'Сәлем, ${user.name.trim().split(' ').first}!'
                                    : 'Сәлем!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.background,
                                  fontSize: 20,
                                ),
                              ),
                              InkWell(
                                onTap: _openDistrictPicker,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Астана, $districtText',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.lavenderChip,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.lavenderChip,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            InkWell(
                              onTap: _openNotificationsSheet,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.raisedIndigo,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.background,
                                  size: 22,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isKk
                              ? 'Үнемделді ${AppFormatters.formatPrice(user.stats.moneySaved)}'
                              : 'Сэкономлено ${AppFormatters.formatPrice(user.stats.moneySaved)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.push(AppRoutes.auth),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l10n.actionLogin,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isKk ? '70% дейін үнемдеу' : 'Скидки до 70%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.lavenderChip,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _searchController,
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
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: AppColors.accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _openFilterSortSheet,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 50,
                              height: 50,
                              child: Icon(
                                Icons.tune_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Two-tone Title + Список / Карта toggle + Category Chips
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: isKk ? 'Бокстар ' : 'Боксы ',
                                ),
                                TextSpan(
                                  text: isKk ? 'жақында' : 'рядом',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ToidymViewSwitch(
                          isMap: false,
                          compactWhitePill: true,
                          listLabel: isKk ? 'Тізім' : 'Список',
                          mapLabel: 'Карта',
                          onListTap: () {},
                          onMapTap: () => context.go(AppRoutes.map),
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
                      itemBuilder: (_, index) {
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
            ...boxesAsync.when(
              loading: () => const [
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        BoxCardSkeleton(),
                        SizedBox(height: 12),
                        BoxCardSkeleton(),
                      ],
                    ),
                  ),
                ),
              ],
              error: (_, _) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                    child: ErrorState(
                      onRetry: () => ref.invalidate(boxesFeedProvider),
                    ),
                  ),
                ),
              ],
              data: (boxes) {
                if (boxes.isEmpty) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                        child: EmptyState(
                          title: isKk
                              ? 'Бокстар табылмады'
                              : 'Подходящих боксов не найдено',
                          subtitle: isKk
                              ? 'Басқа сүзгіні таңдап көріңіз'
                              : 'Попробуйте сбросить фильтры или сменить район',
                          actionLabel:
                              isKk ? 'Тазарту' : 'Сбросить фильтры',
                          onAction: _resetFilters,
                        ),
                      ),
                    ),
                  ];
                }

                final pickupNowBoxes = [
                  ...boxes.where((b) => b.isResale),
                  ...boxes.where((b) => !b.isResale),
                ].take(6).toList();

                return [
                  // Забрать сейчас horizontal rail
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isKk ? 'Қазір алып кету' : 'Забрать сейчас',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _openFilterSortSheet,
                            child: Text(
                              isKk ? 'Бәрі' : 'Все',
                              style: AppTextStyles.label14.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 236,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pickupNowBoxes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, index) {
                          final box = pickupNowBoxes[index];
                          final venue = venuesMap[box.venueId];
                          return BoxTallCard(
                            box: box,
                            venue: venue,
                            distanceKm: _distanceKm(
                              venue,
                              district,
                              userCoords,
                            ),
                            isFavorite: favorites.contains(box.id),
                            onTap: () =>
                                context.push(AppRoutes.boxDetailPath(box.id)),
                            onToggleFavorite: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(box.id),
                          );
                        },
                      ),
                    ),
                  ),
                  // Сегодня вечером vertical list
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isKk ? 'Бүгін кешке' : 'Сегодня вечером',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _openFilterSortSheet,
                            child: Text(
                              sortOption == BoxSortOption.nearest
                                  ? (isKk ? 'Бәрі' : 'Все')
                                  : sortOption.label(l10n),
                              style: AppTextStyles.label14.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                    sliver: SliverList.separated(
                      itemCount: boxes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final box = boxes[index];
                        final venue = venuesMap[box.venueId];
                        return BoxHorizontalCard(
                          box: box,
                          venue: venue,
                          distanceKm: _distanceKm(venue, district, userCoords),
                          isFavorite: favorites.contains(box.id),
                          onTap: () =>
                              context.push(AppRoutes.boxDetailPath(box.id)),
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(box.id),
                        );
                      },
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) rowChildren.add(SizedBox(width: spacing));
        final idx = i + c;
        if (idx < children.length) {
          rowChildren.add(Expanded(child: children[idx]));
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      if (i > 0) rows.add(SizedBox(height: spacing));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );
    }
    return Column(children: rows);
  }
}
