import 'package:flutter/material.dart';

class DiscussionThreadScreen extends StatelessWidget {
  const DiscussionThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                'https://image.tmdb.org/t/p/w92/8FhKnPpql374qyyHAkZDld93IUw.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Past Lives', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: const [
          Icon(Icons.ios_share_outlined, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: const _DiscussionBody(),
    );
  }
}


class _DiscussionBody extends StatelessWidget {
  const _DiscussionBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: _CommentList()),
        _reactionBar([
          {'emoji': '❤️', 'count': 4},
          {'emoji': '🔥', 'count': 3},
          {'emoji': '👍', 'count': 3},
          {'emoji': '😊', 'count': 3},
        ]),
        const _CommentInput(),
      ],
    );
  }
}


class _CommentList extends StatelessWidget {
  const _CommentList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: const [
        _CommentBubble(
          name: 'Jenny Wilson',
          avatar: 'https://randomuser.me/api/portraits/women/1.jpg',
          timeAgo: '5 h',
          comment: 'What a beautiful, melancholy film. The final scene will stay with me forever...',
          reactions: [
            {'emoji': '😍', 'count': 4},
            {'emoji': '🥲', 'count': 4},
            {'emoji': '❤️', 'count': 4},
          ],
        ),
        _CommentBubble(
          name: 'Savannah Nguyen',
          avatar: 'https://randomuser.me/api/portraits/women/2.jpg',
          timeAgo: '2 h',
          comment: 'That last shot through the window — I had chills! What an ending 😉',
        ),
        _CommentBubble(
          name: 'Noah Lee',
          avatar: '',
          timeAgo: '1 h',
          comment: 'Agreed, the acting was so incredibly subtle and powerful.',
        ),
        _CommentBubble(
          name: 'Eleanor Pena',
          avatar: 'https://randomuser.me/api/portraits/women/3.jpg',
          timeAgo: '3 h',
          comment: 'Loved the theme of ’In Yun’! Gave the film such a deep, soulful meaning.',
          reactions: [
            {'emoji': '❤️', 'count': 4},
            {'emoji': '🔥', 'count': 3},
            {'emoji': '👍', 'count': 3},
            {'emoji': '😊', 'count': 3},
          ],
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final String name;
  final String avatar;
  final String timeAgo;
  final String comment;
  final List<Map<String, dynamic>>? reactions;

  const _CommentBubble({
    required this.name,
    required this.avatar,
    required this.timeAgo,
    required this.comment,
    this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avatar.isNotEmpty)
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(avatar),
            )
          else
            const CircleAvatar(radius: 18, backgroundColor: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A122A),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(comment, style: const TextStyle(color: Colors.white70)),
                  if (reactions != null && reactions!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: reactions!
                          .map((r) => Chip(
                                label: Text('${r['emoji']} ${r['count']}'),
                                backgroundColor: Colors.white10,
                                labelStyle: const TextStyle(color: Colors.white),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(timeAgo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}


Widget _reactionBar(List<Map<String, dynamic>> reactions) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Wrap(
      spacing: 8,
      children: reactions
          .map((r) => Chip(
                label: Text('${r['emoji']} ${r['count']}'),
                backgroundColor: Colors.white10,
                labelStyle: const TextStyle(color: Colors.white),
              ))
          .toList(),
    ),
  );
}

class _CommentInput extends StatelessWidget {
  const _CommentInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 12),
      color: const Color(0xFF0D0D0F),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions_outlined, color: Colors.white30),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A122A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.send, color: Colors.white),
        ],
      ),
    );
  }
}

