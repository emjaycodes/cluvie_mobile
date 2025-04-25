import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _loading = false;

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate signup

    // if (context.mounted) {
    //   context.goNamed(RouteNames.emailVerification);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.clPadding,
          child: Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 40),
                  Text("Create Account", style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  const Text("Start your Cluvie journey", style: AppTextStyles.heading2,),
                  const SizedBox(height: AppSpacing.xl),
            
                  // Name
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Joe Doe'),
                    keyboardType: TextInputType.name,
                    onSaved: (value) => _name = value ?? '',
                    validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
            
                  // Email
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'johndoe@example.com'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => _email = value ?? '',
                    validator: (value) =>
                        value != null && value.contains('@') ? null : 'Enter valid email',
                  ),
                  const SizedBox(height: AppSpacing.md),
            
                  // Password
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onSaved: (value) => _password = value ?? '',
                    validator: (value) =>
                        value != null && value.length >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: AppSpacing.xl*2),
            
                  ClButton(
                    label: _loading ? 'Creating Account...' : 'Create Account',
                    onPressed: _loading ? () {} : _handleSignup,
                  ),
            
                  TextButton(
                    onPressed: () => context.pushNamed(RouteNames.login),
                    child: const Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
