// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Movie Detail — CF-03
/// Poster, title, year, overview, TMDB rating, Cluvie votes/engagementScore,
/// actions Suggest + Add to Watchlist with optimistic UI.
class MovieDetailScreen extends StatefulWidget {
  final String? movieId;
  const MovieDetailScreen({super.key, this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _api = ApiClient();
  bool _inWatchlist = false;
  bool _watchlistLoading = false;
  bool _suggestLoading = false;
  int _cluvieVotes = 42;
  double _engagement = 8.4;
  bool _stale = false;

  Future<void> _toggleWatchlist() async {
    final prev = _inWatchlist;
    setState(() {
      _inWatchlist = !_inWatchlist;
      _watchlistLoading = true;
    });
    ClSnackbar.show(context, message: _inWatchlist ? 'Added to Watchlist' : 'Removed from Watchlist', type: ClSnackbarType.success);
    try {
      if (_inWatchlist) {
        await _api.post('/watchlist', data: {'tmdbId': widget.movieId ?? '550', 'title': 'Everything Everywhere All At Once'});
      } else {
        await _api.delete('/watchlist/${widget.movieId ?? '550'}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _inWatchlist = prev);
        ClSnackbar.show(context, message: "Couldn't update Watchlist — restored", type: ClSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _watchlistLoading = false);
    }
  }

  Future<void> _suggest() async {
    setState(() => _suggestLoading = true);
    // optimistic
    setState(() => _cluvieVotes += 1);
    ClSnackbar.show(context, message: 'Suggested to Cinema Sundays ✓', type: ClSnackbarType.success);
    try {
      await _api.post('/communities/demo/suggest', data: {'tmdbId': widget.movieId ?? '550'});
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {
      if (mounted) {
        setState(() => _cluvieVotes -= 1);
        ClSnackbar.show(context, message: "Couldn't suggest — tap to retry", type: ClSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _suggestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
            actions: [
              IconButton(icon: Icon(_inWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _inWatchlist ? AppColors.accent : Colors.white), onPressed: _toggleWatchlist),
              IconButton(icon: const Icon(Icons.ios_share_rounded, color: Colors.white), onPressed: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade900, highlightColor: Colors.grey.shade800, child: Container(color: Colors.white)),
                  errorWidget: (_, __, ___) => Container(color: AppColors.darkSurface),
                ),
                Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.65), Colors.transparent, Colors.black.withOpacity(0.75)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                      child: Text('A24 · WINNER', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                    const SizedBox(height: 8),
                    Text('Everything Everywhere All At Once', style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 26, height: 1.1)),
                    const SizedBox(height: 6),
                    Text('2022 · 139 min · Sci-Fi · 12 votes · Engagement $_engagement', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  ]),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_stale)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.14), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning.withOpacity(0.4))),
                      child: Row(children: [const Icon(Icons.cloud_off, size: 14, color: AppColors.warning), const SizedBox(width: 8), Text('Using cached data', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700))]),
                    ),
                  const SizedBox(height: 10),
                  // Rating row — TMDB + Cluvie
                  Row(children: [
                    _RatingPill(icon: Icons.star_rounded, label: 'Cluvie', score: '$_cluvieVotes votes', color: AppColors.accent),
                    const SizedBox(width: 8),
                    _RatingPill(icon: Icons.movie_rounded, label: 'TMDB', score: '7.8 ★', color: Colors.white70),
                    const SizedBox(width: 8),
                    _RatingPill(icon: Icons.bolt_rounded, label: 'Engagement', score: '$_engagement', color: AppColors.success),
                  ]),
                  const SizedBox(height: 14),
                  // Actions — Suggest + Watchlist with optimistic UI
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _suggestLoading ? null : _suggest,
                        icon: _suggestLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.add_rounded, size: 18),
                        label: Text(_suggestLoading ? 'Suggesting…' : 'Suggest to Club', style: const TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _watchlistLoading ? null : _toggleWatchlist,
                        icon: Icon(_inWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 18),
                        label: Text(_inWatchlist ? 'In Watchlist' : 'Add to Watchlist', style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(foregroundColor: _inWatchlist ? AppColors.accent : Colors.white, side: BorderSide(color: _inWatchlist ? AppColors.accent : Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Text('Overview', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'A Chinese immigrant gets unwillingly embroiled in an epic adventure where she must connect different versions of herself in the parallel universe to stop someone who intends to harm the multiverse.',
                    style: AppTextStyles.body.copyWith(color: AppColors.darkTextSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: const [
                    _TagChip(label: '#Comedy'),
                    _TagChip(label: '#LGBTQ+'),
                    _TagChip(label: '#IndieFilm'),
                    _TagChip(label: '#ScienceFiction'),
                  ]),
                  const SizedBox(height: 24),
                  Text('Cast & Crew', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => Column(children: [
                        CircleAvatar(radius: 28, backgroundImage: CachedNetworkImageProvider('https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${40 + i}.jpg')),
                        const SizedBox(height: 6),
                        Text(['Ke Huy Quan', 'Michelle Yeoh', 'Stephanie Hsu', 'James Hong'][i], style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Text('Discussion', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
                    const Spacer(),
                    TextButton(onPressed: () => context.push('/discussionThread'), child: Text('Open thread →', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
                  ]),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Row(children: [
                      const CircleAvatar(backgroundImage: CachedNetworkImageProvider('https://randomuser.me/api/portraits/women/68.jpg'), radius: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Favorite scene?', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('The ocean swim with Kevin — so tender.', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white30),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.push('/discussionThread'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: AppColors.accent.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('View 12 comments'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String score;
  final Color color;
  const _RatingPill({required this.icon, required this.label, required this.score, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text('$label $score', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))]),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.cinematicPurple, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
