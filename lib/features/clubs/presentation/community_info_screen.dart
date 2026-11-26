import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// About a club (`/communities/:id/about`): its full description and the
/// facts the backend has (members, admins, films, founded).
///
/// Gold budget: "Join club" for non-members. Otherwise none.
class CommunityInfoScreen extends ConsumerStatefulWidget {
  const CommunityInfoScreen({super.key, required this.communityId});
  final String communityId;

  @override
  ConsumerState<CommunityInfoScreen> createState() => _CommunityInfoScreenState();
}

class _CommunityInfoScreenState extends ConsumerState<CommunityInfoScreen> {
  bool _joining = false;

  Future<void> _join(Community club) async {
    setState(() => _joining = true);
    final refusal = await joinClub(ref, widget.communityId);
    if (!mounted) return;
    setState(() => _joining = false);
    ClSnackbar.show(
      context,
      message: refusal == null ? 'Welcome to ${club.displayName}.' : "Couldn't join. Check your connection and try again.",
      type: refusal == null ? ClSnackbarType.success : ClSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClubScaffold(
      communityId: widget.communityId,
      title: 'About',
      builder: (context, club) {
        final membership = membershipIn(ref, club);
        final since = club.createdAt;
        final facts = [
          (icon: AppIcons.clubs, value: '${club.members.length}', label: club.members.length == 1 ? 'Member' : 'Members'),
          (icon: AppIcons.crown, value: '${club.admins.length}', label: club.admins.length == 1 ? 'Admin' : 'Admins'),
          (icon: AppIcons.filmStrip, value: '${club.movieSuggestions.length}', label: club.movieSuggestions.length == 1 ? 'Film' : 'Films'),
          if (since != null) (icon: AppIcons.calendar, value: DateFormat.yMMM().format(since), label: 'Founded'),
        ];
        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
          children: [
            Semantics(
              header: true,
              child: FitWordsText(club.displayName, styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              club.description ?? 'This club has no description yet.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(builder: (context, box) {
              final columns = box.maxWidth >= 300 && MediaQuery.textScalerOf(context).scale(1) <= 1.5 ? 2 : 1;
              final w = (box.maxWidth - AppSpacing.md * (columns - 1)) / columns;
              return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
                for (final f in facts)
                  SizedBox(
                    width: w,
                    child: ClCard(
                      child: Semantics(
                        label: '${f.label}: ${f.value}',
                        excludeSemantics: true,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(f.icon, color: AppColors.purpleText, size: 20),
                          const SizedBox(height: AppSpacing.sm),
                          Text(f.value, style: AppTextStyles.h3),
                          Text(f.label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
              ]);
            }),
            const SizedBox(height: AppSpacing.xl),
            if (membership == ClubMembership.member)
              ClCard(
                child: Row(children: [
                  const Icon(AppIcons.success, color: AppColors.success, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      club.isOwner(_me(ref)) ? 'You started this club.' : "You're a member of this club.",
                      style: AppTextStyles.body,
                    ),
                  ),
                ]),
              )
            else if (membership == ClubMembership.notMember)
              ClButton(
                label: 'Join club',
                icon: AppIcons.add,
                variant: ClButtonVariant.primary,
                isLoading: _joining,
                onPressed: _joining ? null : () => _join(club),
              ),
          ],
        );
      },
    );
  }
}

String? _me(WidgetRef ref) => ref.watch(currentUserIdProvider).valueOrNull;
