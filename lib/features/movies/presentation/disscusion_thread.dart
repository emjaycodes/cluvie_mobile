// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:flutter/material.dart';

/// Discussion — CF-07
/// Threaded comments paginated newest-first, author/timestamp/body/reaction counts,
/// "Be the first to comment", pull-to-refresh + infinite scroll, reactions ❤️👍😂😮 with toggle,
/// pinned badge sorts first.
class DiscussionThreadScreen extends StatefulWidget {
  final String? communityId;
  const DiscussionThreadScreen({super.key, this.communityId});

  @override
  State<DiscussionThreadScreen> createState() => _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends State<DiscussionThreadScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isLoadingMore = false;
  int _page = 1;

  // Demo threaded comments — pinned sorts first, newest-first otherwise
  late List<Map<String, dynamic>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      {
        'id': 'p1',
        'author': 'Carmen (Host)',
        'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
        'body': '📌 Pinned — Please keep spoilers tagged. Watch party tomorrow 8pm — RSVP in the Watch tab!',
        'time': '1d ago',
        'pinned': true,
        'reactions': {'❤️': 8, '👍': 5},
        'myReactions': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': 'c3',
        'author': 'Noah Lee',
        'avatar': '',
        'body': 'Agreed, the acting was so incredibly subtle and powerful.',
        'time': '1h ago',
        'pinned': false,
        'reactions': <String, int>{},
        'myReactions': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      },
      {
        'id': 'c2',
        'author': 'Savannah Nguyen',
        'avatar': 'https://randomuser.me/api/portraits/women/2.jpg',
        'body': 'That last shot through the window — I had chills! What an ending 😉',
        'time': '2h ago',
        'pinned': false,
        'reactions': {'🔥': 3, '😮': 2},
        'myReactions': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'c1',
        'author': 'Jenny Wilson',
        'avatar': 'https://randomuser.me/api/portraits/women/1.jpg',
        'body': 'What a beautiful, melancholy film. The final scene will stay with me forever...',
        'time': '5h ago',
        'pinned': false,
        'reactions': {'😍': 4, '🥲': 4, '❤️': 4},
        'myReactions': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': 'c0',
        'author': 'Eleanor Pena',
        'avatar': 'https://randomuser.me/api/portraits/women/3.jpg',
        'body': "Loved the theme of 'In Yun'! Gave the film such a deep, soulful meaning.",
        'time': '3h ago',
        'pinned': false,
        'reactions': {'❤️': 4, '🔥': 3, '👍': 3, '😊': 3},
        'myReactions': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      },
    ];
    _sort();
    _scrollCtrl.addListener(_onScroll);
  }

  void _sort() {
    _comments.sort((a, b) {
      final pa = a['pinned'] as bool;
      final pb = b['pinned'] as bool;
      if (pa != pb) return pa ? -1 : 1;
      return (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime);
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120 && !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _comments.add({
        'id': 'more_${_page}',
        'author': 'Alex Rivera',
        'avatar': 'https://randomuser.me/api/portraits/men/${20 + _page}.jpg',
        'body': 'Page $_page — infinite scroll demo. Real app paginates newest-first via GET /api/comments?communityId=&page=$_page',
        'time': '${_page + 1}h ago',
        'pinned': false,
        'reactions': {'👍': 1},
        'myReactions': <String>[],
        'createdAt': DateTime.now().subtract(Duration(hours: 6 + _page)),
      });
      _page++;
      _isLoadingMore = false;
      _sort();
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _page = 1;
      _sort();
    });
  }

  void _toggleReaction(int idx, String emoji) {
    setState(() {
      final c = _comments[idx];
      final reactions = c['reactions'] as Map<String, int>;
      final mine = c['myReactions'] as List<String>;
      if (mine.contains(emoji)) {
        mine.remove(emoji);
        reactions[emoji] = (reactions[emoji] ?? 1) - 1;
        if (reactions[emoji]! <= 0) reactions.remove(emoji);
      } else {
        mine.add(emoji);
        reactions[emoji] = (reactions[emoji] ?? 0) + 1;
      }
    });
  }

  void _post() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text.length > 2000) return;
    setState(() {
      _comments.insert(0, {
        'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
        'author': 'You',
        'avatar': 'https://randomuser.me/api/portraits/women/79.jpg',
        'body': text,
        'time': 'now',
        'pinned': false,
        'reactions': <String, int>{},
        'myReactions': <String>[],
        'createdAt': DateTime.now(),
      });
      _sort();
      // keep pinned at top: if new comment is not pinned, it goes just after pinned
      // _sort already does this
    });
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w92/8FhKnPpql374qyyHAkZDld93IUw.jpg', width: 28, height: 28, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Text('Past Lives', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          if (widget.communityId != null) ...[
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)), child: Text(widget.communityId!, style: AppTextStyles.caption.copyWith(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800))),
          ],
        ]),
        actions: const [Icon(Icons.ios_share_outlined, color: Colors.white), SizedBox(width: 12)],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _refresh,
              child: _comments.isEmpty
                  ? ListView(children: const [SizedBox(height: 60), ClEmptyState(message: 'Be the first to comment', icon: Icons.chat_bubble_outline_rounded)])
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _comments.length) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)));
                        }
                        final c = _comments[i];
                        final isPinned = c['pinned'] as bool;
                        final reactions = c['reactions'] as Map<String, int>;
                        final mine = c['myReactions'] as List<String>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isPinned ? AppColors.accent.withOpacity(0.08) : const Color(0xFF1A122A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isPinned ? AppColors.accent.withOpacity(0.35) : Colors.white10),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                (c['avatar'] as String).isNotEmpty
                                    ? CircleAvatar(radius: 16, backgroundImage: CachedNetworkImageProvider(c['avatar']))
                                    : const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 14, color: Colors.white)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Text(c['author'], style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                      if (isPinned) ...[
                                        const SizedBox(width: 6),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)), child: Text('PINNED', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9))),
                                      ],
                                      const Spacer(),
                                      Text(c['time'], style: AppTextStyles.caption.copyWith(color: Colors.white54, fontSize: 11)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(c['body'], style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 13)),
                                  ]),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ...reactions.entries.map((e) => GestureDetector(
                                        onTap: () => _toggleReaction(i, e.key),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: mine.contains(e.key) ? AppColors.accent.withOpacity(0.18) : Colors.white10,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: mine.contains(e.key) ? AppColors.accent.withOpacity(0.5) : Colors.white12),
                                          ),
                                          child: Text('${e.key} ${e.value}', style: AppTextStyles.caption.copyWith(color: mine.contains(e.key) ? AppColors.accent : Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                                        ),
                                      )),
                                  // add reaction
                                  ...['❤️', '👍', '😂', '😮'].where((em) => !reactions.containsKey(em)).take(2).map((em) => GestureDetector(
                                        onTap: () => _toggleReaction(i, em),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                                          child: Text(em, style: const TextStyle(fontSize: 12)),
                                        ),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          // reaction bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.black.withOpacity(0.15),
            child: Row(children: [
              Text('Tap a reaction to toggle:', style: AppTextStyles.caption.copyWith(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 8),
              ...['❤️', '👍', '😂', '😮'].map((em) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Text(em, style: const TextStyle(fontSize: 14))),
                  )),
            ]),
          ),
          // input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(color: const Color(0xFF0E0C1E), border: Border(top: BorderSide(color: Colors.white10))),
            child: Row(children: [
              const Icon(Icons.emoji_emotions_outlined, color: Colors.white30, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 2000,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts... (1–2000 chars)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1A122A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _post(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _post,
                child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.black, size: 16)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
