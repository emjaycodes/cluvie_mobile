import 'package:flutter/material.dart';

class ClubSettingsScreen extends StatelessWidget {
  const ClubSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C1E),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ClubSettingsBody(),
      ),
    );
  }
}


class ClubSettingsBody extends StatelessWidget {
  const ClubSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubHeader(),
        const SizedBox(height: 20),
        const TextButton(
          onPressed: null,
          child: Text('Leave Club',
              style: TextStyle(color: Color(0xFF8CA4FF), fontWeight: FontWeight.w500)),
        ),
        const Divider(color: Colors.white12),
        const ClubSettingsItem(title: 'Edit Community Name'),
        const ClubSettingsItem(title: 'Change Cover Image'),
        const ClubSettingsItem(
          title: 'Membership',
          trailingText: 'Open to everyone',
        ),
        const ClubSettingsItem(title: 'Role Management'),
        const ClubSettingsItem(title: 'Pinned Content'),
        const ClubSettingsItem(
          title: 'Weekly Cycle',
          trailingText: 'Votes: Mon–Wed  ·  Watch: Fri',
        ),
        const ClubSettingsItem(title: 'Club Rules'),
        const ClubSettingsItem(title: 'Mute Notifications'),
        const SizedBox(height: 12),
        const Text('Report Community',
            style: TextStyle(
              color: Color(0xFFFFBE66),
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}


class ClubHeader extends StatelessWidget {
  const ClubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.local_movies_rounded, color: Color(0xFFFFD27D), size: 28),
        SizedBox(width: 8),
        Text(
          'Cinephiles Unite',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}


class ClubSettingsItem extends StatelessWidget {
  final String title;
  final String? trailingText;

  const ClubSettingsItem({
    super.key,
    required this.title,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailingText != null
              ? Text(
                  trailingText!,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                )
              : const Icon(Icons.chevron_right, color: Colors.white24),
          onTap: () {}, // Placeholder for functionality
        ),
        const Divider(color: Colors.white12, height: 0),
      ],
    );
  }
}
