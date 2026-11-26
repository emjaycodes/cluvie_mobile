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
import 'package:go_router/go_router.dart';

/// Your membership of a club (`/communities/:id/settings`): your role, and
/// leaving.
///
/// The backend can't rename, re-cover, moderate or delete a club, so none of
/// those rows are offered. Owners can't leave (the backend refuses), so the
/// screen says that up front instead of failing after the tap.
///
/// Gold budget: none. Leaving is a danger action.
class ClubSettingsScreen extends ConsumerStatefulWidget {
  const ClubSettingsScreen({super.key, required this.communityId});
  final String communityId;

  @override
  ConsumerState<ClubSettingsScreen> createState() => _ClubSettingsScreenState();
}

class _ClubSettingsScreenState extends ConsumerState<ClubSettingsScreen> {
  bool _leaving = false;

  void _confirmLeave(Community club) {
    showClDialog(
      context: context,
      title: 'Leave ${club.displayName}?',
      message: "You'll stop seeing its votes and can't suggest films to it. You can join again later.",
      confirmText: 'Leave club',
      closeText: 'Stay',
      showConfirm: true,
      destructive: true,
      onConfirm: () => _leave(club),
    );
  }

  Future<void> _leave(Community club) async {
    setState(() => _leaving = true);
    final refusal = await leaveClub(ref, widget.communityId);
    if (!mounted) return;
    setState(() => _leaving = false);
    switch (refusal) {
      case null:
        ClSnackbar.show(context, message: 'You left ${club.displayName}.', type: ClSnackbarType.success);
        context.go('/communities');
      case ClubActionRefusal.ownerCannotLeave:
        ClSnackbar.show(context, message: "Owners can't leave their own club.", type: ClSnackbarType.error);
      case ClubActionRefusal.notFound:
        ClSnackbar.show(context, message: 'This club no longer exists.', type: ClSnackbarType.error);
        context.go('/communities');
      case ClubActionRefusal.failed:
        ClSnackbar.show(context, message: "Couldn't leave. Check your connection and try again.", type: ClSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClubScaffold(
      communityId: widget.communityId,
      title: 'Membership',
      builder: (context, club) {
        final me = ref.watch(currentUserIdProvider).valueOrNull;
        final membership = membershipIn(ref, club);
        final owner = club.isOwner(me);
        final role = owner ? 'Owner' : (club.isAdmin(me) ? 'Admin' : 'Member');

        final children = <Widget>[
          Semantics(
            header: true,
            child: FitWordsText(club.displayName, styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
          ),
          const SizedBox(height: AppSpacing.xl),
        ];

        if (membership == ClubMembership.notMember) {
          children.add(ClEmptyState(
            compact: true,
            icon: AppIcons.clubs,
            title: "You're not in this club",
            message: 'Open the club to join it.',
            actionLabel: 'Open club',
            actionVariant: ClButtonVariant.secondary,
            onAction: () => context.go('/communities/${widget.communityId}'),
          ));
        } else {
          children.addAll([
            ClCard(
              child: Row(children: [
                Icon(owner ? AppIcons.crown : AppIcons.user, color: AppColors.purpleText, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your role', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    Text(role, style: AppTextStyles.title),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (owner) ...[
              ClButton(label: 'Leave club', icon: AppIcons.signOut, variant: ClButtonVariant.danger, onPressed: null),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "You started this club, so you can't leave it.",
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ] else if (membership == ClubMembership.member)
              ClButton(
                label: 'Leave club',
                icon: AppIcons.signOut,
                variant: ClButtonVariant.danger,
                isLoading: _leaving,
                onPressed: _leaving ? null : () => _confirmLeave(club),
              ),
          ]);
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
          children: children,
        );
      },
    );
  }
}
