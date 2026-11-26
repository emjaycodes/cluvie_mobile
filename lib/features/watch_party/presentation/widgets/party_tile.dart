import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// "Sat 28 Sep · 20:00", or "Today · 20:00" / "Tomorrow · 20:00".
String partyWhen(DateTime when, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(when.year, when.month, when.day);
  final time = DateFormat.Hm().format(when);
  final diff = day.difference(today).inDays;
  final date = switch (diff) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ => day.year == today.year ? DateFormat('EEE d MMM').format(when) : DateFormat('d MMM yyyy').format(when),
  };
  return '$date · $time';
}

/// The label for a party's state, or null for an ordinary upcoming one.
/// A scheduled party long past its start reads as ended
/// ([WatchParty.isOver]).
String? partyStateLabel(WatchParty p, String? me) => switch (p.status) {
      PartyStatus.live => 'Live',
      PartyStatus.cancelled => 'Cancelled',
      PartyStatus.ended => 'Ended',
      PartyStatus.scheduled when p.isOver() => 'Ended',
      PartyStatus.scheduled => p.isHost(me) ? 'Hosting' : (p.isGoing(me) ? 'Going' : null),
    };

/// The badge for [partyStateLabel].
Widget? partyBadge(WatchParty p, String? me) {
  final label = partyStateLabel(p, me);
  if (label == null) return null;
  return ClBadge(label, tone: switch (label) {
    'Live' => ClBadgeTone.purpleSolid,
    'Cancelled' => ClBadgeTone.error,
    'Ended' => ClBadgeTone.glass,
    'Going' => ClBadgeTone.success,
    _ => ClBadgeTone.purple,
  });
}

/// A party in a list: poster, title, film, club and time. Opens the party.
class PartyTile extends StatelessWidget {
  const PartyTile({super.key, required this.party, required this.me});
  final WatchParty party;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final p = party;
    final badge = partyBadge(p, me);
    final going = p.participantIds.length;
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.6;
    final details = [
      if (p.film != null && p.film!.title != p.title) p.film!.title,
      if (p.clubName != null) p.clubName!,
    ].join(' · ');
    return ClCard(
      padding: EdgeInsets.zero,
      child: ClPressable(
        semanticLabel: [
          if (partyStateLabel(p, me) case final state?) state,
          p.title,
          if (details.isNotEmpty) details,
          partyWhen(p.scheduledAt),
          '$going going',
        ].join(', '),
        onTap: () => context.push('/watch-parties/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (roomy) ...[
              ClPosterImage(url: p.film?.posterUrl('w185'), width: 56, height: 84, radius: AppRadius.sm),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: ExcludeSemantics(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (badge != null) ...[badge, const SizedBox(height: AppSpacing.xs)],
                  FitWordsText(p.title, styles: const [AppTextStyles.title, AppTextStyles.label, AppTextStyles.bodySm], maxLines: 3),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(details, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.xxs, children: [
                    _Meta(icon: AppIcons.calendar, text: partyWhen(p.scheduledAt)),
                    _Meta(icon: AppIcons.clubs, text: '$going going'),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
      ]);
}
