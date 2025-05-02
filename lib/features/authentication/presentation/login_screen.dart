import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_loading.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
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


  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

     await ref.read(authNotifierProvider.notifier).login("email", "password");

    if (context.mounted) {
      context.goNamed(RouteNames.movies); // go to home
    }
  }

  @override
  Widget build(BuildContext context) {
      final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return Scaffold(
        body: Center(child: ClLoading()), 
      );
    }
    return Scaffold(
      body: SafeArea(
        child: authState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(authState.error!, style: TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).login("email", "password");
                    },
                    child: Text("Retry"),
                  ),
                ],
              ),
            )
          : Padding(
          padding: AppSpacing.clPadding,
          child: Form(
            key: _formKey,
            child: Column(
              
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
                  label: 'Login',
                  onPressed: _handleLogin,
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
