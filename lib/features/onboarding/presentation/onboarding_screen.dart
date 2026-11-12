import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

/// Онбординг покупателя (Figma 02 · Онбординг 1–3).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _nextOrFinish() async {
    if (_pageIndex < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  List<_Slide> _slides(bool isKk) {
    if (isKk) {
      return const [
        _Slide(
          title: 'Тағамды сақта —\n70% дейін үнемде',
          subtitle:
              'Астананың кафе мен наубайханалары күннің соңғы жаңа өнімдерін тосынсый бокстарында ұсынады.',
          image: 'assets/images/onboarding_1.png',
        ),
        _Slide(
          title: 'Жақын маңнан\nбокс таңдаңыз',
          subtitle:
              'Картадан немесе тізімнен мекемені тауып, өзіңізге ыңғайлы уақыт терезесін брондаңыз.',
          image: 'assets/images/onboarding_2.png',
        ),
        _Slide(
          title: 'Өзіңіз келіп\nкүтусіз алыңыз',
          subtitle:
              'Кассада QR-кодты көрсетіңіз. Жеткізусіз — тағам да сақталады, бағасы да тиімді.',
          image: 'assets/images/food_waffles.png',
        ),
      ];
    }
    return const [
      _Slide(
        title: 'Спасай еду —\nэкономь до 70%',
        subtitle:
            'Кафе и пекарни Астаны продают свежие остатки дня в боксах-сюрпризах.',
        image: 'assets/images/onboarding_1.png',
      ),
      _Slide(
        title: 'Выбирай боксы\nрядом с собой',
        subtitle:
            'Смотрите предложения на карте или списком и бронируйте удобное время самовывоза.',
        image: 'assets/images/onboarding_2.png',
      ),
      _Slide(
        title: 'Забирай вечером\nбез ожидания',
        subtitle:
            'Покажите QR или код на кассе в указанное окно. Без доставки и лишних сборов.',
        image: 'assets/images/food_waffles.png',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage.fromCode(ref.watch(localeProvider).languageCode);
    final isKk = lang == AppLanguage.kk;
    final slides = _slides(isKk);
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1020),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ToidymCard(
                padding: EdgeInsets.zero,
                borderRadius: 32,
                child: SizedBox(
                  height: 580,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(32),
                          ),
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) =>
                                setState(() => _pageIndex = i),
                            itemCount: slides.length,
                            itemBuilder: (_, index) => Image.asset(
                              slides[index].image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(36, 28, 36, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const ToidymLogo(
                                    darkText: true,
                                    height: 36,
                                  ),
                                  _LanguagePill(
                                    lang: lang,
                                    onChanged: (next) => ref
                                        .read(localeProvider.notifier)
                                        .setLanguage(next),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                slides[_pageIndex].title,
                                style: AppTextStyles.displayHero.copyWith(
                                  fontSize: 34,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                slides[_pageIndex].subtitle,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _PillDots(
                                count: slides.length,
                                active: _pageIndex,
                                onTap: (i) => _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                ),
                              ),
                              const Spacer(),
                              PrimaryButton(
                                label: _pageIndex < 2
                                    ? (isKk ? 'Келесі' : 'Далее')
                                    : (isKk ? 'Бастау' : 'Начать'),
                                onPressed: _nextOrFinish,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: _finish,
                                  child: Text(
                                    isKk ? 'Өткізіп жіберу' : 'Пропустить',
                                    style: AppTextStyles.button.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.sheet),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemCount: slides.length,
                      itemBuilder: (_, index) => Image.asset(
                        slides[index].image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  right: 16,
                  child: _LanguagePill(
                    lang: lang,
                    onChanged: (next) =>
                        ref.read(localeProvider.notifier).setLanguage(next),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 32).clamp(0, 1200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slides[_pageIndex].title,
                                style: AppTextStyles.displayHero.copyWith(
                                  fontSize: 34,
                                  height: 38 / 34,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                slides[_pageIndex].subtitle,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PillDots(
                                count: slides.length,
                                active: _pageIndex,
                                onTap: (i) => _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                PrimaryButton(
                                  label: _pageIndex < 2
                                      ? (isKk ? 'Келесі' : 'Далее')
                                      : (isKk ? 'Бастау' : 'Начать'),
                                  onPressed: _nextOrFinish,
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: TextButton(
                                    onPressed: _finish,
                                    child: Text(
                                      isKk ? 'Өткізіп жіберу' : 'Пропустить',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.image,
  });

  final String title;
  final String subtitle;
  final String image;
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.lang, required this.onChanged});

  final AppLanguage lang;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangTab(
            label: 'Қаз',
            active: lang == AppLanguage.kk,
            onTap: () => onChanged(AppLanguage.kk),
          ),
          _LangTab(
            label: 'Рус',
            active: lang == AppLanguage.ru,
            onTap: () => onChanged(AppLanguage.ru),
          ),
        ],
      ),
    );
  }
}

class _LangTab extends StatelessWidget {
  const _LangTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label14.copyWith(
              color: active ? AppColors.background : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillDots extends StatelessWidget {
  const _PillDots({
    required this.count,
    required this.active,
    required this.onTap,
  });

  final int count;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: i == active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == active ? AppColors.primary : AppColors.lavenderChip,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
