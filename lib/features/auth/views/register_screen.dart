import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_layout.dart';
import 'widgets/google_button.dart';

/// Register screen: no role to choose. Every account can watch, and a default
/// channel is created automatically so the user can upload right away (BR03).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthLayout(form: _RegisterForm());
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // On success the router redirects to Home.
    await context.read<AuthViewModel>().register(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.watch<AuthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create your account', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'One account to watch, like, comment and publish your own videos.',
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Display name',
                  hint: 'Your name',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.displayName,
                  onChanged: (_) => auth.clearError(),
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _email,
                  focusNode: _emailFocus,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  onChanged: (_) => auth.clearError(),
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  label: 'Password',
                  hint: '6-32 characters',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onChanged: (_) => auth.clearError(),
                  onSubmitted: (_) => _confirmFocus.requestFocus(),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _confirm,
                  focusNode: _confirmFocus,
                  label: 'Confirm password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.password(value) ??
                      (value == _password.text ? null : AppStrings.passwordMismatch),
                  onChanged: (_) => auth.clearError(),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        AuthErrorBanner(message: auth.errorMessage),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.live_tv_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A channel with your name is created for you, so you can upload videos right away.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Create account', isLoading: auth.isLoading, onPressed: _submit),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        GoogleButton(
          label: 'Sign up with Google',
          onPressed: auth.isLoading ? null : () => context.read<AuthViewModel>().loginWithGoogle(),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.pushReplacement(RouteNames.login),
            child: const Text('Already have an account? Log in'),
          ),
        ),
      ],
    );
  }
}
