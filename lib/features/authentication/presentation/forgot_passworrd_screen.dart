// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../app/router/route_names.dart';
// import '../../../../core/widgets/cl_primary_button.dart';
// import '../../../../core/theme/spacing.dart';

// class ForgotPasswordScreen extends ConsumerStatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String _email = '';
//   bool _loading = false;

//   void _handlePasswordReset() async {
//     if (!_formKey.currentState!.validate()) return;
//     _formKey.currentState!.save();

//     setState(() => _loading = true);

//     await Future.delayed(const Duration(seconds: 2)); // simulate password reset

//     if (context.mounted) {
//       // Show a success dialog or message
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Password Reset Link Sent"),
//           content: const Text("Check your email for the reset link."),
//           actions: [
//             TextButton(
//               onPressed: () => context.goNamed(RouteNames.login),
//               child: const Text("Okay"),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: AppSpacing.screenPadding,
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               children: [
//                 const SizedBox(height: 40),
//                 Text("Forgot Password", style: Theme.of(context).textTheme.headlineSmall),
//                 const SizedBox(height: 8),
//                 const Text("Enter your email to reset your password."),
//                 const SizedBox(height: 32),

//                 // Email input
//                 TextFormField(
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   keyboardType: TextInputType.emailAddress,
//                   onSaved: (value) => _email = value ?? '',
//                   validator: (value) =>
//                       value != null && value.contains('@') ? null : 'Enter valid email',
//                 ),
//                 const SizedBox(height: 32),

//                 // Reset Button
//                 ClPrimaryButton(
//                   text: _loading ? 'Sending Reset Link...' : 'Send Reset Link',
//                   onPressed: _loading ? null : _handlePasswordReset,
//                 ),

//                 const SizedBox(height: 16),

//                 TextButton(
//                   onPressed: () => context.pushNamed(RouteNames.login),
//                   child: const Text("Remember your password? Login"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
