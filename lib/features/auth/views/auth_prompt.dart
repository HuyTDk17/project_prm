import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/state_views.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Guards an action that needs an account (like, comment, subscribe, upload ...).
/// Returns true when the user is logged in. Otherwise it shows the
/// "log in required" sheet and returns false.
bool requireLogin(BuildContext context, String reason) {
  if (context.read<AuthViewModel>().isAuthenticated) return true;
  showAuthPrompt(context, reason: reason);
  return false;
}

Future<void> showAuthPrompt(BuildContext context, {required String reason}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => _AuthPromptSheet(
      reason: reason,
      onLogin: () {
        Navigator.of(sheetContext).pop();
        context.push(RouteNames.login);
      },
      onRegister: () {
        Navigator.of(sheetContext).pop();
        context.push(RouteNames.register);
      },
    ),
  );
}

class _AuthPromptSheet extends StatelessWidget {
  const _AuthPromptSheet({
    required this.reason,
    required this.onLogin,
    required this.onRegister,
  });

  final String reason;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.lock_outline_rounded, size: 30, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Log in to continue', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Log in'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [child] to logged-in users and a "log in" invitation to guests.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthViewModel, bool>((a) => a.isAuthenticated);
    if (loggedIn) return child;
    return SafeArea(
      child: StateView(
        icon: icon,
        title: title,
        message: message,
        actionLabel: 'Log in',
        onAction: () => context.push(RouteNames.login),
        secondaryLabel: 'Create account',
        onSecondary: () => context.push(RouteNames.register),
      ),
    );
  }
}
