import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class ClubSettingsScreen extends StatelessWidget {
  const ClubSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F), // Night Slate
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Header(),
              SizedBox(height: 12),
              _LeaveClubButton(),
              SizedBox(height: 24),
              _SettingItem(label: 'Edit club Name'),
              _SettingItem(label: 'Change Cover Image'),
              _SettingItem(label: 'Membership', trailing: Text('Open to everyone', style: TextStyle(color: Colors.white38))),
              _SettingItem(label: 'Role Management'),
              _SettingItem(label: 'Pinned Content'),
              _SettingItem(
                label: 'Weekly Cycle',
                trailing: Text('Votes: Mon-Wed • Watch: Fri', style: TextStyle(color: Colors.white38)),
              ),
              _SettingItem(label: 'Club Rules'),
              _SettingItem(label: 'Mute Notifications', hasArrow: true),
              Spacer(),
              _ReportButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.movie_filter, size: 30, color: Color(0xFFFFD27D)), // Gold Accent
        SizedBox(width: 12),
        Text(
          'Cinephiles Unite',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final bool hasArrow;

  const _SettingItem({
    super.key,
    required this.label,
    this.trailing,
    this.hasArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white12, height: 1),
        ListTile(
          title: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          trailing: trailing ??
              (hasArrow
                  ? const Icon(Icons.chevron_right, color: Colors.white38)
                  : null),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
class _ReportButton extends StatelessWidget {
  const _ReportButton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Text(
        'Report club',
        style: TextStyle(
          color: Color(0xFFFFD27D), // Gold Accent for warning
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LeaveClubButton extends StatelessWidget {
  const _LeaveClubButton();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Leave Club',
      style: TextStyle(
        color: AppColors.softRed, 
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
