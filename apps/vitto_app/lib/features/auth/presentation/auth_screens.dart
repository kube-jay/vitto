import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/common.dart';
import '../data/auth_repository.dart';

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

String? _emailError(AppLocalizations l10n, String? v) =>
    v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
    ? l10n.validEmail
    : null;

String? _passwordError(AppLocalizations l10n, String? v) =>
    v == null || v.length < 8 ? l10n.validPassword : null;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(_email.text, _password.text);
      // The router redirect sends the user on to `from`.
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = failureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AuthFrame(
      title: l10n.signIn,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (v) => _emailError(l10n, v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(labelText: l10n.password),
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.validPassword : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: VittoColors.danger)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.signIn),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(Routes.resetPassword),
          child: Text(l10n.forgotPassword),
        ),
        const Divider(height: 32),
        Text(l10n.noAccountYet, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go(
            Uri(
              path: Routes.signup,
              queryParameters: {'from': ?widget.from},
            ).toString(),
          ),
          child: Text(l10n.signUp),
        ),
      ],
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _country;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final locale =
          ref.read(localeProvider)?.languageCode ??
          (_country == 'BJ' ? 'fr' : 'en');
      final needsConfirm = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
            countryCode: _country!,
            locale: locale,
          );
      if (mounted) setState(() => _sent = needsConfirm);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = failureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_sent) {
      return _AuthFrame(
        title: l10n.checkYourEmail,
        children: [
          Text(l10n.confirmEmailSent(_email.text.trim())),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go(Routes.login),
            child: Text(l10n.signIn),
          ),
        ],
      );
    }
    return _AuthFrame(
      title: l10n.signUp,
      children: [
        Text(
          l10n.oneAccountHint,
          style: const TextStyle(color: VittoColors.muted),
        ),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.displayName),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty || v.trim().length > 60
                    ? l10n.validRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _country,
                decoration: InputDecoration(labelText: l10n.country),
                items: [
                  DropdownMenuItem(
                    value: 'NG',
                    child: Text(l10n.countryNigeria),
                  ),
                  DropdownMenuItem(value: 'BJ', child: Text(l10n.countryBenin)),
                ],
                onChanged: (v) => setState(() => _country = v),
                validator: (v) => v == null ? l10n.validRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.email),
                validator: (v) => _emailError(l10n, v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.password,
                  helperText: l10n.validPassword,
                ),
                validator: (v) => _passwordError(l10n, v),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: VittoColors.danger)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.signUp),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.agreeToTerms,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: () => context.push(Routes.terms),
          child: Text(l10n.screenTerms),
        ),
        TextButton(
          onPressed: () => context.go(Routes.login),
          child: Text(l10n.haveAccount),
        ),
      ],
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AuthFrame(
      title: l10n.resetPassword,
      children: [
        if (_sent)
          Text(l10n.resetEmailSent)
        else ...[
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (_emailError(l10n, _email.text) != null) {
                showSnack(context, l10n.validEmail);
                return;
              }
              final ok = await runGuarded(context, () async {
                await ref
                    .read(authRepositoryProvider)
                    .sendPasswordReset(_email.text);
                return true;
              });
              if (ok == true && mounted) setState(() => _sent = true);
            },
            child: Text(l10n.sendResetLink),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(Routes.login),
          child: Text(l10n.signIn),
        ),
      ],
    );
  }
}

/// Reached from the password-recovery email link.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AuthFrame(
      title: l10n.newPassword,
      children: [
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.password,
            helperText: l10n.validPassword,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            if (_passwordError(l10n, _password.text) != null) {
              showSnack(context, l10n.validPassword);
              return;
            }
            final ok = await runGuarded(context, () async {
              await ref
                  .read(authRepositoryProvider)
                  .updatePassword(_password.text);
              return true;
            });
            if (ok == true && context.mounted) {
              showSnack(context, l10n.passwordUpdated);
              context.go(Routes.home);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
