import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/widgets/app_badge.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/primary_button.dart';

/// Экран выдачи заказов для владельца и кассира: QR-сканер + Custom Numpad (без системной клавиатуры) + WAV-сигналы.
class VenuePickupScreen extends ConsumerStatefulWidget {
  const VenuePickupScreen({super.key});

  @override
  ConsumerState<VenuePickupScreen> createState() => _VenuePickupScreenState();
}

class _VenuePickupScreenState extends ConsumerState<VenuePickupScreen> {
  String _enteredPin = '';
  bool _isBusy = false;
  bool _scannerOpen = false;
  bool _errorFlash = false;
  bool _successFlash = false;
  String? _errorText;
  String? _successText;
  AudioPlayer? _audioPlayer;

  @override
  void dispose() {
    unawaited(_audioPlayer?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _playFeedbackSound({required bool success}) async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.stop();
      await _audioPlayer!.play(
        AssetSource(
          success ? 'audio/success_beep.wav' : 'audio/error_buzzer.wav',
        ),
      );
    } catch (_) {
      // В headless/web-окружении без разрешённого аудиопотока используется только тактильная/визуальная индикация.
    }
  }

  void _appendDigit(String digit) {
    if (_isBusy || _enteredPin.length >= 4) return;
    HapticFeedback.selectionClick();
    final next = '$_enteredPin$digit';
    setState(() {
      _enteredPin = next;
      _errorFlash = false;
      _errorText = null;
    });
    if (next.length == 4) {
      unawaited(_completePickup(pinCode: next));
    }
  }

  void _backspacePin() {
    if (_isBusy || _enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorFlash = false;
      _errorText = null;
    });
  }

  void _clearPin() {
    if (_isBusy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = '';
      _errorFlash = false;
      _errorText = null;
    });
  }

  Future<void> _completePickup({String? qrCode, String? pinCode}) async {
    final l10n = context.l10n;
    final venueId = ref.read(managedVenueIdProvider);
    final orderRepo = ref.read(orderRepositoryProvider);

    setState(() {
      _isBusy = true;
      _errorFlash = false;
      _successFlash = false;
      _errorText = null;
      _successText = null;
    });

    try {
      final result = await orderRepo.completePickup(
        venueId: venueId,
        qrCode: qrCode,
        pinCode: pinCode,
      );
      HapticFeedback.heavyImpact();
      unawaited(_playFeedbackSound(success: true));
      if (!mounted) return;
      final successMsg = l10n.venuePickupSuccess(result.order.orderNumber);
      setState(() {
        _isBusy = false;
        _scannerOpen = false;
        _enteredPin = '';
        _successFlash = true;
        _successText = successMsg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
    } catch (_) {
      HapticFeedback.vibrate();
      unawaited(_playFeedbackSound(success: false));
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _enteredPin = '';
        _errorFlash = true;
        _errorText = l10n.venuePickupPinWrong;
      });
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController(text: 'Закончилась позиция');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.venuePickupCancelTitle),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: l10n.venuePickupCancelReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionCancel),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    await ref.read(orderRepositoryProvider).cancelOrderByVenue(
          orderId: order.id,
          reason: reason,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final pendingOrders = ref.watch(venuePendingOrdersProvider);
    final boxes = ref.watch(allBoxesStreamProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: _errorFlash ? AppColors.errorLight : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.screenVenuePickupTitle,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        actions: [
          if (user?.isCashierOnly ?? false)
            IconButton(
              tooltip: l10n.actionLogout,
              onPressed: () async {
                final authRepo = ref.read(authRepositoryProvider);
                final modeNotifier = ref.read(activeAppModeProvider.notifier);
                final router = GoRouter.of(context);
                await modeNotifier.setMode(AppMode.buyer);
                await authRepo.logout();
                if (!mounted) return;
                router.go(AppRoutes.home);
              },
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            108,
          ),
          children: [
            // Рамка сканера QR + фолбэк для эмулятора без камеры
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Container(
                      height: 156,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: AppRadius.cardBorderRadius,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _scannerOpen
                          ? MobileScanner(
                              onDetect: (capture) {
                                final code =
                                    capture.barcodes.firstOrNull?.rawValue;
                                if (code != null && !_isBusy) {
                                  _completePickup(qrCode: code);
                                }
                              },
                              errorBuilder: (_, _) => _ScannerPlaceholder(
                                hint: l10n.venuePickupScannerHint,
                              ),
                            )
                          : InkWell(
                              onTap: () => setState(() => _scannerOpen = true),
                              child: _ScannerPlaceholder(
                                hint: l10n.venuePickupScannerHint,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Кастомный Numpad (без системной клавиатуры)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _errorFlash
                    ? AppColors.errorLight
                    : (_successFlash
                        ? AppColors.successLight
                        : AppColors.surface),
                borderRadius: AppRadius.cardBorderRadius,
                border: Border.all(
                  color: _errorFlash
                      ? AppColors.error
                      : (_successFlash ? AppColors.success : AppColors.border),
                  width: _errorFlash || _successFlash ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.venuePickupEnterPinTitle,
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (idx) {
                      final hasChar = idx < _enteredPin.length;
                      final char = hasChar ? _enteredPin[idx] : '•';
                      return Container(
                        width: 52,
                        height: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.inputBorderRadius,
                          border: Border.all(
                            color: _errorFlash
                                ? AppColors.error
                                : (hasChar
                                    ? AppColors.primary
                                    : AppColors.border),
                            width: hasChar || _errorFlash ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          char,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: _errorFlash
                                ? AppColors.error
                                : (hasChar
                                    ? AppColors.primary
                                    : AppColors.textSecondary),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.errorText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_successText != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _successText!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.successText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _CustomNumpadGrid(
                    isBusy: _isBusy,
                    clearLabel: l10n.venuePickupClear,
                    onDigit: _appendDigit,
                    onClear: _clearPin,
                    onBackspace: _backspacePin,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: l10n.venuePickupGiveButton,
                    isLoading: _isBusy,
                    onPressed: _enteredPin.length == 4
                        ? () => _completePickup(pinCode: _enteredPin)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              '${l10n.venuePickupWaitingTitle} (${pendingOrders.length})',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (pendingOrders.isEmpty)
              EmptyState(
                title: l10n.venuePickupEmptyWaiting,
                subtitle: l10n.venueQumbekTip,
              )
            else
              for (final order in pendingOrders) ...[
                () {
                  final box = boxes.cast<Box?>().firstWhere(
                        (b) => b?.id == order.boxId,
                        orElse: () => null,
                      );
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: AppTextStyles.titleMedium,
                              ),
                              AppBadge(
                                label: order.status.label(l10n),
                                tone: AppBadgeTone.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${box?.title ?? ''} · ×${order.quantity}',
                            style: AppTextStyles.bodyLargeMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${AppFormatters.formatPrice(order.totalPrice)} (${l10n.paymentOnSite}) · PIN ${order.formattedPin}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _cancelOrder(order),
                                  child: Text(l10n.actionCancel),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _completePickup(pinCode: order.pinCode),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                  ),
                                  child: Text(l10n.venuePickupGiveButton),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }(),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _CustomNumpadGrid extends StatelessWidget {
  const _CustomNumpadGrid({
    required this.isBusy,
    required this.clearLabel,
    required this.onDigit,
    required this.onClear,
    required this.onBackspace,
  });

  final bool isBusy;
  final String clearLabel;
  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final digit in row) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilledButton.tonal(
                      key: ValueKey('numpad_digit_$digit'),
                      onPressed: isBusy ? null : () => onDigit(digit),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      child: Text(
                        digit,
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: OutlinedButton(
                  key: const ValueKey('numpad_clear'),
                  onPressed: isBusy ? null : onClear,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(clearLabel, style: AppTextStyles.caption),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FilledButton.tonal(
                  key: const ValueKey('numpad_digit_0'),
                  onPressed: isBusy ? null : () => onDigit('0'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('0', style: AppTextStyles.titleLarge),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: OutlinedButton(
                  key: const ValueKey('numpad_backspace'),
                  onPressed: isBusy ? null : onBackspace,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Icon(Icons.backspace_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accent, width: 3),
            borderRadius: AppRadius.cardBorderRadius,
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 46,
            color: AppColors.accent,
          ),
        ),
        Positioned(
          bottom: AppSpacing.sm,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
