import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/features/communities/presentation/joined_community_screen.dart';
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

    return
    Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add),
        //     onPressed: () => context.push('/create-community'),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.clPadding,
          child: Column(
            children: [
              // Display the list of communities
              Expanded(
                child: ListView.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return CommunityCard();
                  },
                ),
              ),
              const SizedBox(height: 32),
              // // Optionally, add a button for creating a new community
              // ClPrimaryButton(
              //   text: "Create a Community",
              //   onPressed: () => context.push('/create-community'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
