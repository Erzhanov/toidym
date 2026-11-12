import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/box_template.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/venue.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/box_card.dart';
import 'package:toidym/shared/widgets/primary_button.dart';

/// Создание нового бокса с шаблонами `BoxTemplate` (публикация в 1 клик) и проверкой бизнес-правил.
class VenueNewBoxScreen extends ConsumerStatefulWidget {
  const VenueNewBoxScreen({super.key});

  @override
  ConsumerState<VenueNewBoxScreen> createState() => _VenueNewBoxScreenState();
}

class _VenueNewBoxScreenState extends ConsumerState<VenueNewBoxScreen> {
  final _titleController = TextEditingController(text: 'Вечерний сет выпечки');
  final _descController =
      TextEditingController(text: 'Круассаны, слойки и свежая сдоба дня');
  final _originalPriceController = TextEditingController(text: '2400');
  final _discountPriceController = TextEditingController(text: '990');

  BoxType _type = BoxType.surprise;
  BoxCategory _category = BoxCategory.bakery;
  int _quantity = 5;
  bool _markHalal = true;
  bool _isVegetarian = false;
  bool _saveAsTemplate = false;
  BoxTemplate? _appliedTemplate;
  final Set<int> _repeatWeekdays = {1, 2, 3, 4, 5};
  final Set<String> _allergens = {'Глютен', 'Молочные продукты'};
  bool _isPublishing = false;
  bool _windowInitialized = false;
  List<BusinessRuleViolation> _violations = const [];
  String? _publishError;

  late DateTime _windowStart;
  late DateTime _windowEnd;

  static const _presetPhotos = [
    'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800',
  ];
  int _selectedPhotoIdx = 0;

  static const _allAllergens = [
    'Глютен',
    'Молочные продукты',
    'Яйца',
    'Орехи',
    'Кунжут',
  ];

  static const _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final candidateHour = now.hour + 3;
    final DateTime defaultStart;
    if (candidateHour <= 21) {
      defaultStart = DateTime(now.year, now.month, now.day, candidateHour, 0);
    } else {
      final tomorrow = now.add(const Duration(days: 1));
      defaultStart =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
    }
    _windowStart = defaultStart;
    _windowEnd = defaultStart.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _originalPriceController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }

  int get _originalPrice =>
      int.tryParse(_originalPriceController.text.trim()) ?? 0;
  int get _discountPrice =>
      int.tryParse(_discountPriceController.text.trim()) ?? 0;

  int get _discountPercent => BoxBusinessRules.calculateDiscountPercent(
        originalPrice: _originalPrice,
        discountPrice: _discountPrice,
      );

  void _applyTemplate(BoxTemplate template, Venue venue) {
    final l10n = context.l10n;
    final halalAllowed = BoxBusinessRules.canUseHalalBadge(venue);
    setState(() {
      _appliedTemplate = template;
      _titleController.text = template.name;
      _descController.text = template.description;
      _category = template.category;
      _type = template.type;
      _originalPriceController.text = '${template.originalPrice}';
      _discountPriceController.text = '${template.discountPrice}';
      _markHalal = template.isHalal && halalAllowed;
      _isVegetarian = template.isVegetarian;
      _allergens
        ..clear()
        ..addAll(template.allergens);
      final photoIdx = _presetPhotos.indexOf(template.imageUrl);
      if (photoIdx >= 0) _selectedPhotoIdx = photoIdx;
      _violations = const [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.venueTemplateApplied(template.name))),
    );
  }

  Box _buildDraftBox(Venue venue) {
    return Box(
      id: 'preview_box',
      venueId: venue.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      type: _type,
      category: _category,
      originalPrice: _originalPrice,
      discountPrice: _discountPrice,
      discountPercent: _discountPercent,
      quantity: _quantity,
      quantityLeft: _quantity,
      pickupWindow: PickupWindow(start: _windowStart, end: _windowEnd),
      isHalal: _markHalal && BoxBusinessRules.canUseHalalBadge(venue),
      isVegetarian: _isVegetarian,
      allergens: _allergens.toList(growable: false),
      status: BoxStatus.active,
      createdAt: DateTime.now(),
      photos: [_presetPhotos[_selectedPhotoIdx]],
      repeatWeekdays: _repeatWeekdays.toList(growable: false),
    );
  }

  void _showPreview(Venue venue) {
    final draft = _buildDraftBox(venue);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        child: BoxCard(
          box: draft,
          venue: venue,
          distanceKm: 0.9,
          isFavorite: false,
          onTap: () {},
          onToggleFavorite: () {},
        ),
      ),
    );
  }

  Future<void> _publish(Venue venue) async {
    final halalAllowed = BoxBusinessRules.canUseHalalBadge(venue);
    final violations = BoxBusinessRules.validateNewBox(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      originalPrice: _originalPrice,
      discountPrice: _discountPrice,
      quantity: _quantity,
      pickupWindow: PickupWindow(start: _windowStart, end: _windowEnd),
      venue: venue,
      markAsHalal: halalAllowed && _markHalal,
    );

    if (violations.isNotEmpty) {
      setState(() {
        _violations = violations;
        _publishError = null;
      });
      return;
    }

    final boxRepo = ref.read(boxRepositoryProvider);
    setState(() {
      _isPublishing = true;
      _violations = const [];
      _publishError = null;
    });

    try {
      final template = _appliedTemplate;
      if (template != null &&
          template.name == _titleController.text.trim() &&
          template.originalPrice == _originalPrice) {
        await boxRepo.publishFromTemplate(
          template: template,
          quantity: _quantity,
          pickupWindow: PickupWindow(start: _windowStart, end: _windowEnd),
        );
      } else {
        final draft = _buildDraftBox(venue).copyWith(id: '');
        await boxRepo.createBox(draft);
        if (_saveAsTemplate) {
          await boxRepo.createTemplate(
            BoxTemplate(
              id: '',
              venueId: venue.id,
              name: draft.title,
              description: draft.description,
              category: draft.category,
              type: draft.type,
              originalPrice: draft.originalPrice,
              discountPercent: draft.discountPercent,
              imageUrl: draft.photos.isNotEmpty
                  ? draft.photos.first
                  : _presetPhotos.first,
              allergens: draft.allergens,
              isHalal: draft.isHalal,
              isVegetarian: draft.isVegetarian,
            ),
          );
          ref.invalidate(venueTemplatesProvider);
        }
      }
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      context.pop();
    } on BusinessRuleException catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _violations = e.violations;
        _publishError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().trim();
      setState(() {
        _isPublishing = false;
        _publishError = message.isEmpty
            ? 'Не удалось опубликовать бокс. Попробуйте ещё раз.'
            : message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_publishError!),
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
    final templatesAsync = ref.watch(venueTemplatesProvider);

    if (venue == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.screenVenueNewBoxTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_windowInitialized) {
      _windowInitialized = true;
      final sprint = BoxBusinessRules.calculateSprintPickupWindow(venue);
      _windowStart = sprint.start;
      _windowEnd = sprint.end;
    }

    final halalAllowed = BoxBusinessRules.canUseHalalBadge(venue);
    final lowDiscount =
        _originalPrice > 0 && _discountPrice > 0 && _discountPercent < 50;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenVenueNewBoxTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Горизонтальная карусель шаблонов BoxTemplate
            templatesAsync.maybeWhen(
              data: (templates) {
                if (templates.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.venueTemplatesTitle,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: templates.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final tpl = templates[index];
                          final selected = _appliedTemplate?.id == tpl.id;
                          return InkWell(
                            borderRadius: AppRadius.cardBorderRadius,
                            onTap: () => _applyTemplate(tpl, venue),
                            child: Container(
                              width: 210,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                                borderRadius: AppRadius.cardBorderRadius,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tpl.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyLargeMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      AppBadge(
                                        label: '-${tpl.discountPercent}%',
                                        tone: AppBadgeTone.accent,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        AppFormatters.formatPrice(
                                          tpl.discountPrice,
                                        ),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Фото пресеты
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetPhotos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final selected = _selectedPhotoIdx == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedPhotoIdx = index),
                    borderRadius: AppRadius.inputBorderRadius,
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.inputBorderRadius,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _presetPhotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.photo_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.venueNewBoxTitleField,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.venueNewBoxType, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text(l10n.venueNewBoxSurprise),
                  selected: _type == BoxType.surprise,
                  onSelected: (_) => setState(() => _type = BoxType.surprise),
                ),
                ChoiceChip(
                  label: Text(l10n.venueNewBoxSet),
                  selected: _type == BoxType.set,
                  onSelected: (_) => setState(() => _type = BoxType.set),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final cat in BoxCategory.values)
                  ChoiceChip(
                    label: Text(cat.label(l10n)),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.venueNewBoxInside),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _originalPriceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.venueNewBoxOriginalPrice,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _discountPriceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.venueNewBoxDiscountPrice,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: lowDiscount
                    ? AppColors.warningLight
                    : AppColors.successLight,
                borderRadius: AppRadius.inputBorderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lowDiscount
                        ? l10n.venueNewBoxLowDiscountWarn
                        : l10n.venueNewBoxAutoDiscount(_discountPercent),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: lowDiscount
                          ? AppColors.warningText
                          : AppColors.successText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.venueNewBoxNoCommissionNote,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.venueNewBoxQuantity,
                    style: AppTextStyles.bodyLargeMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _quantity <= 1
                      ? null
                      : () => setState(() => _quantity--),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('$_quantity', style: AppTextStyles.titleMedium),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              color: AppColors.primaryLight.withValues(alpha: 0.45),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.venueNewBoxSprintTitle,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.venueNewBoxSprintSubtitle(
                              PickupWindow(
                                start: _windowStart,
                                end: _windowEnd,
                              ).formatted,
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(l10n.venueNewBoxRepeatDays, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              children: List.generate(7, (idx) {
                final weekday = idx + 1;
                final selected = _repeatWeekdays.contains(weekday);
                return FilterChip(
                  label: Text(_weekdayLabels[idx]),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _repeatWeekdays.add(weekday);
                      } else {
                        _repeatWeekdays.remove(weekday);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: AppSpacing.sm),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.badgeHalal),
              subtitle: halalAllowed
                  ? null
                  : Text(
                      l10n.venueNewBoxHalalNoCertHint,
                      style: AppTextStyles.caption,
                    ),
              value: halalAllowed && _markHalal,
              onChanged: halalAllowed
                  ? (v) => setState(() => _markHalal = v)
                  : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.venueNewBoxVegetarian),
              value: _isVegetarian,
              onChanged: (v) => setState(() => _isVegetarian = v),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.venueSaveAsTemplate),
              value: _saveAsTemplate,
              onChanged: (v) => setState(() => _saveAsTemplate = v ?? false),
            ),

            Text(l10n.venueNewBoxAllergens, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final allergen in _allAllergens)
                  FilterChip(
                    label: Text(allergen),
                    selected: _allergens.contains(allergen),
                    showCheckmark: false,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _allergens.add(allergen);
                        } else {
                          _allergens.remove(allergen);
                        }
                      });
                    },
                  ),
              ],
            ),

            if (_violations.isNotEmpty || _publishError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppRadius.inputBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_publishError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _publishError!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.errorText,
                          ),
                        ),
                      ),
                    for (final violation in _violations)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${violation.label(l10n)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.errorText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _showPreview(venue),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.venueNewBoxPreviewButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.venueNewBoxPublishButton,
              isLoading: _isPublishing,
              onPressed: () => _publish(venue),
            ),
          ],
        ),
      ),
    );
  }
}
