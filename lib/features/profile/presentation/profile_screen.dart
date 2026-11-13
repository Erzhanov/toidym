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
import 'package:toidym/features/auth/presentation/auth_modal_screen.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/booking_warning_sheet.dart';
import 'package:toidym/shared/widgets/box_card.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';
import 'package:toidym/shared/widgets/toidym_buyer_web_header.dart';

/// Профиль покупателя: статистика, диета, Strikes, «Қызыл кітап», избранное и настройки.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  Future<void> _buyCharityBox(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (user.isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authErrAccountBanned)),
      );
      return;
    }

    final accepted = await showOfflineBookingWarningSheet(context);
    if (!accepted || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileCharityTitle),
        content: Text(
          '${l10n.profileCharitySubtitle}\n\n${AppFormatters.formatPrice(990)} · ${l10n.paymentOnSite}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profileCharityConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final boxes = ref.read(allBoxesStreamProvider).valueOrNull ?? const [];
    final targetBox = boxes.firstWhere(
      (b) => b.isAvailable,
      orElse: () => boxes.first,
    );

    await ref.read(orderRepositoryProvider).createReservation(
          userId: user.id,
          boxId: targetBox.id,
          venueId: targetBox.venueId,
          quantity: 1,
          totalPrice: 990,
          originalTotalPrice: 2970,
          isCharityBox: true,
        );

    HapticFeedback.heavyImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.profileCharitySuccess)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final favoriteAlerts = ref.watch(favoriteAlertsProvider);
    final snowfallEnabled = ref.watch(snowfallEnabledProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                title: Text(
                  l10n.screenProfileTitle,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
        body: Column(
          children: [
            if (isDesktop) const ToidymBuyerWebHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      48,
                    ),
                    children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const QumbekMascot(size: 112, mood: QumbekMood.happy),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.guestBenefitsTitle,
                        style: AppTextStyles.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.guestBenefitsSubtitle,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _BenefitRow(
                        icon: Icons.qr_code_2_rounded,
                        text: l10n.guestBenefitOrders,
                      ),
                      _BenefitRow(
                        icon: Icons.eco_outlined,
                        text: l10n.guestBenefitStats,
                      ),
                      _BenefitRow(
                        icon: Icons.pets_rounded,
                        text: l10n.guestBenefitKitap,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: l10n.actionLogin,
                        onPressed: () => showAuthBottomSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _LanguageCard(
                currentLanguage: AppLanguage.fromCode(locale.languageCode),
                onChanged: (lang) =>
                    ref.read(localeProvider.notifier).setLanguage(lang),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final favoriteIds = ref.watch(favoritesProvider);
    final allBoxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];
    final favoriteBoxes =
        allBoxes.where((b) => favoriteIds.contains(b.id)).toList();
    final venuesMap = ref.watch(venuesMapProvider);
    final district = ref.watch(selectedDistrictProvider);
    final dietaryPrefs = ref.watch(dietaryPreferencesProvider);

    final nextAnimal = user.qyzylKitap.currentAnimal.nextAnimal;
    final targetBoxes = nextAnimal?.requiredBoxes ?? 50;
    final progressRatio =
        (user.stats.boxesSaved / targetBoxes).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (isDesktop)
            const ToidymBuyerWebHeader()
          else
            ToidymDarkHeader(
              child: Row(
                children: [
                  const QumbekMascot(size: 56, mood: QumbekMood.happy),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        Text(
                          '${user.email} · ${user.phone}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.navInactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: user.role.apiValue,
                    tone: AppBadgeTone.accent,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 28 : AppSpacing.md,
                    AppSpacing.md,
                    isDesktop ? 28 : AppSpacing.md,
                    isDesktop ? 48 : 108,
                  ),
                  children: [

            // Надёжность и 3 Strikes
            Card(
              color: user.isBanned
                  ? AppColors.errorLight
                  : (user.strikesCount > 0 ? AppColors.warningLight : null),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.profileStrikesTitle,
                          style: AppTextStyles.titleMedium,
                        ),
                        AppBadge(
                          label: l10n.profileStrikesCount(user.strikesCount),
                          tone: user.strikesCount == 0
                              ? AppBadgeTone.success
                              : (user.isBanned
                                  ? AppBadgeTone.error
                                  : AppBadgeTone.warning),
                        ),
                      ],
                    ),
                    if (user.isBanned && user.bannedUntil != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileBannedUntil(_formatDate(user.bannedUntil!)),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.errorText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Диетические предпочтения
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileDietSettingsTitle,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final pref in DietaryPreference.values)
                          ToidymChip(
                            label: pref.label(l10n),
                            selected: dietaryPrefs.contains(pref),
                            onTap: () {
                              ref
                                  .read(dietaryPreferencesProvider.notifier)
                                  .toggle(pref);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Статистика спасённой еды
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '${user.stats.boxesSaved}',
                    label: l10n.profileBoxesSaved,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StatCard(
                    value: AppFormatters.formatWeightKg(
                      user.stats.kgSaved,
                      l10n,
                    ),
                    label: l10n.profileKgSaved,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StatCard(
                    value: AppFormatters.formatPrice(user.stats.moneySaved),
                    label: l10n.profileMoneySaved,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Коллекция «Қызыл кітап»
            Card(
              child: InkWell(
                borderRadius: AppRadius.cardBorderRadius,
                onTap: () => context.push(AppRoutes.qyzylKitap),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.qyzylKitapTitle,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progressRatio),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: AppRadius.badgeBorderRadius,
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: AppColors.surfaceVariant,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        nextAnimal == null
                            ? l10n.qyzylKitapAllUnlocked
                            : l10n.qyzylKitapProgress(
                                user.stats.boxesSaved,
                                targetBoxes,
                                user.qyzylKitap.boxesToNext,
                                nextAnimal.label(l10n),
                              ),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Избранное (Hive)
            Text(l10n.profileFavoritesTitle, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            if (favoriteBoxes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.profileFavoritesEmpty,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favoriteBoxes.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final box = favoriteBoxes[index];
                    final venue = venuesMap[box.venueId];
                    final dist = venue == null
                        ? 1.2
                        : AppFormatters.calculateDistanceKm(
                            fromLat: district.centerLat,
                            fromLng: district.centerLng,
                            toLat: venue.lat,
                            toLng: venue.lng,
                          );
                    return SizedBox(
                      width: 296,
                      child: BoxCard(
                        box: box,
                        venue: venue,
                        distanceKm: dist,
                        isFavorite: true,
                        compact: true,
                        onTap: () =>
                            context.push(AppRoutes.boxDetailPath(box.id)),
                        onToggleFavorite: () =>
                            ref.read(favoritesProvider.notifier).toggle(box.id),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            // Настройки: язык и уведомления
            _LanguageCard(
              currentLanguage: AppLanguage.fromCode(locale.languageCode),
              onChanged: (lang) =>
                  ref.read(localeProvider.notifier).setLanguage(lang),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: SwitchListTile.adaptive(
                value: favoriteAlerts,
                onChanged: (value) async {
                  ref.read(favoriteAlertsProvider.notifier).state = value;
                  await ref
                      .read(appPreferencesProvider)
                      .setFavoriteAlertsEnabled(value);
                },
                title: Text(
                  l10n.profileFavoriteAlerts,
                  style: AppTextStyles.bodyLargeMedium,
                ),
                subtitle: Text(
                  l10n.profileFavoriteAlertsSubtitle,
                  style: AppTextStyles.caption,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: SwitchListTile.adaptive(
                value: snowfallEnabled,
                onChanged: (value) async {
                  ref.read(snowfallEnabledProvider.notifier).state = value;
                  await ref
                      .read(appPreferencesProvider)
                      .setSnowfallEnabled(value);
                },
                title: Text(
                  l10n.profileSnowfallAnimation,
                  style: AppTextStyles.bodyLargeMedium,
                ),
                subtitle: Text(
                  l10n.profileSnowfallSubtitle,
                  style: AppTextStyles.caption,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Подвешенный бокс для фонда
            Card(
              color: AppColors.accentLight,
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.textOnAccent,
                  ),
                ),
                title: Text(
                  l10n.profileCharityTitle,
                  style: AppTextStyles.titleMedium,
                ),
                subtitle: Text(l10n.profileCharitySubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _buyCharityBox(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Панель партнёра / администратора или подача заявки на партнёрство
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user.canAccessAdminMode) ...[
                      PrimaryButton(
                        label: l10n.actionSwitchToAdmin,
                        icon: Icons.admin_panel_settings_rounded,
                        onPressed: () => ref
                            .read(activeAppModeProvider.notifier)
                            .setMode(AppMode.admin),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    if (user.canAccessVenueMode)
                      user.canAccessAdminMode
                          ? SecondaryButton(
                              label: l10n.actionSwitchToVenue,
                              icon: Icons.storefront_rounded,
                              onPressed: () => ref
                                  .read(activeAppModeProvider.notifier)
                                  .setMode(AppMode.venue),
                            )
                          : PrimaryButton(
                              label: l10n.actionSwitchToVenue,
                              icon: Icons.storefront_rounded,
                              onPressed: () => ref
                                  .read(activeAppModeProvider.notifier)
                                  .setMode(AppMode.venue),
                            )
                    else
                      SecondaryButton(
                        label: l10n.actionBecomePartner,
                        icon: Icons.storefront_rounded,
                        onPressed: () => context.push(AppRoutes.partnerApply),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
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
              label: Text(l10n.actionLogout),
            ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.currentLanguage,
    required this.onChanged,
  });

  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.languageTitle,
                style: AppTextStyles.bodyLargeMedium,
              ),
            ),
            ToidymPillToggle<AppLanguage>(
              selected: currentLanguage,
              items: [
                (value: AppLanguage.kk, label: l10n.languageKk),
                (value: AppLanguage.ru, label: l10n.languageRu),
              ],
              onSelected: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
