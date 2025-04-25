import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'splash_screen.dart'; // for access to authProvider

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate login

    ref.read(authProvider.notifier).state = true;

    // if (context.mounted) {
    //   context.goNamed(RouteNames.movies); // go to home
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.clPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text("Welcome Back 👋", style: AppTextStyles.heading1),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  "Log in to continue using Cluvie.",
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Email
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'johndoe@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value ?? '',
                  validator:
                      (value) =>
                          value != null && value.contains('@')
                              ? null
                              : 'Enter valid email',
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (value) => _password = value ?? '',
                  validator:
                      (value) =>
                          value != null && value.length >= 6
                              ? null
                              : 'Min 6 characters',
                ),

                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(),
                    TextButton(
                      onPressed:
                          () => context.pushNamed(RouteNames.forgotPassword),
                      child: const Text("Forgot Password"),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                // Login Button
                ClButton(
                  label: _loading ? 'Logging in...' : 'Login',
                  onPressed: _loading ? () {} : _handleLogin,
                ),

                const SizedBox(height: AppSpacing.md),

                // Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton(
                      onPressed: () => context.pushNamed(RouteNames.signup),
                      child: const Text("Sign up"),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
