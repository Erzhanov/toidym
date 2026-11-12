import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/halal_cert_image.dart';

/// Админ-экран жалоб, управления 3-Strikes / банами, журнала AuditLogs и всех заказов.
class AdminComplaintsScreen extends ConsumerWidget {
  const AdminComplaintsScreen({super.key});

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} $hh:$mm';
  }

  Future<void> _runSafeAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showResolveDialog(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final l10n = context.l10n;
    final noteCtrl = TextEditingController(
      text: 'Провели проверку с магазином, спасибо за обращение.',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminComplaintResolve),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.adminComplaintResolutionHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (confirmed != true || !context.mounted) return;

    await _runSafeAction(context, () async {
      final actorEmail =
          ref.read(currentUserProvider)?.email ?? 'admin@toidym.kz';
      await ref.read(orderRepositoryProvider).resolveComplaint(
            orderId: order.id,
            status: ComplaintStatus.resolved,
            resolutionNote: note,
          );
      await ref.read(auditLogRepositoryProvider).recordAction(
            actorEmail: actorEmail,
            action: 'RESOLVE_COMPLAINT',
            targetType: 'ORDER',
            targetId: order.id,
            details: note,
          );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orders = ref.watch(allPlatformOrdersProvider);
    final venuesMap = ref.watch(venuesMapProvider);
    final users = ref.watch(allUsersProvider);
    final auditLogs = ref.watch(auditLogsProvider);
    final actorEmail =
        ref.read(currentUserProvider)?.email ?? 'admin@toidym.kz';

    final complaints =
        orders.where((o) => o.complaintSubmitted).toList(growable: false);
    final buyerUsers = users
        .where((u) => u.role == UserRole.buyer)
        .toList()
      ..sort((a, b) => b.strikesCount.compareTo(a.strikesCount));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          title: Text(
            l10n.screenAdminComplaintsTitle,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.navInactive,
            tabs: [
              Tab(text: '${l10n.adminComplaintsTab} (${complaints.length})'),
              Tab(text: '${l10n.adminStrikesTab} (${buyerUsers.length})'),
              Tab(text: '${l10n.adminAuditTab} (${auditLogs.length})'),
              Tab(text: '${l10n.adminAllOrdersTab} (${orders.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Жалобы
            complaints.isEmpty
                ? EmptyState(
                    title: l10n.adminNoComplaintsTitle,
                    subtitle: l10n.adminNoComplaintsSubtitle,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: complaints.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final order = complaints[index];
                      final venue = venuesMap[order.venueId];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${order.orderNumber} · ${venue?.name ?? order.venueId}',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  AppBadge(
                                    label: order.complaintStatus.label(l10n),
                                    tone: order.complaintStatus.isOpen
                                        ? AppBadgeTone.error
                                        : AppBadgeTone.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                order.complaintNote ?? '',
                                style: AppTextStyles.bodyLarge,
                              ),
                              if (order.complaintPhotoPaths.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: 240,
                                  child: HalalCertImage(
                                    source: order.complaintPhotoPaths.first,
                                    height: 140,
                                  ),
                                ),
                              ],
                              if (order.complaintResolutionNote != null &&
                                  order.complaintResolutionNote!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  order.complaintResolutionNote!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.successText,
                                  ),
                                ),
                              ],
                              if (order.complaintStatus.isOpen) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    if (order.complaintStatus ==
                                        ComplaintStatus.open)
                                      OutlinedButton(
                                        onPressed: () => _runSafeAction(
                                          context,
                                          () async {
                                            await ref
                                                .read(orderRepositoryProvider)
                                                .resolveComplaint(
                                                  orderId: order.id,
                                                  status:
                                                      ComplaintStatus.inReview,
                                                  resolutionNote: l10n
                                                      .adminComplaintStatusInReview,
                                                );
                                            await ref
                                                .read(
                                                  auditLogRepositoryProvider,
                                                )
                                                .recordAction(
                                                  actorEmail: actorEmail,
                                                  action:
                                                      'TAKE_COMPLAINT_REVIEW',
                                                  targetType: 'ORDER',
                                                  targetId: order.id,
                                                  details: 'Moved to inReview',
                                                );
                                          },
                                        ),
                                        child: Text(
                                          l10n.adminComplaintTakeInReview,
                                        ),
                                      ),
                                    FilledButton(
                                      onPressed: () => _showResolveDialog(
                                        context,
                                        ref,
                                        order,
                                      ),
                                      child: Text(l10n.adminComplaintResolve),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            // 2. Strikes и Баны пользователей
            ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: buyerUsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final buyer = buyerUsers[index];
                return Card(
                  color: buyer.isBanned ? AppColors.errorLight : null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${buyer.name} · ${buyer.email}',
                                style: AppTextStyles.titleMedium,
                              ),
                            ),
                            AppBadge(
                              label:
                                  l10n.adminUserStrikesBadge(buyer.strikesCount),
                              tone: buyer.isBanned
                                  ? AppBadgeTone.error
                                  : (buyer.strikesCount > 0
                                      ? AppBadgeTone.warning
                                      : AppBadgeTone.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(buyer.phone, style: AppTextStyles.caption),
                        if (buyer.isBanned && buyer.bannedUntil != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.profileBannedUntil(
                              _formatDateTime(buyer.bannedUntil!),
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.errorText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (buyer.strikesCount > 0 || buyer.isBanned) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            children: [
                              if (buyer.strikesCount > 0)
                                OutlinedButton.icon(
                                  onPressed: () => _runSafeAction(
                                    context,
                                    () async {
                                      await ref
                                          .read(authRepositoryProvider)
                                          .removeStrike(buyer.id);
                                      await ref
                                          .read(auditLogRepositoryProvider)
                                          .recordAction(
                                            actorEmail: actorEmail,
                                            action: 'REMOVE_STRIKE',
                                            targetType: 'USER',
                                            targetId: buyer.id,
                                            details:
                                                'Removed 1 strike from ${buyer.email}',
                                          );
                                    },
                                  ),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l10n.adminRemoveStrike),
                                ),
                              if (buyer.isBanned)
                                FilledButton.icon(
                                  onPressed: () => _runSafeAction(
                                    context,
                                    () async {
                                      await ref
                                          .read(authRepositoryProvider)
                                          .unbanUser(buyer.id);
                                      await ref
                                          .read(auditLogRepositoryProvider)
                                          .recordAction(
                                            actorEmail: actorEmail,
                                            action: 'UNBAN_USER',
                                            targetType: 'USER',
                                            targetId: buyer.id,
                                            details: 'Unbanned ${buyer.email}',
                                          );
                                    },
                                  ),
                                  icon: const Icon(
                                    Icons.lock_open_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l10n.adminUnbanUser),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // 3. Журнал аудита (AuditLogs)
            auditLogs.isEmpty
                ? EmptyState(
                    title: l10n.adminAuditEmpty,
                    subtitle: l10n.adminAuditTab,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: auditLogs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final entry = auditLogs[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(
                              Icons.history_edu_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            '${entry.action} · ${entry.targetType}:${entry.targetId}',
                            style: AppTextStyles.bodyLargeMedium,
                          ),
                          subtitle: Text(
                            '${entry.actorEmail}\n${entry.details}',
                            style: AppTextStyles.caption,
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            _formatDateTime(entry.createdAt),
                            style: AppTextStyles.caption,
                          ),
                        ),
                      );
                    },
                  ),

            // 4. Все заказы
            ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final order = orders[index];
                final venue = venuesMap[order.venueId];
                final isErr = order.status == OrderStatus.cancelledByUser ||
                    order.status == OrderStatus.cancelledByVenue ||
                    order.status == OrderStatus.noShow;
                return Card(
                  child: ListTile(
                    title: Text(
                      '${order.orderNumber} · ${venue?.name ?? order.venueId}',
                      style: AppTextStyles.bodyLargeMedium,
                    ),
                    subtitle: Text(
                      '${order.paymentMethod.label(l10n)} · PIN ${order.formattedPin}',
                      style: AppTextStyles.caption,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.formatPrice(order.totalPrice),
                          style: AppTextStyles.bodyLargeMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AppBadge(
                          label: order.status.label(l10n),
                          tone: isErr
                              ? AppBadgeTone.error
                              : (order.status.isActive
                                  ? AppBadgeTone.success
                                  : AppBadgeTone.neutral),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
