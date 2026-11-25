import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';

/// Layout for login / signup / reset: transparent app bar with back button,
/// quiet backdrop, keyboard-safe scrolling column.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ClAppBar(title: '', transparent: true),
      body: AuthBackdrop(
        intensity: 0.6,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.xxl),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// No password-reset endpoint exists yet. Until it does, the "Forgot
/// password?" link is hidden and the screen says so plainly instead of
/// pretending an email was sent (review round 3, B4).
const bool kPasswordResetAvailable = false;

/// Simple email shape check (server is the source of truth).
String? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Enter your email.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email, like ada@example.com.';
  return null;
}

String? validatePassword(String? v) {
  if ((v ?? '').length < 6) return 'Use at least 6 characters.';
  return null;
}
