import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommunityListScreen extends StatelessWidget {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate a list of communities (in a real app, this data would come from the backend)
    final List<String> communities = [
      'Movie Buffs',
      'Sci-Fi Lovers',
      'Horror Enthusiasts',
      'Action Movie Fans',
    ];

    return Placeholder();
    // Scaffold(
    //   appBar: AppBar(
    //     title: const Text("Communities"),
    //     actions: [
    //       IconButton(
    //         icon: const Icon(Icons.add),
    //         onPressed: () => context.push('/create-community'),
    //       ),
    //     ],
    //   ),
    //   body: SafeArea(
    //     child: Padding(
    //       padding: AppSpacing.screenPadding,
    //       child: Column(
    //         children: [
    //           // Display the list of communities
    //           Expanded(
    //             child: ListView.builder(
    //               itemCount: communities.length,
    //               itemBuilder: (context, index) {
    //                 return ListTile(
    //                   title: Text(communities[index]),
    //                   subtitle: const Text("Tap to view details"),
    //                   trailing: const Icon(Icons.arrow_forward),
    //                   onTap: () => context.push('/community/${communities[index]}'),
    //                 );
    //               },
    //             ),
    //           ),
    //           const SizedBox(height: 32),
    //           // Optionally, add a button for creating a new community
    //           ClPrimaryButton(
    //             text: "Create a Community",
    //             onPressed: () => context.push('/create-community'),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
