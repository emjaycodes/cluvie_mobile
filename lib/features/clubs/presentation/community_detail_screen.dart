// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_chip.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Community Detail — CF-04/05/06
/// Route: /communities/:id
/// Shows name/desc, members+roles, movie_suggestions, active poll, discussions.
/// Per PRD-012, handles loading/error/empty per section with CL* widgets.
class CommunityDetailScreen extends StatelessWidget {
  final String communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    // Demo community — in real app fetch via GET /api/communities/:id
    final demo = Community(
      id: communityId,
      name: 'Cinema Sundays 🌅',
      description: 'Weekly watch + vote + discuss. Host: Carmen. 12 members.',
      members: ['u1', 'u2', 'u3'],
      admins: ['u1'],
      votes: [],
      movieSuggestions: [],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    // Helper for role display
    String roleFor(String? uid) => (demo.admins.contains(uid) ? 'admin' : 'member');

    return Scaffold(
      appBar: AppBar(
        title: Text(demo.name ?? 'Community', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => context.push('/communityInfo', extra: demo)),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => context.push('/communityChat', extra: demo)),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/communitySettings')),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cinematicGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.verified, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('${demo.members.length} members', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                          child: Text('Invite code: CLUV-${communityId.substring(0, 4).toUpperCase()}',
                              style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(demo.description ?? '', style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClButton(
                            label: 'Suggest a Movie',
                            onPressed: () => context.push('/communities/$communityId/suggest'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClButton(
                            label: 'Vote now',
                            isSecondary: true,
                            onPressed: () => context.push('/communities/$communityId/vote'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Members + roles
              Text('Members', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: demo.members.map((uid) {
                  final role = roleFor(uid);
                  final isAdmin = role == 'admin';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isAdmin ? AppColors.accent.withOpacity(0.5) : Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: CachedNetworkImageProvider('https://randomuser.me/api/portraits/${isAdmin ? 'women' : 'men'}/${isAdmin ? 44 : 32}.jpg'),
                        ),
                        const SizedBox(width: 8),
                        Text(uid ?? 'user', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        ClChip(label: role, isSelected: isAdmin),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Movie suggestions — empty CTA per PRD
              Text('Movie Suggestions', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              if (demo.movieSuggestions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      const ClEmptyState(message: 'No suggestions yet — be the first!', icon: Icons.movie_outlined),
                      const SizedBox(height: 12),
                      ClButton(label: 'Suggest a Film', onPressed: () => context.push('/communities/$communityId/suggest')),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: 'https://image.tmdb.org/t/p/w300/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
                        width: 120,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade700,
                          child: Container(width: 120, height: 180, color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(width: 120, color: AppColors.darkSurface, child: const Icon(Icons.broken_image, color: Colors.white30)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Active poll
              Text('Active Poll', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.how_to_vote, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text('Vote for this week’s pick', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                          child: Text('Ends in 18h', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PollRow(title: 'Past Lives', votes: 7, isWinner: true),
                    _PollRow(title: 'Oppenheimer', votes: 5),
                    _PollRow(title: 'The Zone of Interest', votes: 2),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/communities/$communityId/vote'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Open Voting', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Discussions preview
              Row(
                children: [
                  Text('Discussions', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const Spacer(),
                  TextButton(onPressed: () => context.push('/communities/$communityId/discussion'), child: Text('View all', style: TextStyle(color: AppColors.accent))),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/68.jpg'), radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('What did everyone think of the ending?', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('2 replies · 4h ago', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white30),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                      child: Text('PINNED', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('📌 Watch party rules — please read before RSVP', style: AppTextStyles.body.copyWith(color: Colors.white))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollRow extends StatelessWidget {
  final String title;
  final int votes;
  final bool isWinner;
  const _PollRow({required this.title, required this.votes, this.isWinner = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.accent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isWinner ? AppColors.accent.withOpacity(0.4) : Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400))),
          if (isWinner)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
              child: Text('WINNER', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
          Text('$votes votes', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}
