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

/// Voting + Poll lifecycle — CF-06
/// Route: /communities/:id/vote
/// Poll lifecycle: expiresAt/status, winner = highest votes tie=earliest, vote summary screen.
/// Shows ranked suggestions, vote counts, winner badge.
class VoteSummaryScreen extends StatefulWidget {
  final String? communityId;
  const VoteSummaryScreen({super.key, this.communityId});
  @override
  State<VoteSummaryScreen> createState() => _VoteSummaryScreenState();
}

class _VoteSummaryScreenState extends State<VoteSummaryScreen> {
  final _api = ApiClient();
  late List<Map<String, dynamic>> _suggestions;
  String _status = 'open'; // open | closed | resolved
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 18));

  @override
  void initState() {
    super.initState();
    _suggestions = [
      {'id': '1', 'title': 'Past Lives', 'year': '2023', 'poster': 'https://image.tmdb.org/t/p/w200/kAellTx1ukNtc42BP1kcnHPCG5e.jpg', 'votes': 9, 'voters': ['u1', 'u2'], 'createdAt': DateTime.now().subtract(const Duration(hours: 20))},
      {'id': '2', 'title': 'Oppenheimer', 'year': '2023', 'poster': 'https://image.tmdb.org/t/p/w200/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', 'votes': 7, 'voters': ['u3'], 'createdAt': DateTime.now().subtract(const Duration(hours: 18))},
      {'id': '3', 'title': 'The Zone of Interest', 'year': '2023', 'poster': 'https://image.tmdb.org/t/p/w200/hUu9zyZmDd8VZegKi1iK1Vk0RYS.jpg', 'votes': 7, 'voters': ['u4'], 'createdAt': DateTime.now().subtract(const Duration(hours: 10))}, // tie -> earlier wins, so Oppenheimer wins tie
      {'id': '4', 'title': 'Poor Things', 'year': '2023', 'poster': 'https://image.tmdb.org/t/p/w200/kCGlIMHnOm8JPXq3rXM84hre9Mh.jpg', 'votes': 2, 'voters': [], 'createdAt': DateTime.now().subtract(const Duration(hours: 5))},
    ];
    _sortAndResolve();
  }

  void _sortAndResolve() {
    // winner = highest votes, tie = earliest createdAt
    _suggestions.sort((a, b) {
      final va = a['votes'] as int;
      final vb = b['votes'] as int;
      if (vb != va) return vb.compareTo(va);
      return (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime);
    });
  }

  String get _winnerId => _suggestions.isNotEmpty ? _suggestions.first['id'] as String : '';

  Duration get _remaining => _expiresAt.difference(DateTime.now());

  Future<void> _toggleVote(int index) async {
    if (_status != 'open') {
      ClSnackbar.show(context, message: 'Poll is $_status — voting closed', type: ClSnackbarType.warning);
      return;
    }
    final s = _suggestions[index];
    final hasVoted = (s['voters'] as List).contains('me');
    setState(() {
      if (hasVoted) {
        s['voters'].remove('me');
        s['votes'] = (s['votes'] as int) - 1;
      } else {
        s['voters'].add('me');
        s['votes'] = (s['votes'] as int) + 1;
      }
    });
    _sortAndResolve();
    setState(() {});
    ClSnackbar.show(context, message: hasVoted ? 'Vote removed' : 'Voted for "${s['title']}"', type: ClSnackbarType.success);
    try {
      await _api.post('/movies/${s['id']}/vote');
    } catch (_) {
      // rollback
      if (mounted) {
        setState(() {
          if (hasVoted) {
            s['voters'].add('me');
            s['votes'] = (s['votes'] as int) + 1;
          } else {
            s['voters'].remove('me');
            s['votes'] = (s['votes'] as int) - 1;
          }
        });
        _sortAndResolve();
        setState(() {});
        ClSnackbar.show(context, message: "Couldn't vote — restored", type: ClSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.clamp(0, 999);
    final mins = (_remaining.inMinutes % 60).clamp(0, 59);
    return Scaffold(
      appBar: AppBar(
        title: Text('Voting', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _status == 'open' ? AppColors.success.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _status == 'open' ? AppColors.success : AppColors.warning),
            ),
            child: Text(_status == 'open' ? 'OPEN · ${hours}h ${mins}m left' : _status.toUpperCase(), style: AppTextStyles.caption.copyWith(color: _status == 'open' ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) setState(() => _expiresAt = DateTime.now().add(const Duration(hours: 18)));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: AppColors.cinematicGradient, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Weekly Pick — ${widget.communityId ?? 'Cinema Sundays'}', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Poll closes ${_expiresAt.toLocal().toString().split(' ').first} · Winner = highest votes, tie = earliest suggestion', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ClButton(label: 'Close poll early', onPressed: () => setState(() => _status = 'resolved'), isSecondary: true)),
                  const SizedBox(width: 10),
                  Expanded(child: ClButton(label: 'Share', onPressed: () {})),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Ranked Suggestions', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Tap Vote to toggle until expiry', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
            const SizedBox(height: 12),
            ..._suggestions.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isWinner = s['id'] == _winnerId;
              final hasVoted = (s['voters'] as List).contains('me');
              final rank = idx + 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isWinner ? AppColors.accent.withOpacity(0.10) : AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isWinner ? AppColors.accent.withOpacity(0.5) : Colors.white10),
                ),
                child: Row(children: [
                  // rank + poster
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: s['poster'],
                        width: 64,
                        height: 84,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 64, height: 84, color: Colors.white)),
                        errorWidget: (_, __, ___) => Container(width: 64, height: 84, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white30)),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: isWinner ? AppColors.accent : Colors.black.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                        child: Center(child: Text('$rank', style: TextStyle(color: isWinner ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(s['title'], style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
                        if (isWinner)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                            child: Text('WINNER', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9)),
                          ),
                      ]),
                      Text('${s['year']} · ${s['votes']} votes', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        // voter avatars
                        SizedBox(
                          width: 60,
                          height: 22,
                          child: Stack(
                            children: List.generate((s['voters'] as List).length.clamp(0, 3), (i) => Positioned(left: i * 14, child: CircleAvatar(radius: 11, backgroundColor: Colors.white, child: CircleAvatar(radius: 10, backgroundImage: CachedNetworkImageProvider('https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${30 + i}.jpg'))))),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: () => _toggleVote(idx),
                            style: ElevatedButton.styleFrom(backgroundColor: hasVoted ? AppColors.accent : Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: Text(hasVoted ? 'Voted ✓' : 'Vote', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 14),
            if (_status == 'resolved')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Poll resolved — winner is "${_suggestions.first['title']}". Next: discuss or schedule watch party.', style: AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.w700))),
                ]),
              ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => context.push('/discussionThread'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: AppColors.accent.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Discuss'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => context.push('/watchParty'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Schedule Watch Party', style: TextStyle(fontWeight: FontWeight.w800)))),
            ]),
            const SizedBox(height: 8),
            Center(child: Text('Winner logic: highest votes, tie = earliest suggestion · Status: $_status · expiresAt: ${_expiresAt.toLocal()}', style: AppTextStyles.caption.copyWith(color: Colors.white24, fontSize: 10), textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
