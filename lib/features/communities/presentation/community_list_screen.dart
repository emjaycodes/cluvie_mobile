import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/features/communities/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/communities/presentation/joined_community_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<CommunityListScreen> createState() => _CommunityListScreenConsumerState();
}

class _CommunityListScreenConsumerState extends ConsumerState<CommunityListScreen> {
  @override
  Widget build(BuildContext context) {
    
    final community = ref.watch(communityNotifierProvider);

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
                child: ListView.separated(
                  itemCount: 4,
                   separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        print('tappeed');
                         context.push('/communityChat');},
                      // child: CommunityCard(community: community.communities,)
                      );
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
