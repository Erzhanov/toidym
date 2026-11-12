import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

/// Верхняя шапка веб-интерфейса покупателя (Figma C01–C05).
class ToidymBuyerWebHeader extends ConsumerWidget {
  const ToidymBuyerWebHeader({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onDistrictTap,
    this.onNotificationsTap,
    this.trailingAction,
  });

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onDistrictTap;
  final VoidCallback? onNotificationsTap;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final district = ref.watch(selectedDistrictProvider);
    final strictDistrict = ref.watch(filterStrictlyByDistrictProvider);
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final isKk = locale.languageCode == 'kk';
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = screenWidth >= 1200 ? 64.0 : 28.0;

    final districtText = strictDistrict
        ? district.label(l10n)
        : l10n.districtAllAstana;
    final locationLabel = 'Астана, $districtText';

    return ToidymDarkHeader(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.sheet),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => context.go(AppRoutes.home),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: ToidymLogo(height: 54),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onDistrictTap ?? () => context.go(AppRoutes.home),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              size: 16,
                              color: AppColors.background,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                locationLabel,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.background,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          if (onSearchChanged != null) {
                            onSearchChanged!(value);
                          } else {
                            ref.read(boxSearchQueryProvider.notifier).state =
                                value;
                          }
                        },
                        onSubmitted: (value) {
                          if (onSearchChanged == null) {
                            ref.read(boxSearchQueryProvider.notifier).state =
                                value;
                          }
                          context.go(AppRoutes.home);
                        },
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
                            color: AppColors.textSecondary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailingAction != null) ...[
                        trailingAction!,
                        const SizedBox(width: 8),
                      ],
                      if (user != null && onNotificationsTap != null) ...[
                        _HeaderBellButton(
                          unreadCount: unreadCount,
                          onTap: onNotificationsTap!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (user != null &&
                          (user.role == UserRole.partner ||
                              user.role == UserRole.admin)) ...[
                        _RoleQuickButton(user: user, ref: ref, isKk: isKk),
                        const SizedBox(width: 8),
                      ],
                      Material(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: () {
                            if (user == null) {
                              context.push(AppRoutes.auth);
                            } else {
                              context.go(AppRoutes.profile);
                            }
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            child: Text(
                              user == null
                                  ? l10n.actionLogin
                                  : user.name.trim().split(' ').first,
                              style: AppTextStyles.label14.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.orders),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            isKk ? 'Тапсырыстарым' : 'Мои заказы',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '  ·  ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.lavenderChip,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          final next = isKk ? AppLanguage.ru : AppLanguage.kk;
                          ref.read(localeProvider.notifier).setLanguage(next);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isKk ? 'Қазақша' : 'Русский',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.background,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.background,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBellButton extends StatelessWidget {
  const _HeaderBellButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.raisedIndigo,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.background,
                size: 20,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 2,
            top: 2,
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
    );
  }
}

class _RoleQuickButton extends StatelessWidget {
  const _RoleQuickButton({
    required this.user,
    required this.ref,
    required this.isKk,
  });

  final dynamic user;
  final WidgetRef ref;
  final bool isKk;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == UserRole.admin;
    final label = isAdmin
        ? (isKk ? 'Әкімші' : 'Админ')
        : (isKk ? 'Дүкен' : 'Заведение');
    return Material(
      color: AppColors.raisedIndigo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () async {
          final targetMode = isAdmin ? AppMode.admin : AppMode.venue;
          await ref.read(activeAppModeProvider.notifier).setMode(targetMode);
          if (context.mounted) {
            context.go(
              isAdmin ? AppRoutes.adminDashboard : AppRoutes.venueToday,
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}
