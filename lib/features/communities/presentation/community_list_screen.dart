import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/features/communities/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/communities/presentation/joined_community_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class CommunityListScreen extends ConsumerWidget {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCommunityAsync = ref.watch(allCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.clPadding,
          child: allCommunityAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (communities) {
              if (communities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "No communities yet.",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      ClButton(
                        onPressed: () => context.push('/create-community'),
                        label: "Create a Community",
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: communities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return InkWell(
                          onTap: () => context.push('/communityChat'),
                          child: CommunityCard(community: community),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
