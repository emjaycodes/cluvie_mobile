// import 'package:flutter/material.dart';
// import '../../../../core/theme/spacing.dart';

// class VoteSummaryScreen extends StatelessWidget {
//   final String movieTitle;
//   final List<int> ratings;

//   const VoteSummaryScreen({
//     super.key,
//     required this.movieTitle,
//     required this.ratings,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Calculate the total number of votes and average rating
//     final int totalVotes = ratings.length;
//     final double averageRating = ratings.isEmpty
//         ? 0.0
//         : ratings.reduce((a, b) => a + b) / totalVotes;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("$movieTitle Voting Results"),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: AppSpacing.screenPadding,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Movie Title
//               Text(
//                 movieTitle,
//                 style: Theme.of(context).textTheme.headlineMedium,
//               ),
//               const SizedBox(height: 16),

//               // Voting Breakdown
//               Text(
//                 "Total Votes: $totalVotes",
//                 style: Theme.of(context).textTheme.bodyLarge,
//               ),
//               const SizedBox(height: 16),

//               // Average Rating
//               Text(
//                 "Average Rating: ${averageRating.toStringAsFixed(1)} / 5",
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 32),

//               // Rating Distribution (for simplicity, we will assume a basic distribution here)
//               Text(
//                 "Rating Distribution:",
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 8),
//               ..._buildRatingDistribution(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildRatingDistribution(BuildContext context) {
//     final Map<int, int> ratingDistribution = {
//       1: ratings.where((rating) => rating == 1).length,
//       2: ratings.where((rating) => rating == 2).length,
//       3: ratings.where((rating) => rating == 3).length,
//       4: ratings.where((rating) => rating == 4).length,
//       5: ratings.where((rating) => rating == 5).length,
//     };

//     return ratingDistribution.entries.map((entry) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Row(
//           children: [
//             Text("${entry.key} Stars: "),
//             LinearProgressIndicator(
//               value: entry.value / ratings.length,
//               backgroundColor: Colors.grey[200],
//               color: Colors.blue,
//             ),
//             const SizedBox(width: 8),
//             Text("${entry.value} votes"),
//           ],
//         ),
//       );
//     }).toList();
//   }
// }
