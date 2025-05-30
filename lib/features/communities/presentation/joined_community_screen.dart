import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/features/communities/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinedCommunitiesScreen extends ConsumerStatefulWidget {
  const JoinedCommunitiesScreen({super.key});

  @override
  ConsumerState<JoinedCommunitiesScreen> createState() => _JoinedCommunitiesScreenConsumerState();
}

class _JoinedCommunitiesScreenConsumerState extends ConsumerState<JoinedCommunitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final community = ref.watch(communityNotifierProvider);
    if (community.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (community.error != null) {
      return Center(child: Text('Error: ${community.error}'));
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          context.pushNamed('createCommunity');
        },
        child: const Icon(Icons.add),
      ),
      // backgroundColor: Colors.black, // Netflix style
      appBar: AppBar(
        // backgroundColor: Colors.black,
        title: const Text("Your Communities", style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('communitySearch'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 Continue Participating Row
            const Text("Continue Participating", style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // active communities
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return AspectRatio(
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
                          child: const Text(
                            "Movie Buffs NG",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 🟦 All Communities List
            const Text("All Joined Communities", style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // all joined communities
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return CommunityCard(community: community.communities[index],);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityCard extends StatelessWidget {
  final Community community; 
  const CommunityCard({
    super.key, required this.community,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        title:  Text(community.name, style: TextStyle(color: Colors.white)),
        subtitle: Text(
          '${community.members.length} · 🔥 Trending discussion',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
          onPressed: () {
            context.pushNamed('communityDetail');
          },
        ),
      ),
    );
  }
}
