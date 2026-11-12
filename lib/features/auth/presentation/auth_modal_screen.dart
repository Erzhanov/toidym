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
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/data/repositories/mock_auth_repository.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/user.dart';
import 'package:toidym/shared/widgets/primary_button.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';
import 'package:toidym/shared/widgets/toidym_brand.dart';

/// Открывает модальный экран входа/регистрации (`Email + Пароль`).
/// Возвращает `true`, если пользователь успешно вошёл в аккаунт.
Future<bool> showAuthBottomSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        child: _AuthFlowBody(
          onAuthenticated: (_) => Navigator.of(sheetContext).pop(true),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Полноэкранная модалка авторизации для маршрута `/auth`.
class AuthModalScreen extends StatelessWidget {
  const AuthModalScreen({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    void handleAuthSuccess(User user) {
      if (user.role == UserRole.partner && user.isFirstLogin) {
        context.go(AppRoutes.forcePasswordChange);
        return;
      }
      if (user.role == UserRole.admin) {
        context.go(AppRoutes.adminDashboard);
        return;
      }
      if (user.role == UserRole.cashier) {
        context.go(AppRoutes.venuePickup);
        return;
      }
      if (user.role == UserRole.partner) {
        context.go(AppRoutes.venueToday);
        return;
      }
      final target = nextLocation;
      if (target != null && target.isNotEmpty) {
        context.go(target);
      } else {
        context.go(AppRoutes.home);
      }
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Левая тёмная индиго-панель бренда (#2B2350) из Design Toidym S01
            Expanded(
              flex: 4,
              child: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.all(40),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ToidymLogo(height: 44),
                      const SizedBox(height: 32),
                      Text(
                        l10n.brandSlogan,
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.brandPhrase,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.navInactive,
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Image.asset(
                          'assets/images/image0_93_2.png',
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: AppRadius.cardBorderRadius,
                        ),
                        child: Text(
                          l10n.onboardingLocationSubtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Правая кремовая панель формы (#FFF5DF)
            Expanded(
              flex: 5,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.home);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: Text(l10n.navBoxes),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: SingleChildScrollView(
                            child: _AuthFlowBody(
                              onAuthenticated: handleAuthSuccess,
                            ),
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(l10n.authLoginTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: _AuthFlowBody(
                onAuthenticated: handleAuthSuccess,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFlowBody extends ConsumerStatefulWidget {
  const _AuthFlowBody({required this.onAuthenticated});

  final void Function(User user) onAuthenticated;

  @override
  ConsumerState<_AuthFlowBody> createState() => _AuthFlowBodyState();
}

class _AuthFlowBodyState extends ConsumerState<_AuthFlowBody> {
  final _identifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmController = TextEditingController();

  bool _isRegisterTab = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _isLoading = false;
  String? _errorText;
  String? _infoText;

  @override
  void initState() {
    super.initState();
    // Предустановленные демо-данные заполняем только в локальном мок/тест-режиме.
    if (!ref.read(useBackendProvider)) {
      _identifierController.text = SeedData.demoUserEmail;
      _loginPasswordController.text = SeedData.demoUserPassword;
    }
  }

  void _clearFeedback() {
    if (_errorText != null || _infoText != null) {
      setState(() {
        _errorText = null;
        _infoText = null;
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmController.dispose();
    super.dispose();
  }

  String _mapAuthError(BuildContext context, Object error) {
    final l10n = context.l10n;
    if (error is ApiException) {
      return error.message;
    }
    if (error is AuthException) {
      return switch (error.code) {
        AuthErrorCode.invalidPhone => l10n.authErrInvalidPhone,
        AuthErrorCode.invalidEmail => l10n.authErrInvalidEmail,
        AuthErrorCode.weakPassword => l10n.authErrWeakPassword,
        AuthErrorCode.emailAlreadyExists => l10n.authErrEmailExists,
        AuthErrorCode.invalidCredentials => l10n.authErrInvalidCredentials,
        AuthErrorCode.emailNotVerified => l10n.authErrEmailNotVerified,
        AuthErrorCode.rateLimited => l10n.authErrRateLimited,
        AuthErrorCode.accountBanned => l10n.authErrAccountBanned,
      };
    }
    return error.toString();
  }

  Future<void> _completeAuthSuccess(User user) async {
    final authRepo = ref.read(authRepositoryProvider);
    final modeNotifier = ref.read(activeAppModeProvider.notifier);
    final onboardingNotifier = ref.read(onboardingCompletedProvider.notifier);
    final dietaryPrefs = ref.read(dietaryPreferencesProvider);

    if (user.role == UserRole.buyer && dietaryPrefs.isNotEmpty) {
      try {
        await authRepo.updateDietaryPreferences(dietaryPrefs);
      } catch (_) {
        // Не блокируем вход, если синхронизация фильтров питания временно не удалась.
      }
    }
    final nextMode = switch (user.role) {
      UserRole.admin => AppMode.admin,
      UserRole.partner || UserRole.cashier => AppMode.venue,
      UserRole.buyer => AppMode.buyer,
    };
    await onboardingNotifier.complete();
    await modeNotifier.setMode(nextMode);
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onAuthenticated(user);
  }

  Future<void> _signInWithCredentials(String identifier, String password) async {
    final l10n = context.l10n;
    final cleanId = identifier.trim();
    if (cleanId.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.authErrInvalidCredentials);
      return;
    }
    if (ref.read(useBackendProvider) && !AuthValidators.isValidEmail(cleanId)) {
      setState(() => _errorText = l10n.authErrInvalidEmail);
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);

    setState(() {
      _isLoading = true;
      _errorText = null;
      _infoText = null;
    });

    try {
      final session = await authRepo.login(
        identifier: cleanId,
        password: password,
      );
      await _completeAuthSuccess(session.user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapAuthError(context, e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapAuthError(context, e);
      });
    }
  }

  Future<void> _register() async {
    final l10n = context.l10n;
    final isKk = Localizations.localeOf(context).languageCode == 'kk';
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final confirm = _regConfirmController.text;

    if (name.isEmpty) {
      setState(
        () => _errorText =
            isKk ? 'Атыңызды енгізіңіз' : 'Введите ваше имя',
      );
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
    if (!AuthValidators.isStrongPassword(password)) {
      setState(() => _errorText = l10n.authErrWeakPassword);
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = l10n.authErrPasswordMismatch);
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);

    setState(() {
      _isLoading = true;
      _errorText = null;
      _infoText = null;
    });

    try {
      final createdUser = await authRepo.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      await _completeAuthSuccess(createdUser);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapAuthError(context, e);
      });
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = context.l10n;
    final emailController = TextEditingController(
      text: _identifierController.text.contains('@')
          ? _identifierController.text.trim()
          : '',
    );
    String? dialogError;
    final submittedEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.authForgotPassword),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (dialogError != null) {
                setDialogState(() => dialogError = null);
              }
            },
            decoration: InputDecoration(
              labelText: l10n.authEmailLabel,
              hintText: 'name@example.kz',
              errorText: dialogError,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final candidate = emailController.text.trim();
                if (!AuthValidators.isValidEmail(candidate)) {
                  setDialogState(() => dialogError = l10n.authErrInvalidEmail);
                  return;
                }
                Navigator.of(dialogContext).pop(candidate);
              },
              child: Text(l10n.actionNext),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();

    if (submittedEmail == null || submittedEmail.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
      _infoText = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(submittedEmail);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _infoText = l10n.authForgotPasswordSent(submittedEmail);
        _errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapAuthError(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Column(
              children: [
                ToidymLogo(darkText: true, height: 34),
                SizedBox(height: AppSpacing.xs),
                QumbekMascot(mood: QumbekMood.happy, size: 64),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isRegisterTab ? l10n.authRegisterTitle : l10n.authLoginTitle,
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.guestBenefitsSubtitle,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          Center(
            child: ToidymPillToggle<bool>(
              selected: _isRegisterTab,
              items: [
                (value: false, label: l10n.authTabLogin),
                (value: true, label: l10n.authTabRegister),
              ],
              onSelected: (isReg) {
                setState(() {
                  _isRegisterTab = isReg;
                  _errorText = null;
                  _infoText = null;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_infoText != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _infoText!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (!_isRegisterTab) ...[
            TextField(
              key: const ValueKey('auth_login_identifier'),
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearFeedback(),
              decoration: InputDecoration(
                labelText: ref.watch(useBackendProvider)
                    ? l10n.authEmailLabel
                    : l10n.authEmailOrPhoneLabel,
                hintText: 'name@example.kz',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('auth_login_password'),
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearFeedback(),
              decoration: InputDecoration(
                labelText: l10n.authPasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () => _obscureLoginPassword = !_obscureLoginPassword,
                    );
                  },
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => _signInWithCredentials(
                _identifierController.text,
                _loginPasswordController.text,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                child: Text(l10n.authForgotPassword),
              ),
            ),
            if (_errorText != null) ...[
              _AuthErrorBanner(message: _errorText!),
              const SizedBox(height: AppSpacing.sm),
            ] else
              const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.actionLogin,
              isLoading: _isLoading,
              onPressed: () => _signInWithCredentials(
                _identifierController.text,
                _loginPasswordController.text,
              ),
            ),
          ] else ...[
            TextField(
              key: const ValueKey('auth_reg_name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearFeedback(),
              decoration: InputDecoration(
                labelText: l10n.authNameLabel,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('auth_reg_phone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [KzPhoneMaskFormatter()],
              onChanged: (_) => _clearFeedback(),
              decoration: InputDecoration(
                labelText: l10n.authPhoneLabel,
                hintText: l10n.authPhoneHint,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('auth_reg_email'),
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearFeedback(),
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                hintText: 'name@example.kz',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('auth_reg_password'),
              controller: _regPasswordController,
              obscureText: _obscureRegPassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearFeedback(),
              decoration: InputDecoration(
                labelText: l10n.authPasswordLabel,
                helperText: l10n.authPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureRegPassword = !_obscureRegPassword);
                  },
                  icon: Icon(
                    _obscureRegPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('auth_reg_confirm'),
              controller: _regConfirmController,
              obscureText: _obscureRegPassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearFeedback(),
              onSubmitted: (_) => _register(),
              decoration: InputDecoration(
                labelText: l10n.authConfirmPasswordLabel,
                prefixIcon: const Icon(Icons.lock_reset_rounded),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.md),
              _AuthErrorBanner(message: _errorText!),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.authTabRegister,
              isLoading: _isLoading,
              onPressed: _register,
            ),
          ],

          if (!ref.watch(useBackendProvider)) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.authDemoAccountsTitle,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.person_rounded, size: 16),
                  label: Text(l10n.profileRoleBuyer),
                  onPressed: _isLoading
                      ? null
                      : () => _signInWithCredentials(
                            SeedData.demoUserEmail,
                            SeedData.demoUserPassword,
                          ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.storefront_rounded, size: 16),
                  label: Text(l10n.profileRoleOwner),
                  onPressed: _isLoading
                      ? null
                      : () => _signInWithCredentials(
                            SeedData.demoPartnerEmail,
                            SeedData.demoPartnerPassword,
                          ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.point_of_sale_rounded, size: 16),
                  label: Text(l10n.profileRoleCashier),
                  onPressed: _isLoading
                      ? null
                      : () => _signInWithCredentials(
                            SeedData.demoCashierEmail,
                            SeedData.demoCashierPassword,
                          ),
                ),
                ActionChip(
                  avatar: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 16,
                  ),
                  label: Text(l10n.profileRoleAdmin),
                  onPressed: _isLoading
                      ? null
                      : () => _signInWithCredentials(
                            SeedData.demoAdminEmail,
                            SeedData.demoAdminPassword,
                          ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
