import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_form_scaffold.dart';
import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Forgot password (`/forgotPassword`): asks `POST /auth/forgot-password`
/// for a reset link. The backend replies the same whether or not the
/// account exists, so the confirmation never says which.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.resetAvailable = kPasswordResetAvailable});

  /// Tests pass true; the app uses [kPasswordResetAvailable].
  final bool resetAvailable;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await AuthRepository(apiClient: ref.read(apiClientProvider)).forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sentTo = email;
      });
    } catch (e) {
      if (!mounted) return;
      final status = e is ApiException ? e.statusCode : null;
      setState(() {
        _loading = false;
        _error = switch (status) {
          429 => "You've asked for several links. Wait 15 minutes, then try again.",
          null => "Can't reach Cluvie right now. Check your connection and try again.",
          _ => "Couldn't send the link. Try again in a moment.",
        };
      });
    }
  }

  void _backToLogin() => context.canPop() ? context.pop() : context.goNamed(RouteNames.login);

  @override
  Widget build(BuildContext context) {
    if (!widget.resetAvailable) {
      // Reachable only by deep link while there is no reset endpoint.
      return AuthFormScaffold(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          ClEntrance(
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow),
                  child: const Icon(AppIcons.lock, size: 48, color: AppColors.purpleText),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text("Password reset isn't available yet", style: AppTextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "We can't send reset emails yet. If you're locked out, contact the Cluvie team and we'll help you back in.",
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ClButton(label: 'Back to log in', variant: ClButtonVariant.secondary, onPressed: _backToLogin),
        ],
      );
    }
    if (_sentTo != null) {
      return AuthFormScaffold(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Semantics(
            liveRegion: true,
            child: ClEntrance(
              child: Column(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow),
                    child: const Icon(AppIcons.email, size: 48, color: AppColors.purpleText),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Check your inbox', style: AppTextStyles.h1, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'If an account exists for $_sentTo, we\'ve sent a link to reset your password. It works for 30 minutes.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ClButton(label: 'Back to log in', onPressed: _backToLogin),
          const SizedBox(height: AppSpacing.sm),
          ClButton(
            label: 'Use a different email',
            variant: ClButtonVariant.ghost,
            onPressed: () => setState(() => _sentTo = null),
          ),
        ],
      );
    }

    return AuthFormScaffold(
      children: [
        const ClEntrance(
          child: AuthHeading(
            line1: 'Forgot your password?',
            line2: 'It happens.',
            body: 'Enter the email you signed up with and we\'ll send you a reset link.',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _formKey,
          child: ClTextField(
            label: 'Email',
            controller: _email,
            hintText: 'ada@example.com',
            prefixIcon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_error != null) ...[
          ClStatusBanner(type: ClStatusType.error, message: _error!),
          const SizedBox(height: AppSpacing.lg),
        ],
        ClButton(label: 'Send reset link', isLoading: _loading, onPressed: _loading ? null : _send),
        const SizedBox(height: AppSpacing.lg),
        AuthSwitchLink(prompt: 'Remembered it?', action: 'Log in', onTap: _backToLogin),
      ],
    );
  }
}
