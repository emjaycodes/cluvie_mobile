import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "3 members · 2 films"
String clubStats(Community club) {
  final m = club.members.length;
  final f = club.movieSuggestions.length;
  return [
    '$m member${m == 1 ? '' : 's'}',
    if (f > 0) '$f film${f == 1 ? '' : 's'}',
  ].join(' · ');
}

/// A club in a list: monogram, name, stats, description. Tapping opens the
/// club. [role] is a small badge ("Owner", "Admin"); [action] (e.g. a Join
/// button) sits on the right, or below when the text is large.
class ClubTile extends StatelessWidget {
  const ClubTile({super.key, required this.club, this.role, this.action, this.actionWidth = 0});

  final Community club;
  final String? role;
  final Widget? action;

  /// The width [action] needs on one line; it moves below the text when
  /// the row can't spare it.
  final double actionWidth;

  @override
  Widget build(BuildContext context) {
    final name = club.displayName;
    final description = club.description;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitWordsText(
          name,
          styles: const [AppTextStyles.title, AppTextStyles.label, AppTextStyles.bodySm],
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(clubStats(club), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            if (role != null) ClBadge(role!, tone: ClBadgeTone.purple),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return ClCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(builder: (context, box) {
        // Above 1.6× text the monogram steps aside so long names fit
        // without breaking words (the name is right there anyway).
        final roomy = MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.6;
        // Avatar + gaps take ~72; keep at least 160 for the text. At large
        // text the action always goes below, so the text gets the width.
        final inline = action == null || (roomy && box.maxWidth - 72 - actionWidth >= 160);
        final open = ClPressable(
          onTap: () => context.push('/communities/${club.id}'),
          semanticLabel: '$name. ${clubStats(club)}${role != null ? '. $role' : ''}',
          borderRadius: AppRadius.mdAll,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (roomy) ...[
              ClAvatar(name: name, radius: 22),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: ExcludeSemantics(child: info)),
          ]),
        );
        if (action == null) return open;
        if (inline) {
          return Row(children: [
            Expanded(child: open),
            const SizedBox(width: AppSpacing.md),
            action!,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          open,
          const SizedBox(height: AppSpacing.md),
          action!,
        ]);
      }),
    );
  }
}
