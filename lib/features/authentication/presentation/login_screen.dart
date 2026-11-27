import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_form_scaffold.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
import 'package:cluvie_mobile/features/authentication/data/launch_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // S7: ignore repeat submits (keyboard Done + button) while in flight.
    if (ref.read(authNotifierProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitted = true);
    final ok = await ref.read(authNotifierProvider.notifier).login(_email.text.trim(), _password.text);
    if (!ok || !mounted) return;
    TextInput.finishAutofillContext();
    await LaunchState.markOnboardingSeen();
    if (mounted) context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    return AuthFormScaffold(
      children: [
        const ClEntrance(child: AuthHeading(line1: 'Welcome back.', line2: 'Your club is waiting.')),
        const SizedBox(height: AppSpacing.xl),
        if (_submitted && auth.error != null && !auth.isLoading) ...[
          ClStatusBanner(type: ClStatusType.error, message: auth.error!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                ClTextField(
                  label: 'Email',
                  controller: _email,
                  hintText: 'ada@example.com',
                  prefixIcon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                ),
                const SizedBox(height: AppSpacing.lg),
                ClTextField(
                  label: 'Password',
                  controller: _password,
                  hintText: 'Your password',
                  prefixIcon: AppIcons.lock,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: validatePassword,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        if (kPasswordResetAvailable)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.pushNamed(RouteNames.forgotPassword),
              style: TextButton.styleFrom(foregroundColor: AppColors.purpleText),
              child: const Text('Forgot password?'),
            ),
          )
        else
          const SizedBox(height: AppSpacing.lg),
        const SizedBox(height: AppSpacing.md),
        ClButton(label: 'Log in', isLoading: auth.isLoading, onPressed: _submit),
        const SizedBox(height: AppSpacing.lg),
        AuthSwitchLink(
          prompt: 'New to Cluvie?',
          action: 'Create an account',
          onTap: () => context.pushReplacementNamed(RouteNames.signup),
        ),
      ],
    );
  }
}
