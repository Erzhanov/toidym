import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/empty_state.dart';

/// Админ-каталог всех боксов платформы: модерация, скрытие/восстановление позиций и аудит.
class AdminBoxesScreen extends ConsumerStatefulWidget {
  const AdminBoxesScreen({super.key});

  @override
  ConsumerState<AdminBoxesScreen> createState() => _AdminBoxesScreenState();
}

class _AdminBoxesScreenState extends ConsumerState<AdminBoxesScreen> {
  final _searchController = TextEditingController();
  BoxStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final boxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];
    final venuesMap = ref.watch(venuesMapProvider);
    final query = _searchController.text.trim().toLowerCase();
    final actorEmail =
        ref.read(currentUserProvider)?.email ?? 'admin@toidym.kz';

    final filtered = boxes.where((b) {
      if (_statusFilter != null && b.status != _statusFilter) return false;
      if (query.isNotEmpty) {
        final venueName = venuesMap[b.venueId]?.name.toLowerCase() ?? '';
        if (!b.title.toLowerCase().contains(query) &&
            !venueName.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.screenAdminBoxesTitle,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.homeSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  ChoiceChip(
                    label: Text(l10n.adminFilterAll),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  for (final status in BoxStatus.values) ...[
                    ChoiceChip(
                      label: Text(status.label(l10n)),
                      selected: _statusFilter == status,
                      onSelected: (_) =>
                          setState(() => _statusFilter = status),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      title: l10n.stateEmptyBoxesTitle,
                      subtitle: l10n.stateEmptyBoxesSubtitle,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final box = filtered[index];
                        final venue = venuesMap[box.venueId];
                        final tone = switch (box.status) {
                          BoxStatus.active => AppBadgeTone.success,
                          BoxStatus.soldOut ||
                          BoxStatus.expired =>
                            AppBadgeTone.neutral,
                          BoxStatus.disabled => AppBadgeTone.error,
                        };

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        box.title,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                    ),
                                    AppBadge(
                                      label: box.status.label(l10n),
                                      tone: tone,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${venue?.name ?? box.venueId} · ${box.category.label(l10n)} · ${box.pickupWindow.formatted}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    AppBadge(
                                      label: AppFormatters.formatDiscount(
                                        box.discountPercent,
                                      ),
                                      tone: AppBadgeTone.accent,
                                    ),
                                    AppBadge(
                                      label: AppFormatters.formatPrice(
                                        box.discountPrice,
                                      ),
                                      tone: AppBadgeTone.primary,
                                    ),
                                    AppBadge(
                                      label: l10n.badgeLeftCount(
                                        box.quantityLeft,
                                      ),
                                      tone: AppBadgeTone.neutral,
                                    ),
                                    if (box.isHalal)
                                      AppBadge(
                                        label: l10n.badgeHalal,
                                        tone: AppBadgeTone.halal,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final boxRepo =
                                            ref.read(boxRepositoryProvider);
                                        final auditRepo = ref
                                            .read(auditLogRepositoryProvider);
                                        final nextStatus =
                                            box.status == BoxStatus.disabled
                                                ? BoxStatus.active
                                                : BoxStatus.disabled;
                                        await boxRepo.toggleBoxStatus(
                                          boxId: box.id,
                                          status: nextStatus,
                                        );
                                        await auditRepo.recordAction(
                                          actorEmail: actorEmail,
                                          action:
                                              nextStatus == BoxStatus.disabled
                                                  ? 'HIDE_BOX'
                                                  : 'RESTORE_BOX',
                                          targetType: 'BOX',
                                          targetId: box.id,
                                          details:
                                              '${box.title} -> ${nextStatus.apiValue}',
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      box.status == BoxStatus.disabled
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      box.status == BoxStatus.disabled
                                          ? l10n.adminRestoreBox
                                          : l10n.adminHideBox,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
