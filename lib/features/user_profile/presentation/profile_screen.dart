// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_avatar.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Profile + Watchlist — CF-02
/// Shows avatar, bio, XP/followers/watchlist, follow graph, editable fields, follower counts.
/// Watchlist CRUD via GET /api/watchlist with pop + empty CTA.
class UserProfileScreen extends StatefulWidget {
  final String? userId;
  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _api = ApiClient();
  bool _isEditing = false;
  final _bioCtrl = TextEditingController(text: 'Ada. Indie. True stories win me.');
  final _nameCtrl = TextEditingController(text: 'Charlottie Cooper');

  // Demo watchlist — would be from GET /api/watchlist
  List<Map<String, dynamic>> _watchlist = [
    {'title': 'Past Lives', 'year': '2023', 'poster': 'https://image.tmdb.org/t/p/w200/kAellTx1ukNtc42BP1kcnHPCG5e.jpg'},
    {'title': 'Oppenheimer', 'year': '2023', 'poster': 'https://image.tmdb.org/t/p/w200/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg'},
  ];
  bool _watchlistLoading = false;
  int _followers = 248;
  int _following = 86;
  bool _isFollowing = false;
  int _xp = 1240;

  Future<void> _loadWatchlist() async {
    setState(() => _watchlistLoading = true);
    try {
      final res = await _api.get('/watchlist');
      final data = res.data is List ? res.data as List : (res.data['watchlist'] ?? res.data['movies'] ?? []) as List;
      if (data.isNotEmpty && mounted) {
        setState(() => _watchlist = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {
      // keep demo data
    } finally {
      if (mounted) setState(() => _watchlistLoading = false);
    }
  }

  Future<void> _removeFromWatchlist(int index) async {
    final removed = _watchlist[index];
    setState(() => _watchlist.removeAt(index));
    ClSnackbar.show(context, message: 'Removed "${removed['title']}"', type: ClSnackbarType.success);
    try {
      await _api.delete('/watchlist/${removed['id'] ?? removed['tmdbId'] ?? ''}');
    } catch (_) {
      // rollback on failure
      if (mounted) {
        setState(() => _watchlist.insert(index, removed));
        ClSnackbar.show(context, message: "Couldn't remove — restored", type: ClSnackbarType.error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.userId == null;
    return Scaffold(
      appBar: AppBar(
        leading: isOwnProfile ? null : const BackButton(color: Colors.white),
        automaticallyImplyLeading: isOwnProfile ? false : true,
        title: Text(isOwnProfile ? 'CLUVIE' : 'Profile', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (isOwnProfile)
            TextButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              child: Text(_isEditing ? 'Done' : 'Edit', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isFollowing = !_isFollowing;
                    _followers += _isFollowing ? 1 : -1;
                  });
                  ClSnackbar.show(context, message: _isFollowing ? 'Following' : 'Unfollowed', type: ClSnackbarType.success);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _isFollowing ? Colors.white12 : AppColors.accent, foregroundColor: _isFollowing ? Colors.white : Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadWatchlist,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Avatar + name + bio — editable fields
            Center(
              child: Stack(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: const CachedNetworkImageProvider('https://randomuser.me/api/portraits/women/79.jpg'),
                ),
                if (_isEditing)
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 14, color: Colors.black))),
              ]),
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.darkSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.darkSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ] else ...[
              Center(child: Text(_nameCtrl.text, style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 22))),
              Center(child: Text(_bioCtrl.text, style: AppTextStyles.body.copyWith(color: Colors.white60), textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 14),
            // XP + followers + watchlist counts
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Row(children: [
                _Stat(label: 'XP', value: '$_xp', icon: Icons.bolt_rounded, color: AppColors.accent),
                _DividerVert(),
                _Stat(label: 'Followers', value: '$_followers', icon: Icons.people_rounded, color: AppColors.success),
                _DividerVert(),
                _Stat(label: 'Following', value: '$_following', icon: Icons.person_add_rounded, color: Colors.white70),
                _DividerVert(),
                _Stat(label: 'Watchlist', value: '${_watchlist.length}', icon: Icons.bookmark_rounded, color: AppColors.warning),
              ]),
            ),
            const SizedBox(height: 12),
            // Follow graph preview
            Row(children: [
              Text('Follow graph', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(onPressed: () {}, child: Text('View all', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
            ]),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => Column(children: [
                  CircleAvatar(radius: 26, backgroundImage: CachedNetworkImageProvider('https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${20 + i}.jpg')),
                  const SizedBox(height: 4),
                  Text(['Ava', 'Ben', 'Carmen', 'Dev', 'Mina', 'Leo'][i], style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            // XP bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: AppColors.cinematicGradient, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Level 7 — Cinephile', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('$_xp / 1500 XP', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: _xp / 1500, minHeight: 8, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(AppColors.accent)),
                ),
                const SizedBox(height: 6),
                Text('12 XP to next badge · Vote or comment to earn', style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 20),

            // Watchlist CRUD — GET /api/watchlist with pop + empty CTA
            Row(children: [
              Text('Watchlist', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
              const Spacer(),
              if (_watchlistLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white54, size: 18), onPressed: _loadWatchlist),
            ]),
            const SizedBox(height: 8),
            if (_watchlist.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                child: Column(children: [
                  const ClEmptyState(message: 'Your watchlist is empty.\nAdd films from Discover to save for later.', icon: Icons.bookmark_border_rounded),
                  const SizedBox(height: 14),
                  ClButton(label: 'Discover Movies', onPressed: () => context.go('/discover')),
                ]),
              )
            else
              ..._watchlist.asMap().entries.map((e) {
                final idx = e.key;
                final m = e.value;
                return Dismissible(
                  key: ValueKey(m['title']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeFromWatchlist(idx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: m['poster'],
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 50, height: 70, color: Colors.white)),
                          errorWidget: (_, __, ___) => Container(width: 50, height: 70, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white30)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['title'], style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(m['year'], style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: Text('Cluvie 4.8', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 11))),
                            const SizedBox(width: 6),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: Text('TMDB 7.4', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 11))),
                          ]),
                        ]),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white30, size: 18), onPressed: () => _removeFromWatchlist(idx)),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 22),

            // Recent Votes — existing UI preserved
            Text('Recent Votes', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            _VoteCard(title: 'Everything Everywhere All At Once', stars: 5, imageUrl: 'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg'),
            _VoteCard(title: 'Past Lives', stars: 4, imageUrl: 'https://image.tmdb.org/t/p/w500/kAellTx1ukNtc42BP1kcnHPCG5e.jpg'),
            const SizedBox(height: 16),
            // Sign out
            if (isOwnProfile) ...[
              OutlinedButton(
                onPressed: () => context.go('/welcome'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _VoteCard({required String title, required int stars, required String imageUrl}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: imageUrl, width: 50, height: 50, fit: BoxFit.cover, placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 50, height: 50, color: Colors.white)), errorWidget: (_, __, ___) => Container(width: 50, height: 50, color: Colors.white10))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: List.generate(5, (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Colors.white30),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16)),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary, fontSize: 10)),
      ]),
    );
  }
}

class _DividerVert extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white10);
}
