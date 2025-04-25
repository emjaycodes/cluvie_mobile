// import 'package:cluvie_mobile/core/theme/app_spacing.dart';
// import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class MovieDetailScreen extends StatelessWidget {
//   final String movieTitle;

//   const MovieDetailScreen({super.key, required this.movieTitle});

//   @override
//   Widget build(BuildContext context) {
//     // Simulate movie details
//     final String movieDescription =
//         "A mind-bending thriller directed by Christopher Nolan, following a thief who enters the dreams of others.";

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(movieTitle),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: AppSpacing.md,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Movie Description
//               Text(
//                 "Description:",
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 8),
//               Text(movieDescription),
//               const SizedBox(height: 32),

//               // Voting section
//               Text(
//                 "Rate this movie:",
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: List.generate(5, (index) {
//                   return IconButton(
//                     icon: Icon(
//                       index < 3 ? Icons.star : Icons.star_border,
//                       color: index < 3 ? Colors.orange : Colors.grey,
//                     ),
//                     onPressed: () {
//                       // Handle voting logic here
//                       print("Voted on $movieTitle with rating ${index + 1}");
//                     },
//                   );
//                 }),
//               ),
//               const SizedBox(height: 32),

//               // Comment section
//               Text(
//                 "Comments:",
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: ListView(
//                   children: [
//                     _CommentWidget(comment: "Amazing movie! A must-watch."),
//                     _CommentWidget(comment: "Loved the visuals and plot twist."),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Add Comment Button
//               ClButton(
//                 onPressed: () {
//                   // Simulate comment dialog or navigation
//                   showDialog(
//                     context: context,
//                     builder: (_) => AlertDialog(
//                       title: const Text("Add Comment"),
//                       content: TextField(
//                         decoration: const InputDecoration(hintText: "Write your comment..."),
//                         onSubmitted: (value) {
//                           // Handle comment submission logic
//                           print("Comment added: $value");
//                           Navigator.pop(context);
//                         },
//                       ),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text("Cancel"),
//                         ),
//                       ],
//                     ),
//                   );
//                 }, label: 'Add Comment',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CommentWidget extends StatelessWidget {
//   final String comment;

//   const _CommentWidget({super.key, required this.comment});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(comment),
//         ),
//       ),
//     );
//   }
// }
