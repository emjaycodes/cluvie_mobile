import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_form_scaffold.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
import 'package:cluvie_mobile/features/authentication/data/sign_out.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Set a new password (`/reset-password?token=…`), opened from the emailed
/// link `cluvie://reset-password?token=…`. Calls
/// `POST /auth/reset-password`; the token works once, for 30 minutes.
///
/// A reset signs out every session (old tokens get `401 SESSION_REVOKED`),
/// so this device is signed out too and the user logs in again.
///
/// Gold budget: one primary button per state.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  /// Null or empty when the link was cut short.
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum _Stage { form, done, invalidLink }

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _confirmFocus = FocusNode();
  bool _loading = false;
  String? _error;
  late _Stage _stage = (widget.token ?? '').trim().isEmpty ? _Stage.invalidLink : _Stage.form;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await AuthRepository(apiClient: ref.read(apiClientProvider)).resetPassword(widget.token!.trim(), _password.text);
      // Every session was signed out by the reset, this one included.
      await ref.read(authNotifierProvider.notifier).logout();
      clearUserState(ref.invalidate);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _stage = _Stage.done;
      });
    } catch (e) {
      if (!mounted) return;
      final body = e is ApiException ? e.responseBody : null;
      final status = e is ApiException ? e.statusCode : null;
      final code = body is Map ? body['code'] : null;
      final message = body is Map ? body['message'] : null;
      setState(() {
        _loading = false;
        if (code == 'INVALID_RESET_TOKEN') {
          _stage = _Stage.invalidLink;
        } else if (status == 400 && message is String && message.isNotEmpty) {
          _error = message;
        } else if (status == null) {
          _error = "Can't reach Cluvie right now. Check your connection and try again.";
        } else {
          _error = "Couldn't update your password. Try again in a moment.";
        }
      });
    }
  }

  void _toLogin() => context.goNamed(RouteNames.login);
  void _newLink() => context.goNamed(RouteNames.forgotPassword);

  Widget _outcome({required IconData icon, required String title, required String body}) => Semantics(
        liveRegion: true,
        child: ClEntrance(
          child: Column(children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow),
              child: Icon(icon, size: 48, color: AppColors.purpleText),
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(header: true, child: Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center)),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.done:
        return AuthFormScaffold(children: [
          const SizedBox(height: AppSpacing.xxl),
          _outcome(
            icon: AppIcons.success,
            title: 'Password updated',
            body: "You've been signed out everywhere. Log in with your new password.",
          ),
          const SizedBox(height: AppSpacing.xxl),
          ClButton(label: 'Log in', onPressed: _toLogin),
        ]);
      case _Stage.invalidLink:
        return AuthFormScaffold(children: [
          const SizedBox(height: AppSpacing.xxl),
          _outcome(
            icon: AppIcons.lock,
            title: 'This link is invalid or expired',
            body: 'Reset links work once, for 30 minutes, and a newer link replaces an older one. Ask for a new link.',
          ),
          const SizedBox(height: AppSpacing.xxl),
          ClButton(label: 'Get a new link', onPressed: _newLink),
          const SizedBox(height: AppSpacing.sm),
          ClButton(label: 'Back to log in', variant: ClButtonVariant.ghost, onPressed: _toLogin),
        ]);
      case _Stage.form:
        return AuthFormScaffold(children: [
          const ClEntrance(
            child: AuthHeading(
              line1: 'Set a new password',
              line2: 'Make it a good one.',
              body: "Pick one you don't use anywhere else.",
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: _formKey,
            child: Column(children: [
              ClTextField(
                label: 'New password',
                controller: _password,
                hintText: 'At least $kResetPasswordMin characters',
                prefixIcon: AppIcons.lock,
                isPassword: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: validateNewPassword,
                onSubmitted: (_) => _confirmFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              ClTextField(
                label: 'Confirm new password',
                controller: _confirm,
                focusNode: _confirmFocus,
                hintText: 'Type it again',
                prefixIcon: AppIcons.lock,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => v == _password.text ? null : "The passwords don't match.",
                onSubmitted: (_) => _submit(),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ...[
            ClStatusBanner(type: ClStatusType.error, message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          ClButton(label: 'Update password', isLoading: _loading, onPressed: _loading ? null : _submit),
          const SizedBox(height: AppSpacing.lg),
          AuthSwitchLink(prompt: 'Remembered it?', action: 'Log in', onTap: _toLogin),
        ]);
    }
  }
}
