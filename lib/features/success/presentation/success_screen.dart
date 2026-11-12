import 'package:confetti/confetti.dart';
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
import 'package:toidym/core/utils/widget_share_helper.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

/// Эмоциональный финальный экран «Ас болсын!» с конфетти, Құмбеком, оценкой и «Қызыл кітап».
class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  late final ConfettiController _confettiController;
  int _rating = 5;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    )..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _finish(Order? order) async {
    if (order != null && _rating > 0) {
      setState(() => _isSaving = true);
      final user = ref.read(currentUserProvider);
      await ref.read(venueRepositoryProvider).addReview(
            Review(
              id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
              orderId: order.id,
              userId: order.userId,
              venueId: order.venueId,
              authorName: user?.name ?? 'Покупатель',
              rating: _rating,
              tags: _selectedTags.toList(growable: false),
              comment: _commentController.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _showStoryPreview(int savedMoney) {
    final l10n = context.l10n;
    final boundaryKey = GlobalKey();
    final caption =
        '${l10n.brandPhrase} ${l10n.successSavedSubtitle(AppFormatters.formatPrice(savedMoney))} #toidym';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.successStoriesTitle),
        content: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: AppRadius.cardBorderRadius,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const QumbekMascot(size: 100, mood: QumbekMood.happy),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.brandPhrase,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.successSavedSubtitle(
                    AppFormatters.formatPrice(savedMoney),
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PrimaryButton(
            label: l10n.actionShare,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final shared = await WidgetShareHelper.shareBoundaryAsPng(
                boundaryKey: boundaryKey,
                text: caption,
                fileName: 'toidym_as_bolsyn.png',
              );
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    shared ? l10n.shareImageReady : l10n.successStoriesSaved,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final orders = ref.watch(ordersStreamProvider).valueOrNull ?? const [];
    final order = orders.cast<Order?>().firstWhere(
          (o) => o?.id == widget.orderId,
          orElse: () => null,
        );
    final savedAmount = order?.savedAmount ?? 1980;
    final boxesSaved = user?.stats.boxesSaved ?? 14;
    final nextAnimal =
        user?.qyzylKitap.currentAnimal.nextAnimal ?? QyzylKitapAnimal.irbis;
    final targetBoxes = nextAnimal.requiredBoxes;
    final leftToNext = (targetBoxes - boxesSaved).clamp(0, targetBoxes);
    final progressRatio =
        targetBoxes > 0 ? (boxesSaved / targetBoxes).clamp(0.0, 1.0) : 1.0;

    final tags = [
      l10n.successTagTasty,
      l10n.successTagPlenty,
      l10n.successTagFresh,
      l10n.successTagPolite,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: PrimaryButton(
                label: l10n.actionDone,
                isLoading: _isSaving,
                onPressed: () => _finish(order),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              ToidymDarkHeader(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    const ToidymLogo(height: 28),
                    const SizedBox(height: AppSpacing.md),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.7, end: 1.0),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: const QumbekMascot(
                        size: 120,
                        mood: QumbekMood.happy,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.brandPhrase,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.successSavedSubtitle(
                        AppFormatters.formatPrice(savedAmount),
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                // Прогресс «Қызыл кітап»
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.qyzylKitapTitle,
                              style: AppTextStyles.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progressRatio),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return ClipRRect(
                              borderRadius: AppRadius.badgeBorderRadius,
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 12,
                                backgroundColor: AppColors.surfaceVariant,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          leftToNext == 0
                              ? l10n.qyzylKitapAllUnlocked
                              : l10n.qyzylKitapProgress(
                                  boxesSaved,
                                  targetBoxes,
                                  leftToNext,
                                  nextAnimal.label(l10n),
                                ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Оценка 1–5 звёзд и быстрые метки
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.successRateTitle,
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            final active = starValue <= _rating;
                            return IconButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _rating = starValue);
                              },
                              constraints: const BoxConstraints(
                                minWidth: AppSpacing.minTouchTarget,
                                minHeight: AppSpacing.minTouchTarget,
                              ),
                              icon: Icon(
                                active
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 36,
                                color: active
                                    ? AppColors.accentDark
                                    : AppColors.textSecondary,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final tag in tags)
                              ToidymChip(
                                label: tag,
                                selected: _selectedTags.contains(tag),
                                onTap: () {
                                  setState(() {
                                    if (_selectedTags.contains(tag)) {
                                      _selectedTags.remove(tag);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: l10n.successCommentHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SecondaryButton(
                  label: l10n.successShareStories,
                  icon: Icons.auto_stories_rounded,
                  onPressed: () => _showStoryPreview(savedAmount),
                ),
                  ],
                ),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 24,
            colors: const [
              AppColors.primary,
              AppColors.accent,
              AppColors.success,
              AppColors.warning,
            ],
          ),
        ],
      ),
    );
  }
}
