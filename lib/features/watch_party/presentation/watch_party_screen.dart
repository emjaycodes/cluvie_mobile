import 'package:flutter/material.dart';

class WatchPartyScreen extends StatelessWidget {
  const WatchPartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: const [
              _TopBar(),
              SizedBox(height: 24),
              Expanded(child: _AvatarSection()),
              _ControlPanel(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('Arrival',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        Text(
          '0:42:16 remaining',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const EmojiReactionBar(),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: const [
                VoiceAvatar(
                  imageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
                  isSpeaking: true,
                ),
                VoiceAvatar(
                  imageUrl: 'https://randomuser.me/api/portraits/men/65.jpg',
                  isMuted: true,
                ),
                VoiceAvatar(
                  imageUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
                ),
                VoiceAvatar(
                  imageUrl: 'https://randomuser.me/api/portraits/women/42.jpg',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class VoiceAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isSpeaking;
  final bool isMuted;

  const VoiceAvatar({
    super.key,
    required this.imageUrl,
    this.isSpeaking = false,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: isSpeaking ? const EdgeInsets.all(3) : EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSpeaking ? Border.all(color: Colors.purpleAccent, width: 2) : null,
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(imageUrl),
          ),
        ),
        if (isMuted)
          const Positioned(
            bottom: 4,
            right: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black87,
              child: Icon(Icons.mic_off, size: 14, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}


class EmojiReactionBar extends StatelessWidget {
  const EmojiReactionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('😍', style: TextStyle(fontSize: 30)),
        SizedBox(width: 12),
        Text('😧', style: TextStyle(fontSize: 30)),
        SizedBox(width: 12),
        Text('🥲', style: TextStyle(fontSize: 30)),
      ],
    );
  }
}


class _ControlPanel extends StatelessWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            ControlButton(icon: Icons.mic_off),
            SizedBox(width: 16),
            ControlButton(icon: Icons.message),
            SizedBox(width: 16),
            ControlButton(icon: Icons.local_fire_department),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Icon(Icons.volume_up, color: Colors.white),
              Icon(Icons.chat_bubble_outline, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }
}



class ControlButton extends StatelessWidget {
  final IconData icon;

  const ControlButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white12,
      radius: 24,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
