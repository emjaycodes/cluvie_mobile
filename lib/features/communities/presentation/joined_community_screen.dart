import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/features/communities/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinedCommunitiesScreen extends ConsumerWidget {
  const JoinedCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedCommunityAsync = ref.watch(joinedCommunitiesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.pushNamed('createCommunity'),
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text("Your Communities", style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('communitySearch'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: joinedCommunityAsync.when(
          
          loading: () =>
              const Center(child: CircularProgressIndicator()),

         
          error: (e, _) =>
              Center(child: Text("Error: $e")),

          
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
                      onPressed: () => context.pushNamed('createCommunity'),
                      label: "Create a Community",
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Continue Participating (placeholder content)
                  const Text("Continue Participating",
                      style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5, // demo cards
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, __) => const _PlaceholderCard(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 🟦 All Joined Communities
                  const Text("All Joined Communities",
                      style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.sm),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: communities.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => CommunityCard(
                      community: communities[index],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/* --- helper widgets ----------------------------------------------------- */

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('assets/images/bb.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.all(8),
              child: const Text("Movie Buffs NG",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      );
}

class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key, required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/group.jpg',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(community.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${community.members.length} · 🔥 Trending discussion',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: () => context.pushNamed('communityDetail'),
          ),
        ),
      );
}
