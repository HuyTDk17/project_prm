import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_layout.dart';
import 'widgets/google_button.dart';

/// Login screen. It is opened from Home (guests browse without an account).
/// After a successful login the router redirects back to Home.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthLayout(form: _LoginForm());
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.read<AuthViewModel>().login(_email.text, _password.text);
    // Go to Home explicitly; the router redirect alone does not close a
    // login page that was opened with push.
    if (ok && mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Log in to like, comment, subscribe and upload your own videos.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _email,
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.password,
                  onChanged: (_) => auth.clearError(),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        AuthErrorBanner(message: auth.errorMessage),
        const SizedBox(height: 24),
        AppButton(label: 'Log in', isLoading: auth.isLoading, onPressed: _submit),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        GoogleButton(
          label: 'Continue with Google',
          onPressed: auth.isLoading
              ? null
              : () async {
                  final ok = await context.read<AuthViewModel>().loginWithGoogle();
                  if (ok && context.mounted) context.go(RouteNames.home);
                },
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => context.pushReplacement(RouteNames.register),
            child: const Text('New to MiniTube? Create an account'),
          ),
        ),
      ],
    );
  }
}
