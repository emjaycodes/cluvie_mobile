// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/theme/spacing.dart';
// import '../../../../core/widgets/cl_primary_button.dart';

// class CreateCommunityScreen extends StatefulWidget {
//   const CreateCommunityScreen({super.key});

//   @override
//   _CreateCommunityScreenState createState() => _CreateCommunityScreenState();
// }

// class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _communityNameController = TextEditingController();
//   final _communityDescriptionController = TextEditingController();

//   @override
//   void dispose() {
//     _communityNameController.dispose();
//     _communityDescriptionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Create New Community"),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: AppSpacing.screenPadding,
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 // Community Name
//                 TextFormField(
//                   controller: _communityNameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Community Name',
//                     hintText: 'Enter community name',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a community name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Community Description
//                 TextFormField(
//                   controller: _communityDescriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Community Description',
//                     hintText: 'Describe your community',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a community description';
//                     }
//                     return null;
//                   },
//                   maxLines: 4,
//                 ),
//                 const SizedBox(height: 32),

//                 // Submit Button
//                 ClPrimaryButton(
//                   text: "Create Community",
//                   onPressed: _createCommunity,
//                 ),
//               ],
//             ),
//           ),
//         ),
