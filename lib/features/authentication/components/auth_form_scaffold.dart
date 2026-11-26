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

/// The reset API exists (`/auth/forgot-password`, `/auth/reset-password`)
/// and the backend can send email (Resend), but the emailed link is
/// `cluvie://reset-password`, which mail apps don't make tappable (R10-S1).
/// Keep this off until the backend sends an https link (App Links /
/// Universal Links, or a redirect page) and the app registers that host.
/// For local testing, build with `--dart-define=PASSWORD_RESET=true`.
const bool kPasswordResetAvailable = bool.fromEnvironment('PASSWORD_RESET');

/// The backend's minimum for a new password (`/auth/reset-password`).
const kResetPasswordMin = 8;

String? validateNewPassword(String? v) {
  if ((v ?? '').length < kResetPasswordMin) return 'Use at least $kResetPasswordMin characters.';
  return null;
}

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
