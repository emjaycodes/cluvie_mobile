import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_form_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    // TODO(api): no reset endpoint exists yet — this still simulates the request.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sentTo = _email.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sentTo != null) {
      return AuthFormScaffold(children: [
        const SizedBox(height: AppSpacing.xxl),
        Semantics(
          liveRegion: true,
          child: ClEntrance(
            child: Column(children: [
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
                'If an account exists for $_sentTo, you\'ll get a link to reset your password in a few minutes.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ClButton(label: 'Back to log in', onPressed: () => context.goNamed(RouteNames.login)),
        const SizedBox(height: AppSpacing.sm),
        ClButton(
          label: 'Use a different email',
          variant: ClButtonVariant.ghost,
          onPressed: () => setState(() => _sentTo = null),
        ),
      ]);
    }

    return AuthFormScaffold(children: [
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
      ClButton(label: 'Send reset link', isLoading: _loading, onPressed: _send),
      const SizedBox(height: AppSpacing.lg),
      AuthSwitchLink(
        prompt: 'Remembered it?',
        action: 'Log in',
        onTap: () => context.canPop() ? context.pop() : context.goNamed(RouteNames.login),
      ),
    ]);
  }
}
