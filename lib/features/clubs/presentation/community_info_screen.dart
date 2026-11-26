import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/clubs/presentation/join_feedback.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// About a club (`/communities/:id/about`): its full description, the facts
/// the backend has (members, admins, films, founded) and who is in it.
/// The owner and admins can make a member an admin.
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
    if (_joining) return;
    setState(() => _joining = true);
    final (done, refusal) = await joinClub(ref, widget.communityId);
    if (!mounted) return;
    setState(() => _joining = false);
    showJoinResult(context, club.displayName, done, refusal);
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
            if (club.memberProfiles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              _Members(club: club, canPromote: membership == ClubMembership.member && club.isAdmin(_me(ref))),
            ],
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

class _Members extends ConsumerStatefulWidget {
  const _Members({required this.club, required this.canPromote});
  final Community club;
  final bool canPromote;

  @override
  ConsumerState<_Members> createState() => _MembersState();
}

class _MembersState extends ConsumerState<_Members> {
  final _promoting = <String>{};

  void _confirm(ClubMemberProfile p) {
    final name = p.username ?? 'this member';
    showClDialog(
      context: context,
      title: 'Make $name an admin?',
      message: "Admins can make other members admins too. There's no way to undo this in the app yet.",
      confirmText: 'Make admin',
      showConfirm: true,
      closeText: 'Cancel',
      onConfirm: () => _promote(p),
    );
  }

  Future<void> _promote(ClubMemberProfile p) async {
    final clubId = widget.club.id;
    if (clubId == null || _promoting.contains(p.id)) return;
    setState(() => _promoting.add(p.id));
    final refusal = await makeClubAdmin(ref, clubId, p.id);
    if (!mounted) return;
    setState(() => _promoting.remove(p.id));
    final name = p.username ?? 'They';
    switch (refusal) {
      case null:
        ClSnackbar.show(context, message: '$name is now an admin.', type: ClSnackbarType.success);
      case ClubActionRefusal.unauthorised:
        ClSnackbar.show(context, message: 'Only the owner and admins can do that.', type: ClSnackbarType.error);
      case ClubActionRefusal.notFound:
        ClSnackbar.show(context, message: 'This club no longer exists.', type: ClSnackbarType.error);
      case ClubActionRefusal.ownerCannotLeave:
      case ClubActionRefusal.failed:
        ClSnackbar.show(context, message: "Couldn't make $name an admin. Try again.", type: ClSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final people = widget.club.memberProfiles;
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.6;
    final makeAdminWidth = ClButton.intrinsicWidth(context, 'Make admin');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(header: true, child: Text('Members', style: AppTextStyles.h3)),
      const SizedBox(height: AppSpacing.md),
      ClCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        child: Column(children: [
          for (final (i, p) in people.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _MemberRow(
              profile: p,
              isMe: p.id == me,
              roomy: roomy,
              actionWidth: makeAdminWidth,
              action: widget.canPromote && p.role == ClubRole.member && p.id != me
                  ? ClButton(
                      label: 'Make admin',
                      expand: false,
                      variant: ClButtonVariant.ghost,
                      isLoading: _promoting.contains(p.id),
                      semanticLabel: 'Make ${p.username ?? 'this member'} an admin',
                      onPressed: _promoting.contains(p.id) ? null : () => _confirm(p),
                    )
                  : null,
            ),
          ],
        ]),
      ),
    ]);
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.profile, required this.isMe, required this.roomy, required this.actionWidth, this.action});
  final ClubMemberProfile profile;
  final bool isMe;
  final bool roomy;
  final double actionWidth;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final name = profile.username ?? 'Deleted account';
    final role = switch (profile.role) { ClubRole.owner => 'Owner', ClubRole.admin => 'Admin', ClubRole.member => null };
    final color = profile.username == null ? AppColors.textSecondary : AppColors.textPrimary;
    final label = Semantics(
      label: [name, if (isMe) 'you', if (role != null) role].join(', '),
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // Usernames are single handles: shrink, then ellipsize, never break.
        FitWordsText(
          name,
          styles: [
            AppTextStyles.label.copyWith(color: color),
            AppTextStyles.bodySm.copyWith(color: color),
            AppTextStyles.caption.copyWith(color: color),
          ],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (role != null || isMe) ...[
          const SizedBox(height: AppSpacing.xxs),
          Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xxs, children: [
            if (role != null) ClBadge(role, icon: profile.role == ClubRole.owner ? AppIcons.crown : null),
            if (isMe) const ClBadge('You', tone: ClBadgeTone.glass),
          ]),
        ],
      ]),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: LayoutBuilder(builder: (context, box) {
        final inline = action != null && roomy && box.maxWidth - actionWidth - 56 >= 140;
        final row = Row(children: [
          if (roomy) ...[
            ClAvatar(name: profile.username ?? '?', radius: 18),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: label),
          if (inline) ...[const SizedBox(width: AppSpacing.sm), action!],
        ]);
        if (action == null || inline) return row;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          row,
          const SizedBox(height: AppSpacing.sm),
          action!,
        ]);
      }),
    );
  }
}
