import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/auth_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/themes/themes.dart';
import '../view_models/auth_view_model.dart';

class AuthBottomSheet extends StatelessWidget {
  const AuthBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider<AuthViewModel>(
          create: (_) =>
              AuthViewModel(authRepository: context.read<AuthRepository>()),
          child: const AuthBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _AuthSheetContent();
  }
}

class _AuthSheetContent extends StatefulWidget {
  const _AuthSheetContent();

  @override
  State<_AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends State<_AuthSheetContent> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _minPasswordLength = 6;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final Listenable _fieldsListenable =
      Listenable.merge([_emailCtrl, _passwordCtrl]);
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Command<void> _activeCommand(AuthViewModel vm) =>
      vm.mode == AuthMode.signIn ? vm.signInWithEmail : vm.signUpWithEmail;

  bool _canSubmit(AuthMode mode) {
    if (!_emailRegex.hasMatch(_emailCtrl.text.trim())) return false;
    // Em sign in basta a senha não estar vazia (Firebase responde
    // se for inválida); em sign up exigimos o mínimo do Firebase.
    return mode == AuthMode.signIn
        ? _passwordCtrl.text.isNotEmpty
        : _passwordCtrl.text.length >= _minPasswordLength;
  }

  Future<void> _submitIfReady(AuthViewModel vm) async {
    if (_canSubmit(vm.mode)) await _submit(vm);
  }

  Future<void> _submit(AuthViewModel vm) async {
    final input = EmailPasswordInput(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (vm.mode == AuthMode.signIn) {
      await vm.signInWithEmail.execute(input);
    } else {
      await vm.signUpWithEmail.execute(input);
    }
    if (!mounted) return;
    final cmd = _activeCommand(vm);
    if (cmd.completed) {
      await _dismiss();
    }
  }

  Future<void> _submitGoogle(AuthViewModel vm) async {
    await vm.signInWithGoogle.execute();
    if (!mounted) return;
    if (vm.signInWithGoogle.completed) {
      await _dismiss();
    }
  }

  Future<void> _dismiss() async {
    // Em sucesso de auth, o `refreshListenable` do GoRouter já
    // redireciona para /home no mesmo frame — o stack pode não ter
    // mais a rota de baixo do sheet. `maybePop` é defensivo: fecha
    // o sheet se ainda estiver no topo do Navigator, ou não faz nada.
    await Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AuthViewModel, AuthMode>((vm) => vm.mode);
    final vm = context.read<AuthViewModel>();
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    final isSignIn = mode == AuthMode.signIn;
    final activeCmd = _activeCommand(vm);
    final googleCmd = vm.signInWithGoogle;

    final title = isSignIn ? l10n.authSignInTitle : l10n.authSignUpTitle;
    final subtitle = isSignIn ? l10n.authSignInSubtitle : l10n.authSignUpSubtitle;
    final ctaLabel = isSignIn ? l10n.authSubmitSignIn : l10n.authSubmitSignUp;
    final togglePrompt =
        isSignIn ? l10n.authToggleToSignUpPrompt : l10n.authToggleToSignInPrompt;
    final toggleAction =
        isSignIn ? l10n.authToggleToSignUpAction : l10n.authToggleToSignInAction;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: text.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: text.bodyMedium?.copyWith(color: colors.textDim),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedBuilder(
                animation: Listenable.merge([activeCmd, googleCmd]),
                builder: (context, _) {
                  final running = activeCmd.running || googleCmd.running;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GoogleButton(
                        label: l10n.authContinueWithGoogle,
                        running: googleCmd.running,
                        disabled: running,
                        onPressed: () => _submitGoogle(vm),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OrDivider(label: l10n.authDividerOr),
                      const SizedBox(height: AppSpacing.lg),
                      _LabeledTextField(
                        label: l10n.authEmailLabel,
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        hintText: l10n.authEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        fieldKey: const Key('auth-email-field'),
                        enabled: !running,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        label: l10n.authPasswordLabel,
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: isSignIn
                            ? const [AutofillHints.password]
                            : const [AutofillHints.newPassword],
                        fieldKey: const Key('auth-password-field'),
                        enabled: !running,
                        onSubmitted: (_) => _submitIfReady(vm),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? l10n.authPasswordVisibilityShow
                              : l10n.authPasswordVisibilityHide,
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InlineError(command: activeCmd, l10n: l10n),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ListenableBuilder(
                          listenable: _fieldsListenable,
                          builder: (context, _) {
                            final canSubmit = _canSubmit(mode);
                            return FilledButton(
                              key: const Key('auth-submit-button'),
                              onPressed: (running || !canSubmit)
                                  ? null
                                  : () => _submit(vm),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: colors.bg,
                                disabledBackgroundColor:
                                    colors.accent.withValues(alpha: 0.5),
                                disabledForegroundColor:
                                    colors.bg.withValues(alpha: 0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                              ),
                              child: activeCmd.running
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation(colors.bg),
                                      ),
                                    )
                                  : Text(
                                      ctaLabel,
                                      style: text.labelLarge?.copyWith(
                                        color: colors.bg,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            togglePrompt,
                            style: text.bodySmall?.copyWith(color: colors.textDimmer),
                          ),
                          TextButton(
                            onPressed: running ? null : vm.toggleMode,
                            child: Text(toggleAction),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.label,
    required this.running,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final bool running;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: running
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.text),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: text.labelLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: text.labelLarge?.copyWith(color: colors.text),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: colors.borderDim)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: typo.caption.copyWith(
              color: colors.textDimmer,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: colors.borderDim)),
      ],
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Key fieldKey;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.command, required this.l10n});

  final Command<void> command;
  final AppLocalizations l10n;

  String? _messageFor(Object error) {
    if (error is AuthCancelledException) return null;
    if (error is AuthException) {
      return switch (error.kind) {
        AuthErrorKind.invalidCredentials => l10n.authErrorInvalidCredentials,
        AuthErrorKind.emailAlreadyInUse => l10n.authErrorEmailInUse,
        AuthErrorKind.weakPassword => l10n.authErrorWeakPassword,
        AuthErrorKind.userDisabled => l10n.authErrorUserDisabled,
        AuthErrorKind.networkError => l10n.authErrorNetwork,
        AuthErrorKind.tooManyRequests => l10n.authErrorTooManyRequests,
        AuthErrorKind.googleSignInFailed => l10n.authErrorGoogleSignInFailed,
        AuthErrorKind.unknown => l10n.authErrorUnknown,
      };
    }
    return l10n.authErrorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: command,
      builder: (context, _) {
        final result = command.result;
        final text = context.text;
        String? message;
        if (result is Error<void>) {
          message = _messageFor(result.error);
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: message == null
                ? const SizedBox(width: double.infinity)
                : Row(
                    key: const ValueKey('inline-error'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          message,
                          style: text.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
