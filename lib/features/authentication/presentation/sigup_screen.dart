import 'package:cluvie_mobile/core/router/routes_name.dart';
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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authNotifierProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .register(_name.text.trim(), _email.text.trim(), _password.text);
    if (!ok || !mounted) return;
    TextInput.finishAutofillContext();
    await LaunchState.markOnboardingSeen();
    // Previously navigated to a non-existent `movies` route (crash).
    if (mounted) context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    return AuthFormScaffold(children: [
      const ClEntrance(
        child: AuthHeading(line1: 'Create your account.', line2: 'Then find your club.'),
      ),
      const SizedBox(height: AppSpacing.xl),
      if (auth.error != null && !auth.isLoading) ...[
        ClStatusBanner(type: ClStatusType.error, message: auth.error!),
        const SizedBox(height: AppSpacing.lg),
      ],
      Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(children: [
            ClTextField(
              label: 'Name',
              controller: _name,
              hintText: 'Ada Obi',
              prefixIcon: AppIcons.user,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
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
              hintText: 'Create a password',
              helperText: 'At least 6 characters.',
              prefixIcon: AppIcons.lock,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: validatePassword,
              onSubmitted: (_) => _submit(),
            ),
          ]),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      ClButton(label: 'Create account', isLoading: auth.isLoading, onPressed: _submit),
      const SizedBox(height: AppSpacing.lg),
      AuthSwitchLink(
        prompt: 'Already have an account?',
        action: 'Log in',
        onTap: () => context.pushReplacementNamed(RouteNames.login),
      ),
    ]);
  }
}
