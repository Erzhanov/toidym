import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/input_formatters.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/halal_cert_image.dart';

enum _VenueFilter { all, pending, approved, rejected, banned }

/// Админ-экран управления магазинами: одобрение заявок с временным паролем, добавление партнёров, бан и Халал-контроль.
class AdminVenuesScreen extends ConsumerStatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  ConsumerState<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends ConsumerState<AdminVenuesScreen> {
  _VenueFilter _filter = _VenueFilter.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _actorEmail =>
      ref.read(currentUserProvider)?.email ?? 'admin@toidym.kz';

  Future<void> _runAdminAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showTempPasswordDialog(PartnerProvisionResult result) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminAddPartnerButton),
        content: SelectableText(
          l10n.adminTempPasswordCreated(
            result.temporaryPassword,
            result.partnerUser.email,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.temporaryPassword));
              Navigator.pop(ctx);
            },
            child: Text(l10n.actionDone),
          ),
        ],
      ),
    );
  }

  Future<void> _approveLead(Venue venue) async {
    await _runAdminAction(() async {
      final venueRepo = ref.read(venueRepositoryProvider);
      final auditRepo = ref.read(auditLogRepositoryProvider);
      final users = ref.read(allUsersProvider);
      final existingEmail = users
          .where((u) => u.managedVenueId == venue.id)
          .map((u) => u.email)
          .firstOrNull;
      final commentEmail =
          (venue.rejectionComment?.startsWith('Email: ') ?? false)
              ? venue.rejectionComment!.replaceFirst('Email: ', '').trim()
              : null;
      final email = (commentEmail != null && commentEmail.isNotEmpty)
          ? commentEmail
          : (existingEmail ?? 'partner_${venue.id}@toidym.kz');

      final result = await venueRepo.approvePartnerLead(
        venueId: venue.id,
        email: email,
      );
      await auditRepo.recordAction(
        actorEmail: _actorEmail,
        action: 'APPROVE_PARTNER_LEAD',
        targetType: 'VENUE',
        targetId: venue.id,
        details: 'Approved ${venue.name} ($email)',
      );
      if (!mounted) return;
      await _showTempPasswordDialog(result);
    });
  }

  Future<void> _showAddPartnerDialog() async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+7 (701) ');
    final addrCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    var district = AstanaDistrict.esil;
    var category = VenueCategory.bakery;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.adminAddPartnerButton),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.venueNameLabel),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: phoneCtrl,
                  inputFormatters: [KzPhoneMaskFormatter()],
                  decoration: InputDecoration(labelText: l10n.venuePhoneLabel),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: addrCtrl,
                  decoration: InputDecoration(labelText: l10n.venueAddressLabel),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.partnerLeadEmailLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<AstanaDistrict>(
                  initialValue: district,
                  decoration: InputDecoration(labelText: l10n.adminTableColDistrict),
                  items: [
                    for (final d in AstanaDistrict.values)
                      DropdownMenuItem(value: d, child: Text(d.label(l10n))),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => district = v);
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<VenueCategory>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: l10n.categoryAll),
                  items: [
                    for (final c in VenueCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.label(l10n))),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
              ],
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
      ),
    );

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final address = addrCtrl.text.trim();
    final email = emailCtrl.text.trim();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addrCtrl.dispose();
    emailCtrl.dispose();

    if (confirmed != true || name.isEmpty || email.isEmpty) return;

    await _runAdminAction(() async {
      final venueRepo = ref.read(venueRepositoryProvider);
      final auditRepo = ref.read(auditLogRepositoryProvider);

      final result = await venueRepo.createPartnerByAdmin(
        name: name,
        phone: phone,
        address: address,
        email: email,
        district: district,
        category: category,
      );
      await auditRepo.recordAction(
        actorEmail: _actorEmail,
        action: 'CREATE_PARTNER',
        targetType: 'VENUE',
        targetId: result.venue.id,
        details: 'Created partner $name ($email)',
      );
      if (!mounted) return;
      await _showTempPasswordDialog(result);
    });
  }

  Future<void> _showRejectDialog(Venue venue) async {
    final l10n = context.l10n;
    final commentCtrl = TextEditingController(
      text: venue.rejectionComment ?? '',
    );
    final fields = <String>{...venue.rejectionFields};
    if (fields.isEmpty) {
      fields.add('halalCert');
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.adminRejectVenue),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (final field in const [
                      'photo',
                      'halalCert',
                      'address',
                      'requisites',
                    ])
                      FilterChip(
                        label: Text(field),
                        selected: fields.contains(field),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              fields.add(field);
                            } else {
                              fields.remove(field);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: commentCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.adminRejectReasonHint,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.adminRejectVenue),
              ),
            ],
          );
        },
      ),
    );
    final comment = commentCtrl.text.trim();
    commentCtrl.dispose();
    if (confirmed != true) return;

    await _runAdminAction(() async {
      final venueRepo = ref.read(venueRepositoryProvider);
      final auditRepo = ref.read(auditLogRepositoryProvider);
      await venueRepo.setDemoVenueStatus(
        venueId: venue.id,
        status: VenueStatus.rejected,
        rejectionComment: comment,
        rejectionFields: fields.toList(growable: false),
      );
      await auditRepo.recordAction(
        actorEmail: _actorEmail,
        action: 'REJECT_VENUE',
        targetType: 'VENUE',
        targetId: venue.id,
        details: comment.isEmpty ? 'Marked rejected' : comment,
      );
    });
  }

  Future<void> _banVenue(Venue venue) async {
    final l10n = context.l10n;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminBanVenue),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(hintText: l10n.adminRejectReasonHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminBanVenue),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (confirmed != true) return;

    await _runAdminAction(() async {
      final venueRepo = ref.read(venueRepositoryProvider);
      final auditRepo = ref.read(auditLogRepositoryProvider);
      await venueRepo.banVenue(
        venueId: venue.id,
        reason: reason.isEmpty ? l10n.venueStatusBanned : reason,
      );
      await auditRepo.recordAction(
        actorEmail: _actorEmail,
        action: 'BAN_VENUE',
        targetType: 'VENUE',
        targetId: venue.id,
        details: reason.isEmpty ? 'Venue banned' : reason,
      );
    });
  }

  Future<void> _unbanVenue(Venue venue) async {
    await _runAdminAction(() async {
      final venueRepo = ref.read(venueRepositoryProvider);
      final auditRepo = ref.read(auditLogRepositoryProvider);
      await venueRepo.unbanVenue(venue.id);
      await auditRepo.recordAction(
        actorEmail: _actorEmail,
        action: 'UNBAN_VENUE',
        targetType: 'VENUE',
        targetId: venue.id,
        details: 'Venue unbanned',
      );
    });
  }

  Future<void> _moderateHalal(Venue venue, HalalCertStatus status) async {
    await _runAdminAction(() async {
      final venueRepo = ref.read(venueRepositoryProvider);
      final auditRepo = ref.read(auditLogRepositoryProvider);
      await venueRepo.updateHalalCertStatus(
        venueId: venue.id,
        halalCertStatus: status,
        halalCertNumber: venue.halalCertNumber,
        halalCertPhoto: venue.resolvedHalalCertPhoto,
      );
      await auditRepo.recordAction(
        actorEmail: _actorEmail,
        action: status == HalalCertStatus.verified
            ? 'VERIFY_HALAL'
            : 'REJECT_HALAL',
        targetType: 'VENUE',
        targetId: venue.id,
        details: 'Halal -> ${status.apiValue}',
      );
    });
  }

  Future<void> _showHalalPhotoDialog(Venue venue) async {
    final photo = venue.resolvedHalalCertPhoto;
    if (photo == null || photo.isEmpty) return;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${venue.name} · Халал'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 440),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: HalalCertImage(
              source: photo,
              height: 360,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Жабу / Закрыть'),
          ),
          if (venue.halalCertStatus == HalalCertStatus.pending) ...[
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _moderateHalal(venue, HalalCertStatus.rejected);
              },
              child: Text(l10n.adminRejectHalal),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _moderateHalal(venue, HalalCertStatus.verified);
              },
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text(l10n.adminVerifyHalal),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venues = ref.watch(venuesStreamProvider).valueOrNull ?? const [];
    final allOrders = ref.watch(allPlatformOrdersProvider);
    final query = _searchController.text.trim().toLowerCase();
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    final filtered = venues.where((v) {
      final matchesFilter = switch (_filter) {
        _VenueFilter.all => true,
        _VenueFilter.pending => v.status == VenueStatus.pending ||
            v.halalCertStatus == HalalCertStatus.pending,
        _VenueFilter.approved => v.status == VenueStatus.approved,
        _VenueFilter.rejected => v.status == VenueStatus.rejected,
        _VenueFilter.banned => v.status == VenueStatus.banned,
      };
      if (!matchesFilter) return false;
      if (query.isNotEmpty) {
        return v.name.toLowerCase().contains(query) ||
            v.address.toLowerCase().contains(query);
      }
      return true;
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenAdminVenuesTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: _showAddPartnerDialog,
              icon: const Icon(Icons.add_business_rounded, size: 18),
              label: Text(l10n.adminAddPartnerButton),
            ),
          ),
        ],
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
                  for (final item in _VenueFilter.values) ...[
                    ChoiceChip(
                      label: Text(switch (item) {
                        _VenueFilter.all => l10n.adminFilterAll,
                        _VenueFilter.pending => l10n.adminFilterPending,
                        _VenueFilter.approved => l10n.adminFilterApproved,
                        _VenueFilter.rejected => l10n.adminFilterRejected,
                        _VenueFilter.banned => l10n.adminFilterBanned,
                      }),
                      selected: _filter == item,
                      onSelected: (_) => setState(() => _filter = item),
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
                  : isWide
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: PaginatedDataTable(
                            rowsPerPage: filtered.length.clamp(1, 8),
                            columns: [
                              DataColumn(label: Text(l10n.adminTableColVenue)),
                              DataColumn(
                                label: Text(l10n.adminTableColDistrict),
                              ),
                              DataColumn(label: Text(l10n.adminTableColStatus)),
                              DataColumn(label: Text(l10n.adminTableColHalal)),
                              DataColumn(label: Text(l10n.adminTableColStats)),
                              DataColumn(
                                label: Text(l10n.adminTableColActions),
                              ),
                            ],
                            source: _VenuesDataTableSource(
                              context: context,
                              venues: filtered,
                              allOrders: allOrders,
                              onApproveLead: _approveLead,
                              onReject: _showRejectDialog,
                              onBan: _banVenue,
                              onUnban: _unbanVenue,
                              onModerateHalal: _moderateHalal,
                              onViewHalalPhoto: _showHalalPhotoDialog,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final venue = filtered[index];
                            final vOrders = allOrders
                                .where((o) => o.venueId == venue.id)
                                .toList(growable: false);
                            final completedCnt = vOrders
                                .where((o) => o.status == OrderStatus.completed)
                                .length;
                            final noShowCnt = vOrders
                                .where((o) => o.status == OrderStatus.noShow)
                                .length;

                            final statusTone = switch (venue.status) {
                              VenueStatus.approved => AppBadgeTone.success,
                              VenueStatus.pending => AppBadgeTone.warning,
                              VenueStatus.rejected ||
                              VenueStatus.banned =>
                                AppBadgeTone.error,
                            };
                            final halalTone = switch (venue.halalCertStatus) {
                              HalalCertStatus.verified => AppBadgeTone.halal,
                              HalalCertStatus.pending => AppBadgeTone.warning,
                              HalalCertStatus.rejected => AppBadgeTone.error,
                              HalalCertStatus.none => AppBadgeTone.neutral,
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
                                            venue.name,
                                            style: AppTextStyles.titleMedium,
                                          ),
                                        ),
                                        AppBadge(
                                          label: venue.status.label(l10n),
                                          tone: statusTone,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      '${venue.district.label(l10n)} · ${venue.address} · ${venue.phone}',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        AppBadge(
                                          label:
                                              venue.halalCertStatus.label(l10n),
                                          tone: halalTone,
                                        ),
                                        AppBadge(
                                          label: l10n.adminVenueCompletedCount(
                                            completedCnt,
                                          ),
                                          tone: AppBadgeTone.primary,
                                        ),
                                        AppBadge(
                                          label: l10n.adminVenueNoShowCount(
                                            noShowCnt,
                                          ),
                                          tone: noShowCnt > 0
                                              ? AppBadgeTone.error
                                              : AppBadgeTone.neutral,
                                        ),
                                      ],
                                    ),
                                    if (venue.rejectionComment != null &&
                                        venue.rejectionComment!.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        venue.rejectionComment!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.errorText,
                                        ),
                                      ),
                                    ],
                                    if (venue.resolvedHalalCertPhoto !=
                                        null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      InkWell(
                                        onTap: () =>
                                            _showHalalPhotoDialog(venue),
                                        borderRadius:
                                            AppRadius.cardBorderRadius,
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            HalalCertImage(
                                              source: venue
                                                  .resolvedHalalCertPhoto!,
                                              height: 140,
                                            ),
                                            Container(
                                              margin: const EdgeInsets.all(
                                                AppSpacing.xs,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: AppSpacing.xxs,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    AppRadius.chipBorderRadius,
                                              ),
                                              child: Text(
                                                'Фото Халал · үлкейту / увеличить',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        if (venue.status != VenueStatus.approved &&
                                            venue.status != VenueStatus.banned)
                                          FilledButton.icon(
                                            onPressed: () =>
                                                _approveLead(venue),
                                            icon: const Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                            ),
                                            label: Text(l10n.adminApproveVenue),
                                          ),
                                        if (venue.status == VenueStatus.pending)
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showRejectDialog(venue),
                                            icon: const Icon(
                                              Icons.edit_note_rounded,
                                              size: 18,
                                            ),
                                            label: Text(l10n.adminRejectVenue),
                                          ),
                                        if (venue.status == VenueStatus.banned)
                                          FilledButton.icon(
                                            onPressed: () => _unbanVenue(venue),
                                            icon: const Icon(
                                              Icons.lock_open_rounded,
                                              size: 18,
                                            ),
                                            label: Text(l10n.adminUnbanVenue),
                                          )
                                        else
                                          OutlinedButton.icon(
                                            onPressed: () => _banVenue(venue),
                                            icon: const Icon(
                                              Icons.block_rounded,
                                              size: 18,
                                            ),
                                            label: Text(l10n.adminBanVenue),
                                          ),
                                        if (venue.halalCertStatus ==
                                            HalalCertStatus.pending) ...[
                                          FilledButton.tonalIcon(
                                            onPressed: () => _moderateHalal(
                                              venue,
                                              HalalCertStatus.verified,
                                            ),
                                            icon: const Icon(
                                              Icons.verified_rounded,
                                              size: 18,
                                            ),
                                            label: Text(l10n.adminVerifyHalal),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => _moderateHalal(
                                              venue,
                                              HalalCertStatus.rejected,
                                            ),
                                            child: Text(l10n.adminRejectHalal),
                                          ),
                                        ],
                                      ],
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

class _VenuesDataTableSource extends DataTableSource {
  _VenuesDataTableSource({
    required this.context,
    required this.venues,
    required this.allOrders,
    required this.onApproveLead,
    required this.onReject,
    required this.onBan,
    required this.onUnban,
    required this.onModerateHalal,
    required this.onViewHalalPhoto,
  });

  final BuildContext context;
  final List<Venue> venues;
  final List<Order> allOrders;
  final ValueChanged<Venue> onApproveLead;
  final ValueChanged<Venue> onReject;
  final ValueChanged<Venue> onBan;
  final ValueChanged<Venue> onUnban;
  final void Function(Venue, HalalCertStatus) onModerateHalal;
  final ValueChanged<Venue> onViewHalalPhoto;

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= venues.length) return null;
    final l10n = context.l10n;
    final venue = venues[index];
    final vOrders = allOrders.where((o) => o.venueId == venue.id);
    final completedCnt =
        vOrders.where((o) => o.status == OrderStatus.completed).length;
    final noShowCnt =
        vOrders.where((o) => o.status == OrderStatus.noShow).length;

    return DataRow(
      cells: [
        DataCell(Text('${venue.name}\n${venue.address}')),
        DataCell(Text(venue.district.label(l10n))),
        DataCell(Text(venue.status.label(l10n))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(venue.halalCertStatus.label(l10n)),
              if (venue.resolvedHalalCertPhoto != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: 'Фото Халал',
                  onPressed: () => onViewHalalPhoto(venue),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                ),
              ],
            ],
          ),
        ),
        DataCell(Text('$completedCnt / $noShowCnt')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (venue.status != VenueStatus.approved &&
                  venue.status != VenueStatus.banned)
                IconButton(
                  tooltip: l10n.adminApproveVenue,
                  onPressed: () => onApproveLead(venue),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                ),
              if (venue.status == VenueStatus.pending)
                IconButton(
                  tooltip: l10n.adminRejectVenue,
                  onPressed: () => onReject(venue),
                  icon: const Icon(Icons.edit_note_rounded),
                ),
              if (venue.status == VenueStatus.banned)
                IconButton(
                  tooltip: l10n.adminUnbanVenue,
                  onPressed: () => onUnban(venue),
                  icon: const Icon(Icons.lock_open_rounded),
                )
              else
                IconButton(
                  tooltip: l10n.adminBanVenue,
                  onPressed: () => onBan(venue),
                  icon: const Icon(Icons.block_rounded, color: AppColors.error),
                ),
              if (venue.halalCertStatus == HalalCertStatus.pending) ...[
                IconButton(
                  tooltip: l10n.adminVerifyHalal,
                  onPressed: () =>
                      onModerateHalal(venue, HalalCertStatus.verified),
                  icon: const Icon(Icons.verified_rounded),
                ),
                IconButton(
                  tooltip: l10n.adminRejectHalal,
                  onPressed: () =>
                      onModerateHalal(venue, HalalCertStatus.rejected),
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => venues.length;

  @override
  int get selectedRowCount => 0;
}
