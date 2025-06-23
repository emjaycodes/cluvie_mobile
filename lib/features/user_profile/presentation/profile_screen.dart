import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  final String email;
  final int joinedCommunities;
  final int totalPosts;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.joinedCommunities,
    required this.totalPosts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Handle logout
              context.go('/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: AppSpacing.clPadding,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary,
              child: Text(
                username[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // Username and Email
            Text(username, style: AppTextStyles.heading1),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 32),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatTile(label: "Communities", value: joinedCommunities),
                _StatTile(label: "Posts", value: totalPosts),
              ],
            ),

            const SizedBox(height: 32),

            // Edit Profile
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  // TODO: Navigate to edit screen
                  context.push('/edit-profile');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;

  const _StatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
