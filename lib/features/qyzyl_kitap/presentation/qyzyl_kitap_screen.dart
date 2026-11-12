import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/widget_share_helper.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';

/// Коллекция «Қызыл кітап»: Құмбек -> Ирбис (15) -> Сайгак (30) -> Тюлень (50).
class QyzylKitapScreen extends ConsumerStatefulWidget {
  const QyzylKitapScreen({super.key});

  @override
  ConsumerState<QyzylKitapScreen> createState() => _QyzylKitapScreenState();
}

class _QyzylKitapScreenState extends ConsumerState<QyzylKitapScreen> {
  final _shareBoundaryKey = GlobalKey();

  Future<void> _shareCollection(
    int boxesSaved,
    QyzylKitapAnimal currentAnimal,
  ) async {
    final l10n = context.l10n;
    final caption =
        '${l10n.qyzylKitapTitle}: ${currentAnimal.label(l10n)} · $boxesSaved #toidym';
    final shared = await WidgetShareHelper.shareBoundaryAsPng(
      boundaryKey: _shareBoundaryKey,
      text: caption,
      fileName: 'toidym_qyzyl_kitap.png',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shared ? l10n.shareImageReady : l10n.shareImageFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final boxesSaved = user?.stats.boxesSaved ?? 0;
    final currentAnimal =
        user?.qyzylKitap.currentAnimal ?? QyzylKitapAnimal.qumbek;
    final nextAnimal = currentAnimal.nextAnimal;
    final target = nextAnimal?.requiredBoxes ?? 50;
    final ratio = (boxesSaved / target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenQyzylKitapTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionShare,
            onPressed: () => _shareCollection(boxesSaved, currentAnimal),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            RepaintBoundary(
              key: _shareBoundaryKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          QyzylKitapAnimalArt(
                            animal: currentAnimal,
                            isUnlocked: true,
                            size: 64,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.qyzylKitapTitle,
                                  style: AppTextStyles.headlineMedium,
                                ),
                                Text(
                                  currentAnimal.label(l10n),
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
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
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        nextAnimal == null
                            ? l10n.qyzylKitapAllUnlocked
                            : l10n.qyzylKitapProgress(
                                boxesSaved,
                                target,
                                (target - boxesSaved).clamp(0, target),
                                nextAnimal.label(l10n),
                              ),
                        style: AppTextStyles.bodyLargeMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.qyzylKitapNoMoneyNote,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: QyzylKitapAnimal.values.length,
              itemBuilder: (context, index) {
                final animal = QyzylKitapAnimal.values[index];
                final isUnlocked = boxesSaved >= animal.requiredBoxes;
                final remaining =
                    (animal.requiredBoxes - boxesSaved).clamp(0, 999);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QyzylKitapAnimalArt(
                          animal: animal,
                          isUnlocked: isUnlocked,
                          size: 96,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          animal.label(l10n),
                          style: AppTextStyles.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppBadge(
                          label: isUnlocked
                              ? l10n.qyzylKitapUnlocked
                              : l10n.qyzylKitapLockedLeft(remaining),
                          tone: isUnlocked
                              ? AppBadgeTone.success
                              : AppBadgeTone.neutral,
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
