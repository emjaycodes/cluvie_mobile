import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Watch Party Events List — CF-09
/// Route: /watch-parties (alias /watchParty for detail)
/// Shows upcoming + past with RSVP CTAs per ROADMAP M1/M2.
class WatchPartyListScreen extends StatefulWidget {
  const WatchPartyListScreen({super.key});
  @override
  State<WatchPartyListScreen> createState() => _WatchPartyListScreenState();
}

class _WatchPartyListScreenState extends State<WatchPartyListScreen> {
  String _rsvp = 'maybe';
  final List<Map<String, dynamic>> _upcoming = [
    {
      'title': 'Past Lives',
      'date': 'Sat, Sep 28 · 8:00 PM',
      'location': 'Cinema Sundays — Discord watch',
      'image': 'https://image.tmdb.org/t/p/w500/kAellTx1ukNtc42BP1kcnHPCG5e.jpg',
      'attendees': 9,
    },
    {
      'title': 'Oppenheimer',
      'date': 'Fri, Oct 4 · 7:30 PM',
      'location': 'A24 Lovers — Host: Carmen',
      'image': 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      'attendees': 14,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watch Parties', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
        child: _upcoming.isEmpty
            ? ListView(children: const [
                SizedBox(height: 80),
                ClEmptyState(message: 'No watch parties yet.\nSchedule one from the winning poll!', icon: Icons.live_tv_rounded),
              ])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text('RSVP helps hosts plan — update anytime until start.', style: AppTextStyles.caption.copyWith(color: AppColors.accent))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Upcoming', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  ..._upcoming.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: CachedNetworkImage(
                                imageUrl: p['image'],
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(height: 160, color: Colors.white)),
                                errorWidget: (_, __, ___) => Container(height: 160, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white30)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['title'], style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(p['date'], style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(p['location'], style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.group, size: 16, color: Colors.white54),
                                      const SizedBox(width: 6),
                                      Text('${p['attendees']} attending', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                                      const Spacer(),
                                      TextButton(onPressed: () => context.push('/watchParty'), child: Text('Details', style: TextStyle(color: AppColors.accent))),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(value: 'yes', label: Text('Yes'), icon: Icon(Icons.check, size: 16)),
                                      ButtonSegment(value: 'maybe', label: Text('Maybe'), icon: Icon(Icons.help_outline, size: 16)),
                                      ButtonSegment(value: 'no', label: Text('No'), icon: Icon(Icons.close, size: 16)),
                                    ],
                                    selected: {_rsvp},
                                    onSelectionChanged: (s) => setState(() => _rsvp = s.first),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.accent : AppColors.darkSurface),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  Text('Past Parties', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w200/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', width: 60, height: 80, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('The Batman — Sep 14', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text('12 attended · Discussion archived', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white30),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClButton(label: 'View Live Party', onPressed: () => context.push('/watchParty')),
                ],
              ),
      ),
    );
  }
}
