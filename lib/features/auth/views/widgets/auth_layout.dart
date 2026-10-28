import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import 'brand_hero.dart';

/// Shared frame of Login and Register. Wide windows get a split layout
/// (brand | form), narrow windows get a header on top of the form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.form});

  final Widget form;

  static const double splitBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= splitBreakpoint) {
            return Row(
              children: [
                const Expanded(flex: 5, child: BrandPanel()),
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: form,
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: SafeArea(child: CloseAuthButton()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                const BrandHeader(trailing: CloseAuthButton(onDark: true)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: form,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Closes Login / Register and goes back to browsing as a guest.
class CloseAuthButton extends StatelessWidget {
  const CloseAuthButton({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Close',
      onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
      icon: Icon(Icons.close_rounded, color: onDark ? Colors.white : null),
    );
  }
}
