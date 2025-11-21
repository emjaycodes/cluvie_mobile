
// ignore_for_file: unused_element

import 'package:cluvie_mobile/core/models/community.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';


class CommunityInfoScreen extends StatelessWidget {
  final Community community;

  const CommunityInfoScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle:false,
              collapseMode: CollapseMode.pin,
              title: Text(community.name!),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                  'assets/images/dis.png',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // community.category.toUpperCase(),
                    "horror".toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoTile(
                        icon: Icons.people,
                        label: "Members",
                        value: "${community.members.length}",
                      ),
                      _InfoTile(
                        icon: Icons.chat_bubble_outline,
                        label: "Posts",
                        value: "800",
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today,
                        label: "Created",
                        value: DateFormat.yMMM().format(community.createdAt),
                      ),
                    ],
                  ),

                   Divider(),

                  const SizedBox(height: 24),
                  //   final bool isMember = community.members.contains(); 
                  // community.
                      _MemberFeatures(),
                      // : _JoinPrompt(community: community),

                  const SizedBox(height: 24),

                  // 🔸 Recent Topics Preview
                  Text(
                    "Trending Topics",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    10,
                    (index) => _DiscussionPreview(
                      title: "Should we watch Dune this weekend?",
                      replies: 48,
                      lastActive: "1h ago",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _MemberFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Member Features", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            _ActionChip(label: "View Discussions", icon: Icons.forum),
            _ActionChip(label: "Create Post", icon: Icons.add),
            _ActionChip(label: "Community Analytics", icon: Icons.bar_chart),
            _ActionChip(label: "Moderation", icon: Icons.admin_panel_settings),
          ],
        ),
      ],
    );
  }
}

class _JoinPrompt extends StatelessWidget {
  final Community community;

  const _JoinPrompt({required this.community});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "You're not a member of this community yet.",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
          },
          icon: const Icon(Icons.group_add),
          label: const Text("Join Community"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: AppColors.cinematicPurple,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 174,
      margin: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(label),
        avatar: Icon(icon, size: 18),
        onPressed: () {},
      ),
    );
  }
}

class _DiscussionPreview extends StatelessWidget {
  final String title;
  final int replies;
  final String lastActive;

  const _DiscussionPreview({
    required this.title,
    required this.replies,
    required this.lastActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text("$replies replies • Active $lastActive"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
      },
    );
  }
}
