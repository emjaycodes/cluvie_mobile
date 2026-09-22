// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Home Feed — CF-02/03
/// Sections: Active polls (vote CTA), Recent discussions (comment CTA), Upcoming watch parties (RSVP CTA)
/// Each with empty state + pull-to-refresh. Voting cards show ranked suggestions, vote counts, winner badge.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _pollEmpty = false;
  bool _discussionEmpty = false;

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(width: 32, height: 32, color: AppColors.accent, child: const Icon(Icons.movie, color: Colors.black, size: 18)),
          ),
          const SizedBox(width: 8),
          Text('CLUVIE', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        ]),
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () => context.push('/notifications')),
            Positioned(
              right: 8,
              top: 8,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
            ),
          ]),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Polls Section — with ranking + winner badge
              _SectionHeader(
                title: 'Active Polls',
                subtitle: 'Vote for this week’s pick',
                actionLabel: _pollEmpty ? null : 'View all',
                onAction: () => context.push('/communities/demo/vote'),
                onToggleEmpty: () => setState(() => _pollEmpty = !_pollEmpty),
              ),
              const SizedBox(height: 10),
              if (_pollEmpty)
                _EmptyCard(message: 'No active polls — suggest a film!', icon: Icons.how_to_vote_outlined, cta: 'Suggest', onCta: () => context.go('/suggest'))
              else ...[
                _VotingRankCard(),
                const SizedBox(height: 10),
                _VotingRankCard(isSecond: true),
              ],
              const SizedBox(height: 20),

              // Recent Discussions
              _SectionHeader(
                title: 'Recent Discussions',
                subtitle: 'Join the conversation',
                actionLabel: _discussionEmpty ? null : 'View all',
                onAction: () => context.push('/discussionThread'),
                onToggleEmpty: () => setState(() => _discussionEmpty = !_discussionEmpty),
              ),
              const SizedBox(height: 10),
              if (_discussionEmpty)
                _EmptyCard(message: 'No discussions yet — be the first to comment!', icon: Icons.chat_bubble_outline, cta: 'Start a thread', onCta: () => context.push('/discussionThread'))
              else ...[
                _DiscussionCard(
                  title: 'Oppenheimer',
                  subtitle: "Christopher Nolan's magnum opus. Thoughts?",
                  imageUrl: 'https://image.tmdb.org/t/p/w200/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
                  replies: 12,
                  isPinned: true,
                ),
                _DiscussionCard(
                  title: 'Mission: Impossible — Fallout',
                  subtitle: 'Most thrilling stunts ever filmed?',
                  imageUrl: 'https://image.tmdb.org/t/p/w200/74xTEgt7R36Fpooo50r9T25onhq.jpg',
                  replies: 5,
                ),
              ],
              const SizedBox(height: 20),

              // Upcoming Watch Parties — RSVP CTA
              _SectionHeader(title: 'Upcoming Watch Parties', subtitle: 'RSVP so hosts can plan', actionLabel: 'See all', onAction: () => context.push('/watch-parties')),
              const SizedBox(height: 10),
              _WatchPartyCard(
                title: 'Past Lives — Tomorrow 8PM',
                subtitle: 'Cinema Sundays · 9 attending',
                imageUrl: 'https://image.tmdb.org/t/p/w500/kAellTx1ukNtc42BP1kcnHPCG5e.jpg',
                rsvpLabel: 'RSVP',
                onRsvp: () => context.push('/watchParty'),
              ),
              const SizedBox(height: 10),
              _WatchPartyCard(
                title: 'The Zone of Interest — Oct 4',
                subtitle: 'A24 Lovers · 14 attending',
                imageUrl: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
                rsvpLabel: 'Maybe',
                onRsvp: () => context.push('/watchParty'),
              ),
              const SizedBox(height: 20),

              // Live Watch Party — polished timer card
              Text('Live Watch Party', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(children: [
                        Stack(alignment: Alignment.center, children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(value: 0.75, strokeWidth: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(AppColors.accent)),
                          ),
                          Text('23:05', style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 20)),
                        ]),
                        const SizedBox(height: 8),
                        Text('to watch', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                          child: Text('Join Live', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: 'https://image.tmdb.org/t/p/w300/74xTEgt7R36Fpooo50r9T25onhq.jpg',
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 120, height: 160, color: Colors.white)),
                        errorWidget: (_, __, ___) => Container(width: 120, height: 160, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white30)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Toggle for demo empty states (design QA helper — hidden in prod)
              Center(
                child: Text('Pull to refresh · Tap section titles to toggle empty states', style: AppTextStyles.caption.copyWith(color: Colors.white24, fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onToggleEmpty;
  const _SectionHeader({required this.title, required this.subtitle, this.actionLabel, this.onAction, this.onToggleEmpty});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onToggleEmpty,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
              Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
            ]),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final String cta;
  final VoidCallback onCta;
  const _EmptyCard({required this.message, required this.icon, required this.cta, required this.onCta});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(children: [
        Icon(icon, size: 36, color: Colors.white38),
        const SizedBox(height: 10),
        Text(message, style: AppTextStyles.body.copyWith(color: Colors.white70), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: onCta,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(cta, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _VotingRankCard extends StatelessWidget {
  final bool isSecond;
  const _VotingRankCard({this.isSecond = false});
  @override
  Widget build(BuildContext context) {
    // Ranked suggestions, vote counts, winner badge per spec
    final suggestions = isSecond
        ? [
            {'title': 'The Boy and the Heron', 'votes': 6, 'winner': true},
            {'title': 'Anatomy of a Fall', 'votes': 6, 'winner': false}, // tie -> earliest wins
            {'title': 'Poor Things', 'votes': 3, 'winner': false},
          ]
        : [
            {'title': 'Past Lives', 'votes': 9, 'winner': true},
            {'title': 'Oppenheimer', 'votes': 7, 'winner': false},
            {'title': 'Past Lives (tie)', 'votes': 2, 'winner': false},
          ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isSecond ? null : AppColors.cinematicGradient,
        color: isSecond ? AppColors.darkSurface : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSecond ? Colors.white10 : AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: isSecond ? Colors.white10 : Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
              child: Text(isSecond ? 'A24 Lovers · ends in 6h' : 'Cinema Sundays · ends in 18h', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text('${suggestions.fold<int>(0, (a, e) => a + (e['votes'] as int))} votes', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          ]),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isWinner = s['winner'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isWinner ? AppColors.accent.withOpacity(0.14) : Colors.white.withOpacity(isSecond ? 0.04 : 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isWinner ? AppColors.accent.withOpacity(0.5) : Colors.white12),
              ),
              child: Row(children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: isWinner ? AppColors.accent : Colors.white12, shape: BoxShape.circle),
                  child: Center(child: Text('${idx + 1}', style: TextStyle(color: isWinner ? Colors.black : Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s['title'] as String, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400, fontSize: 14))),
                if (isWinner)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                    child: Text('WINNER', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9)),
                  ),
                Text('${s['votes']} votes', style: AppTextStyles.caption.copyWith(color: isSecond ? AppColors.darkTextSecondary : Colors.white70, fontWeight: FontWeight.w700)),
              ]),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/communities/demo/vote'),
              style: ElevatedButton.styleFrom(backgroundColor: isSecond ? Colors.white : AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(isSecond ? 'Vote — tie needs your pick' : 'Vote now', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final int replies;
  final bool isPinned;
  const _DiscussionCard({required this.title, required this.subtitle, required this.imageUrl, required this.replies, this.isPinned = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isPinned ? AppColors.accent.withOpacity(0.35) : Colors.white10)),
      child: Row(children: [
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: imageUrl, width: 48, height: 64, fit: BoxFit.cover, placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 48, height: 64, color: Colors.white)), errorWidget: (_, __, ___) => Container(width: 48, height: 64, color: Colors.white10)),
          ),
          if (isPinned)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.push_pin, size: 10, color: Colors.black),
              ),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
              if (isPinned) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(6)), child: Text('PINNED', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text('$replies replies', style: AppTextStyles.caption.copyWith(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              Text('comment →', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _WatchPartyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String rsvpLabel;
  final VoidCallback onRsvp;
  const _WatchPartyCard({required this.title, required this.subtitle, required this.imageUrl, required this.rsvpLabel, required this.onRsvp});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(imageUrl: imageUrl, width: 56, height: 72, fit: BoxFit.cover, placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 56, height: 72, color: Colors.white)), errorWidget: (_, __, ___) => Container(width: 56, height: 72, color: Colors.white10)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 3),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.group, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text('RSVP to confirm', style: AppTextStyles.caption.copyWith(color: Colors.white38, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onRsvp,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(rsvpLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ]),
    );
  }
}
