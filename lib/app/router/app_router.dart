import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/features/admin/presentation/admin_boxes_screen.dart';
import 'package:toidym/features/admin/presentation/admin_complaints_screen.dart';
import 'package:toidym/features/admin/presentation/admin_overview_screen.dart';
import 'package:toidym/features/admin/presentation/admin_venues_screen.dart';
import 'package:toidym/features/auth/presentation/auth_modal_screen.dart';
import 'package:toidym/features/auth/presentation/force_password_change_screen.dart';
import 'package:toidym/features/box_detail/presentation/box_detail_screen.dart';
import 'package:toidym/features/home/presentation/home_screen.dart';
import 'package:toidym/features/map/presentation/map_screen.dart';
import 'package:toidym/features/onboarding/presentation/onboarding_screen.dart';
import 'package:toidym/features/order/presentation/order_screen.dart';
import 'package:toidym/features/orders_history/presentation/orders_history_screen.dart';
import 'package:toidym/features/payment/presentation/payment_screen.dart';
import 'package:toidym/features/profile/presentation/profile_screen.dart';
import 'package:toidym/features/qyzyl_kitap/presentation/qyzyl_kitap_screen.dart';
import 'package:toidym/features/success/presentation/success_screen.dart';
import 'package:toidym/features/venue/presentation/venue_boxes_today_screen.dart';
import 'package:toidym/features/venue/presentation/venue_new_box_screen.dart';
import 'package:toidym/features/venue/presentation/venue_onboarding_screen.dart';
import 'package:toidym/features/venue/presentation/venue_pickup_screen.dart';
import 'package:toidym/features/venue/presentation/venue_settings_screen.dart';
import 'package:toidym/features/venue/presentation/venue_stats_screen.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/user.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref.listen<bool>(onboardingCompletedProvider, (_, _) => refreshNotifier.refresh());
  ref.listen<User?>(currentUserProvider, (_, _) => refreshNotifier.refresh());
  ref.listen<AppMode>(activeAppModeProvider, (_, _) => refreshNotifier.refresh());
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final onboardingDone = ref.read(onboardingCompletedProvider);
      final user = ref.read(currentUserProvider);
      final activeMode = ref.read(activeAppModeProvider);
      final location = state.matchedLocation;

      if (state.uri.path == '/' || state.uri.path.isEmpty) {
        return onboardingDone
            ? _defaultHomeFor(user, activeMode)
            : AppRoutes.onboarding;
      }

      // Принудительная смена временного пароля при первом входе PARTNER
      if (user != null &&
          user.role == UserRole.partner &&
          user.isFirstLogin) {
        if (location == AppRoutes.forcePasswordChange) {
          return null;
        }
        return AppRoutes.forcePasswordChange;
      }

      if (location == AppRoutes.forcePasswordChange &&
          (user == null || !user.isFirstLogin)) {
        return _defaultHomeFor(user, activeMode);
      }

      if (!onboardingDone) {
        if (location == AppRoutes.onboarding ||
            location == AppRoutes.partnerApply ||
            location == AppRoutes.auth) {
          return null;
        }
        return AppRoutes.onboarding;
      }

      if (location == AppRoutes.onboarding) {
        return _defaultHomeFor(user, activeMode);
      }

      if (location == AppRoutes.auth && user != null) {
        final nextParam = state.uri.queryParameters['next'];
        if (nextParam != null &&
            nextParam.isNotEmpty &&
            !nextParam.startsWith(AppRoutes.auth) &&
            user.role == UserRole.buyer) {
          return nextParam;
        }
        return _defaultHomeFor(user, activeMode);
      }

      if (user != null && user.isCashierOnly) {
        if (location != AppRoutes.venuePickup) {
          return AppRoutes.venuePickup;
        }
        return null;
      }

      final requiresAuth = _requiresAuth(location);
      if (requiresAuth && user == null) {
        return AppRoutes.authWithNext(state.uri.toString());
      }

      if (location.startsWith('/venue/')) {
        if (user == null) {
          return AppRoutes.authWithNext(state.uri.toString());
        }
        if (!user.canAccessVenueMode) {
          return AppRoutes.home;
        }
      }

      if (location.startsWith('/admin/')) {
        if (user == null) {
          return AppRoutes.authWithNext(state.uri.toString());
        }
        if (!user.canAccessAdminMode) {
          return AppRoutes.home;
        }
      }

      if (activeMode == AppMode.admin &&
          user != null &&
          user.canAccessAdminMode &&
          (_isBuyerShellRoute(location) || _isVenueShellRoute(location))) {
        return AppRoutes.adminDashboard;
      }

      if (activeMode == AppMode.venue &&
          user != null &&
          user.canAccessVenueMode &&
          (_isBuyerShellRoute(location) || _isAdminShellRoute(location))) {
        return user.isCashierOnly
            ? AppRoutes.venuePickup
            : AppRoutes.venueToday;
      }

      if (activeMode == AppMode.buyer &&
          (_isVenueShellRoute(location) || _isAdminShellRoute(location))) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: AuthModalScreen(
            nextLocation: state.uri.queryParameters['next'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.forcePasswordChange,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForcePasswordChangeScreen(),
      ),
      GoRoute(
        path: AppRoutes.partnerApply,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VenueOnboardingScreen(),
      ),

      // Покупатель: панель навигации (Боксы · Карта · Заказы · Профиль)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _BuyerShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Детальные маршруты покупателя
      GoRoute(
        path: AppRoutes.boxDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BoxDetailScreen(
          boxId: state.pathParameters['boxId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PaymentScreen(
          boxId: state.pathParameters['boxId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.order,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OrderScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.success,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SuccessScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.qyzylKitap,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QyzylKitapScreen(),
      ),

      // Магазин (заведение): панель навигации (Боксы · Выдача · Итоги)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _VenueShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.venueToday,
                builder: (context, state) => const VenueBoxesTodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.venuePickup,
                builder: (context, state) => const VenuePickupScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.venueStats,
                builder: (context, state) => const VenueStatsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Отдельные маршруты магазина
      GoRoute(
        path: AppRoutes.venueNewBox,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VenueNewBoxScreen(),
      ),
      GoRoute(
        path: AppRoutes.venueSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VenueSettingsScreen(),
      ),

      // Админ-панель: панель навигации (Сводка · Магазины · Боксы · Жалобы и Аудит)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AdminShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminDashboard,
                builder: (context, state) => const AdminOverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminVenues,
                builder: (context, state) => const AdminVenuesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminBoxes,
                builder: (context, state) => const AdminBoxesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminComplaints,
                builder: (context, state) => const AdminComplaintsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

bool _requiresAuth(String location) {
  return location.startsWith('/checkout') ||
      location == AppRoutes.orders ||
      location == AppRoutes.profile ||
      location.startsWith('/order/') ||
      location.startsWith('/success/') ||
      location == AppRoutes.qyzylKitap ||
      location == AppRoutes.forcePasswordChange ||
      location.startsWith('/admin/') ||
      location.startsWith('/venue/');
}

bool _isBuyerShellRoute(String location) {
  return location == AppRoutes.home ||
      location == AppRoutes.map ||
      location == AppRoutes.orders ||
      location == AppRoutes.profile;
}

bool _isVenueShellRoute(String location) {
  return location == AppRoutes.venueToday ||
      location == AppRoutes.venuePickup ||
      location == AppRoutes.venueStats;
}

bool _isAdminShellRoute(String location) {
  return location == AppRoutes.adminDashboard ||
      location == AppRoutes.adminVenues ||
      location == AppRoutes.adminBoxes ||
      location == AppRoutes.adminComplaints;
}

String _defaultHomeFor(User? user, AppMode mode) {
  if (user != null) {
    if (user.role == UserRole.partner && user.isFirstLogin) {
      return AppRoutes.forcePasswordChange;
    }
    if (user.role == UserRole.admin ||
        (mode == AppMode.admin && user.canAccessAdminMode)) {
      return AppRoutes.adminDashboard;
    }
    if (user.isCashierOnly) {
      return AppRoutes.venuePickup;
    }
    if (mode == AppMode.venue && user.canAccessVenueMode) {
      return AppRoutes.venueToday;
    }
  }
  return AppRoutes.home;
}

class _AdaptiveNavItem {
  const _AdaptiveNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.badgeColor = AppColors.primary,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final int badgeCount;
  final Color badgeColor;
}

/// Адаптивная оболочка: `NavigationBar` на узких экранах (< 960dp),
/// на десктопе: покупатель — чистый кремовый холст под верхним хедером (C01–C05),
/// партнёр и админ — боковая панель #2B2350 + верхняя панель (T02 / A13).
class _AdaptiveShellScaffold extends StatelessWidget {
  const _AdaptiveShellScaffold({
    required this.navigationShell,
    required this.items,
    this.hideNavigation = false,
    this.isBuyerShell = false,
    this.workspaceTitle = '',
    this.workspaceSubtitle = '',
    this.breadcrumb = '',
    this.roleBadge = '',
  });

  final StatefulNavigationShell navigationShell;
  final List<_AdaptiveNavItem> items;
  final bool hideNavigation;
  final bool isBuyerShell;
  final String workspaceTitle;
  final String workspaceSubtitle;
  final String breadcrumb;
  final String roleBadge;

  Widget _withBadge(Widget icon, _AdaptiveNavItem item) {
    if (item.badgeCount <= 0) return icon;
    return Badge(
      backgroundColor: item.badgeColor,
      textColor: AppColors.textOnPrimary,
      label: Text('${item.badgeCount}'),
      child: icon,
    );
  }

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hideNavigation) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 960;
    if (isWide && isBuyerShell) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
      );
    }

    if (isWide) {
      final sidebarWidth = width >= 1200 ? 224.0 : 188.0;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            Container(
              width: sidebarWidth,
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: ToidymLogo(height: 36),
                    ),
                    const SizedBox(height: 18),
                    if (workspaceTitle.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.sidebarActiveCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workspaceTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (workspaceSubtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                workspaceSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.navInactive,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _onSelect(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                if (i == navigationShell.currentIndex)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  const SizedBox(width: 17),
                                Expanded(
                                  child: Text(
                                    items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          i == navigationShell.currentIndex
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      color: i == navigationShell.currentIndex
                                          ? AppColors.accent
                                          : AppColors.textOnPrimary,
                                    ),
                                  ),
                                ),
                                if (items[i].badgeCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: items[i].badgeColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${items[i].badgeCount}',
                                      style: const TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (breadcrumb.isNotEmpty)
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            breadcrumb,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (roleBadge.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                roleBadge,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.navPill,
            borderRadius: BorderRadius.circular(36),
            boxShadow: AppColors.navShadows,
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 62,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: i == navigationShell.currentIndex
                                    ? AppColors.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                NavigationBar(
                  height: 62,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onSelect,
                  backgroundColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final item in items)
                      NavigationDestination(
                        icon: _withBadge(item.icon, item),
                        selectedIcon: _withBadge(item.selectedIcon, item),
                        label: item.label,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyerShellScaffold extends ConsumerWidget {
  const _BuyerShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activeCount = ref.watch(activeBuyerOrdersCountProvider);

    return _AdaptiveShellScaffold(
      navigationShell: navigationShell,
      isBuyerShell: true,
      items: [
        _AdaptiveNavItem(
          icon: const Icon(Icons.takeout_dining_outlined),
          selectedIcon: const Icon(Icons.takeout_dining_rounded),
          label: l10n.navBoxes,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map_rounded),
          label: l10n.navMap,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long_rounded),
          label: l10n.navOrders,
          badgeCount: activeCount,
          badgeColor: AppColors.primary,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: l10n.navProfile,
        ),
      ],
    );
  }
}

class _VenueShellScaffold extends ConsumerWidget {
  const _VenueShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final isCashierOnly = user?.isCashierOnly ?? false;
    final pendingCount = ref.watch(venuePendingOrdersCountProvider);

    return _AdaptiveShellScaffold(
      navigationShell: navigationShell,
      hideNavigation: isCashierOnly,
      workspaceTitle: user?.name ?? l10n.appName,
      workspaceSubtitle: isCashierOnly
          ? l10n.profileRoleCashier
          : l10n.profileRoleOwner,
      breadcrumb: 'toıdym / ${l10n.profileRoleOwner} / ${l10n.cityAstana}',
      roleBadge: isCashierOnly
          ? l10n.profileRoleCashier
          : l10n.profileRoleOwner,
      items: [
        _AdaptiveNavItem(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2_rounded),
          label: l10n.navVenueBoxes,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          selectedIcon: const Icon(Icons.qr_code_scanner_rounded),
          label: l10n.navVenuePickup,
          badgeCount: pendingCount,
          badgeColor: AppColors.warning,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: l10n.navVenueStats,
        ),
      ],
    );
  }
}

class _AdminShellScaffold extends ConsumerWidget {
  const _AdminShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pendingVenues = ref.watch(adminPendingVenuesCountProvider);
    final openComplaints = ref.watch(adminOpenComplaintsCountProvider);

    return _AdaptiveShellScaffold(
      navigationShell: navigationShell,
      workspaceTitle: l10n.profileRoleAdmin,
      workspaceSubtitle: l10n.cityAstana,
      breadcrumb: 'toıdym / ${l10n.profileRoleAdmin} / ${l10n.cityAstana}',
      roleBadge: l10n.profileRoleAdmin,
      items: [
        _AdaptiveNavItem(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard_rounded),
          label: l10n.navAdminOverview,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.store_outlined),
          selectedIcon: const Icon(Icons.store_rounded),
          label: l10n.navAdminVenues,
          badgeCount: pendingVenues,
          badgeColor: AppColors.warning,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2_rounded),
          label: l10n.navAdminBoxes,
        ),
        _AdaptiveNavItem(
          icon: const Icon(Icons.support_agent_outlined),
          selectedIcon: const Icon(Icons.support_agent_rounded),
          label: l10n.navAdminComplaints,
          badgeCount: openComplaints,
          badgeColor: AppColors.error,
        ),
      ],
    );
  }
}
