import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/input_formatters.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';

/// Лид-форма заявки на партнёрство (`/partner-apply`): отправляет данные в очередь модерации (PENDING).
class VenueOnboardingScreen extends ConsumerStatefulWidget {
  const VenueOnboardingScreen({super.key});

  @override
  ConsumerState<VenueOnboardingScreen> createState() =>
      _VenueOnboardingScreenState();
}

class _VenueOnboardingScreenState extends ConsumerState<VenueOnboardingScreen> {
  final _nameController = TextEditingController(text: 'Aqbiday Bakery');
  final _phoneController = TextEditingController(text: '+7 (777) 555-44-33');
  final _addressController = TextEditingController(text: 'ул. Сыганак, 29');
  final _emailController = TextEditingController(text: 'partner@aqbiday.kz');

  AstanaDistrict _district = AstanaDistrict.esil;
  VenueCategory _category = VenueCategory.bakery;
  bool _isSubmitting = false;
  String? _errorText;
  Venue? _submittedLead;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitLead() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      setState(() => _errorText = l10n.venueNameLabel);
      return;
    }
    if (!AuthValidators.isValidKzPhone(phone)) {
      setState(() => _errorText = l10n.authErrInvalidPhone);
      return;
    }
    if (!AuthValidators.isValidEmail(email)) {
      setState(() => _errorText = l10n.authErrInvalidEmail);
      return;
    }

    final venueRepo = ref.read(venueRepositoryProvider);
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final venue = await venueRepo.submitPartnerLead(
        name: name,
        phone: phone,
        address: address,
        email: email,
        district: _district,
        category: _category,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submittedLead = venue;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerLeadTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _submittedLead != null
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const QumbekMascot(
                              size: 88,
                              mood: QumbekMood.happy,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppBadge(
                              label: _submittedLead!.status.label(l10n),
                              tone: AppBadgeTone.warning,
                              large: true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.partnerLeadSuccessTitle,
                              style: AppTextStyles.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.partnerLeadSuccessBody,
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${_submittedLead!.name} · ${_emailController.text.trim()}',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            PrimaryButton(
                              label: l10n.actionDone,
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      const Center(
                        child: QumbekMascot(size: 72, mood: QumbekMood.tip),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.partnerLeadSubtitle,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        key: const ValueKey('lead_venue_name'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.venueNameLabel,
                          prefixIcon: const Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        key: const ValueKey('lead_venue_phone'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [KzPhoneMaskFormatter()],
                        decoration: InputDecoration(
                          labelText: l10n.venuePhoneLabel,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        key: const ValueKey('lead_venue_address'),
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: l10n.venueAddressLabel,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        key: const ValueKey('lead_venue_email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.partnerLeadEmailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.adminTableColDistrict,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final district in AstanaDistrict.values)
                            ChoiceChip(
                              label: Text(district.label(l10n)),
                              selected: _district == district,
                              onSelected: (_) =>
                                  setState(() => _district = district),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.categoryAll, style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final category in VenueCategory.values)
                            ChoiceChip(
                              label: Text(category.label(l10n)),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                        ],
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorText!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.errorText,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: l10n.venueSubmitApplication,
                        isLoading: _isSubmitting,
                        onPressed: _submitLead,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
