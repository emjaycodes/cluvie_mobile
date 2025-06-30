import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('CLUVIE', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ListView(
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/79.jpg',),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Charlottie Cooper',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const Center(
              child: Text(
                'Ada. Indie. True stories win me.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _ProfileStat(label: 'Films watched', value: '137'),
                _ProfileStat(label: 'Threads started', value: '42'),
                _ProfileStat(label: 'Avg vote rating', value: '4.5★'),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Recent Votes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 16),
            _buildVoteCard('Everything everywhere at once', 5, 'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg'),
            _buildVoteCard('Stale Summer 2099', 4, 'https://image.tmdb.org/t/p/w500//yF1eOkaYvwiORauRCPWznV9xVvi.jpg'),
            const SizedBox(height: 24),
            const Text('Discussion Threads', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),
            _buildDiscussionThread('Past Lives', 'My heart ached 🥲', 5),
            _buildDiscussionThread('Manhattan', 'I loved the unspoken feelings', 12),
            _buildDiscussionThread('Jackie', 'The cinematograp by incredible!', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteCard(String title, int stars, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                )
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildDiscussionThread(String title, String message, int replies) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(message, style: const TextStyle(color: Colors.white60)),
      trailing: Text('$replies', style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
