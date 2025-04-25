// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/widgets/cl_primary_button.dart';
// import '../../../../core/theme/spacing.dart';

// class SuggestMovieScreen extends StatefulWidget {
//   const SuggestMovieScreen({super.key});

//   @override
//   _SuggestMovieScreenState createState() => _SuggestMovieScreenState();
// }

// class _SuggestMovieScreenState extends State<SuggestMovieScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _movieTitleController = TextEditingController();
//   final TextEditingController _movieDescriptionController = TextEditingController();

//   @override
//   void dispose() {
//     _movieTitleController.dispose();
//     _movieDescriptionController.dispose();
//     super.dispose();
//   }

//   void _submitMovieSuggestion() {
//     if (_formKey.currentState?.validate() ?? false) {
//       // Simulate movie suggestion submission
//       final movieTitle = _movieTitleController.text;
//       final movieDescription = _movieDescriptionController.text;

//       // Simulate sending data to backend or community
//       print('Movie Suggested: $movieTitle\nDescription: $movieDescription');
      
//       // Show confirmation dialog
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Movie Suggested"),
//           content: const Text("Your movie suggestion has been sent!"),
//           actions: [
//             TextButton(
//               onPressed: () => context.pop(),
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
//       appBar: AppBar(
//         title: const Text("Suggest a Movie"),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: AppSpacing.screenPadding,
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 32),

//                 // Movie Title Input
//                 TextFormField(
//                   controller: _movieTitleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Movie Title',
//                     hintText: 'Enter the movie title',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a movie title';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Movie Description Input
//                 TextFormField(
//                   controller: _movieDescriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Movie Description',
//                     hintText: 'Enter a brief description of the movie',
//                   ),
//                   maxLines: 5,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a movie description';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 32),

//                 // Submit Button
//                 ClPrimaryButton(
//                   text: "Submit Suggestion",
//                   onPressed: _submitMovieSuggestion,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// // 