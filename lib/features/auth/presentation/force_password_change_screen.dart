import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_routes.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/network/api_client.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/input_formatters.dart';
import 'package:toidym/data/repositories/mock_auth_repository.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';

/// Обязательный экран смены временного пароля при первом входе партнёра (`isFirstLogin == true`).
class ForcePasswordChangeScreen extends ConsumerStatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  ConsumerState<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState
    extends ConsumerState<ForcePasswordChangeScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final newPass = _passwordController.text;
    final confirm = _confirmController.text;

    if (!AuthValidators.isStrongPassword(newPass)) {
      setState(() => _errorText = l10n.authErrWeakPassword);
      return;
    }
    if (newPass != confirm) {
      setState(() => _errorText = l10n.authErrPasswordMismatch);
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);
    final modeNotifier = ref.read(activeAppModeProvider.notifier);
    final router = GoRouter.of(context);

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await authRepo.changeTemporaryPassword(newPass);
      await modeNotifier.setMode(AppMode.venue);
      if (!mounted) return;
      router.go(AppRoutes.venueToday);
    } catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        ApiException(:final message) => message,
        AuthException() => l10n.authErrWeakPassword,
        _ => l10n.stateErrorTitle,
      };
      setState(() {
        _isSaving = false;
        _errorText = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.forcePassTitle),
        actions: [
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: QumbekMascot(
                      mood: QumbekMood.happy,
                      size: 84,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.forcePassTitle,
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.forcePassSubtitle,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user.email,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.forcePassNewLabel,
                      helperText: l10n.authPasswordHint,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.authConfirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      errorText: _errorText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: l10n.forcePassSaveButton,
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
