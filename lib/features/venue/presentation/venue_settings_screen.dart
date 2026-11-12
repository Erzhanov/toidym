import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/halal_photo_picker.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/halal_cert_image.dart';
import 'package:toidym/shared/widgets/primary_button.dart';

/// Настройки заведения: данные, часы работы, сотрудники (кассиры) и поддержка.
class VenueSettingsScreen extends ConsumerStatefulWidget {
  const VenueSettingsScreen({super.key});

  @override
  ConsumerState<VenueSettingsScreen> createState() =>
      _VenueSettingsScreenState();
}

class _VenueSettingsScreenState extends ConsumerState<VenueSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;
  bool _isSubmittingHalal = false;
  String? _selectedHalalPhoto;
  List<VenueStaffMember> _staff = const [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff(String venueId) async {
    try {
      final staff = await ref.read(venueRepositoryProvider).getStaff(venueId);
      if (!mounted) return;
      setState(() => _staff = staff);
    } catch (_) {
      // Seed/demo venues may have no staff records on remote server yet.
    }
  }

  Future<void> _saveSettings(Venue venue) async {
    setState(() => _isSaving = true);
    try {
      final updated = venue.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await ref.read(venueRepositoryProvider).updateVenueSettings(updated);
      ref.invalidate(venuesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionSave)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showAddCashierDialog(String venueId) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+7 (701) ');
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.venueSettingsAddCashier),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.venueSettingsCashierName,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.authPhoneLabel),
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
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (created != true || name.isEmpty) return;

    try {
      await ref.read(venueRepositoryProvider).addCashier(
            venueId: venueId,
            name: name,
            phone: phone,
          );
      await _loadStaff(venueId);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venueId = ref.watch(managedVenueIdProvider);
    final venue = ref.watch(venuesMapProvider)[venueId];

    if (venue != null && !_initialized) {
      _initialized = true;
      _nameController.text = venue.name;
      _addressController.text = venue.address;
      _phoneController.text = venue.phone;
      _selectedHalalPhoto = venue.resolvedHalalCertPhoto;
      _loadStaff(venue.id);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenVenueSettingsTitle)),
      body: SafeArea(
        child: venue == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                key: const ValueKey('venue_settings_list'),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.venueNameLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: l10n.venueAddressLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: l10n.venuePhoneLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text(l10n.venueSettingsWorkHours),
                      subtitle: Text(venue.workHours.formatted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: l10n.actionSave,
                    isLoading: _isSaving,
                    onPressed: () => _saveSettings(venue),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Builder(
                        builder: (context) {
                          final isKk =
                              Localizations.localeOf(context).languageCode ==
                                  'kk';
                          final previewPhoto =
                              _selectedHalalPhoto ??
                              venue.resolvedHalalCertPhoto;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.badgeHalal}: ${venue.halalCertStatus.label(l10n)}',
                                style: AppTextStyles.bodyLargeMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                isKk
                                    ? 'Сертификат нөмірін жазудың қажеті жоқ — Халал сертификатының фотосын түсіріп немесе жүктеп жіберіңіз.'
                                    : 'Номер вводить не нужно — достаточно сфотографировать или загрузить фото Халал-сертификата.',
                                style: AppTextStyles.caption,
                              ),
                              if (previewPhoto != null &&
                                  previewPhoto.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                HalalCertImage(
                                  source: previewPhoto,
                                  height: 190,
                                  fit: BoxFit.contain,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _isSubmittingHalal
                                        ? null
                                        : () async {
                                            final picked =
                                                await pickHalalCertPhoto(
                                              useCamera: true,
                                            );
                                            if (!mounted || picked == null) {
                                              return;
                                            }
                                            setState(
                                              () => _selectedHalalPhoto =
                                                  picked,
                                            );
                                          },
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: Text(
                                      isKk
                                          ? 'Суретке түсіру'
                                          : 'Сфотографировать',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _isSubmittingHalal
                                        ? null
                                        : () async {
                                            final picked =
                                                await pickHalalCertPhoto(
                                              useCamera: false,
                                            );
                                            if (!mounted || picked == null) {
                                              return;
                                            }
                                            setState(
                                              () => _selectedHalalPhoto =
                                                  picked,
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: Text(
                                      isKk ? 'Фото таңдау' : 'Выбрать фото',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FilledButton.icon(
                                onPressed: _isSubmittingHalal ||
                                        previewPhoto == null ||
                                        previewPhoto.isEmpty
                                    ? null
                                    : () async {
                                        setState(
                                          () => _isSubmittingHalal = true,
                                        );
                                        try {
                                          await ref
                                              .read(venueRepositoryProvider)
                                              .updateHalalCertStatus(
                                                venueId: venue.id,
                                                halalCertStatus:
                                                    HalalCertStatus.pending,
                                                halalCertPhoto: previewPhoto,
                                              );
                                          ref.invalidate(venuesProvider);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isKk
                                                    ? 'Сертификат фотосы тексеруге жіберілді'
                                                    : 'Фото сертификата отправлено на проверку',
                                              ),
                                            ),
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
                                        } finally {
                                          if (mounted) {
                                            setState(
                                              () => _isSubmittingHalal = false,
                                            );
                                          }
                                        }
                                      },
                                icon: _isSubmittingHalal
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.verified_outlined),
                                label: Text(l10n.venueSettingsSubmitHalal),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.venueSettingsStaff,
                        style: AppTextStyles.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddCashierDialog(venue.id),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(l10n.venueSettingsAddCashier),
                      ),
                    ],
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final member in _staff)
                          ListTile(
                            leading: const Icon(Icons.badge_outlined),
                            title: Text(member.name),
                            subtitle: Text(member.phone),
                            trailing: Text(
                              member.role == UserRole.partner
                                  ? l10n.profileRoleOwner
                                  : l10n.profileRoleCashier,
                              style: AppTextStyles.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.support_agent_rounded),
                      title: Text(l10n.venueSettingsSupport),
                      subtitle: Text(l10n.venueSettingsSupportText),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final authRepo = ref.read(authRepositoryProvider);
                      final modeNotifier =
                          ref.read(activeAppModeProvider.notifier);
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
    );
  }
}
