// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../app/router/route_names.dart';
// import '../../../../core/widgets/cl_primary_button.dart';
// import '../../../../core/theme/spacing.dart';

// class EmailVerificationScreen extends StatelessWidget {
//   const EmailVerificationScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: AppSpacing.screenPadding,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Email Verification",
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "We’ve sent you a verification link to your email. Please check your inbox and click the link to verify your account.",
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),

//               // Redirect to login
//               ClPrimaryButton(
//                 text: "Go to Login",
//                 onPressed: () => context.goNamed(RouteNames.login),
//               ),

//               const SizedBox(height: 16),
//               // Optionally, a button to resend the verification email
//               TextButton(
//                 onPressed: () {
//                   // Simulate resending the email verification link
//                   showDialog(
//                     context: context,
//                     builder: (_) => AlertDialog(
//                       title: const Text("Verification Email Sent"),
//                       content: const Text(
//                           "A new verification email has been sent. Please check your inbox."),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text("Okay"),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//                 child: const Text("Resend Verification Email"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
