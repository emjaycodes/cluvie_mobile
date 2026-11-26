import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/clubs/presentation/widgets/club_tile.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Clubs (tab 3): your clubs, and other clubs to join.
///
/// * "Your clubs" comes from `GET /communities/joined`, "Find a club" from
///   `GET /communities/all` minus yours. The search filters both by name
///   and description.
/// * Join is real (`POST /communities/:id/join`). There are no invite codes
///   on the backend, so there is no code field.
/// * While your clubs are loading or failed, other clubs show no Join
///   button: membership is unknown, not "not a member".
///
/// Gold budget: "Create a club" in the empty state, when shown. Otherwise
/// none.
class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});
  @override
  ConsumerState<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  final _search = TextEditingController();
  String _query = '';
  final _joining = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Community c) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return c.displayName.toLowerCase().contains(q) || (c.description ?? '').toLowerCase().contains(q);
  }

  Future<void> _refresh() async {
    final hadData = ref.read(joinedCommunitiesProvider).hasValue || ref.read(allCommunitiesProvider).hasValue;
    ref.invalidate(joinedCommunitiesProvider);
    ref.invalidate(allCommunitiesProvider);
    try {
      await Future.wait([
        ref.read(joinedCommunitiesProvider.future),
        ref.read(allCommunitiesProvider.future),
      ]);
    } catch (_) {
      if (hadData && mounted) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier clubs.", type: ClSnackbarType.error);
      }
    }
  }

  Future<void> _join(Community club) async {
    final id = club.id;
    if (id == null || _joining.contains(id)) return;
    setState(() => _joining.add(id));
    final refusal = await joinClub(ref, id);
    if (!mounted) return;
    setState(() => _joining.remove(id));
    switch (refusal) {
      case null:
        ClSnackbar.show(
          context,
          message: 'You joined ${club.displayName}.',
          type: ClSnackbarType.success,
          actionLabel: 'Open',
          onAction: () => context.push('/communities/$id'),
        );
      case ClubActionRefusal.notFound:
        ref.invalidate(allCommunitiesProvider);
        ClSnackbar.show(context, message: '${club.displayName} no longer exists.', type: ClSnackbarType.error);
      case ClubActionRefusal.ownerCannotLeave:
      case ClubActionRefusal.failed:
        ClSnackbar.show(
          context,
          message: "Couldn't join ${club.displayName}. Check your connection and try again.",
          type: ClSnackbarType.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final joined = ref.watch(joinedCommunitiesProvider);
    final all = ref.watch(allCommunitiesProvider);
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final unread = ref.watch(unreadCountProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    final mine = (joined.valueOrNull ?? const <Community>[]).where(_matches).toList();
    final mineIds = {for (final c in joined.valueOrNull ?? const <Community>[]) c.id};
    final membershipKnown = joined.hasValue;
    final others = (all.valueOrNull ?? const <Community>[])
        .where((c) => c.id != null && !mineIds.contains(c.id) && _matches(c))
        .toList();

    String? roleOf(Community c) => c.isOwner(me) ? 'Owner' : (c.isAdmin(me) ? 'Admin' : null);

    final joinWidth = ClButton.intrinsicWidth(context, 'Join');

    Widget section(String title, {String? subtitle}) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.section, AppSpacing.gutter, AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(title, style: AppTextStyles.h3)),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            ],
          ]),
        );

    Widget tiles(List<Widget> children) => Padding(
          padding: AppSpacing.screen,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              ClEntrance(index: i, child: c),
            ],
          ]),
        );

    Widget skeletons(int n) => Padding(
          padding: AppSpacing.screen,
          child: Semantics(
            label: 'Loading clubs',
            liveRegion: true,
            child: Column(children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const ClSkeletonRow(thumbWidth: 44, thumbHeight: 44),
              ],
            ]),
          ),
        );

    final searching = _query.isNotEmpty;
    final bothLoaded = joined.hasValue && all.hasValue;
    final noMatches = searching && bothLoaded && mine.isEmpty && others.isEmpty;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
        child: ClSearchField(
          controller: _search,
          hintText: 'Find a club',
          onChanged: (t) => setState(() => _query = t.trim()),
          onSubmitted: (t) => setState(() => _query = t.trim()),
          onCleared: () => setState(() => _query = ''),
        ),
      ),
      if (noMatches)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl, AppSpacing.gutter, 0),
          child: ClEmptyState(
            icon: AppIcons.search,
            title: "No clubs match '$_query'",
            message: 'Try another name, or start the club yourself.',
            actionLabel: 'Create a club',
            actionVariant: ClButtonVariant.secondary,
            onAction: () => context.push('/createCommunity'),
          ),
        )
      else ...[
        // ── Your clubs ──
        section('Your clubs'),
        ...joined.when(
          skipLoadingOnRefresh: joined.hasValue,
          skipError: joined.hasValue,
          loading: () => [skeletons(2)],
          error: (_, __) => [
            Padding(
              padding: AppSpacing.screen,
              child: ClErrorState(
                title: "Couldn't load your clubs",
                compact: true,
                onRetry: () => ref.invalidate(joinedCommunitiesProvider),
              ),
            ),
          ],
          data: (list) {
            if (list.isEmpty && !searching) {
              return [
                Padding(
                  padding: AppSpacing.screen,
                  child: ClCard(
                    child: ClEmptyState(
                      compact: true,
                      illustration: ClIllustration.clubs,
                      title: "You're not in a club yet",
                      message: 'Start one for your friends, or join one below.',
                      actionLabel: 'Create a club',
                      actionVariant: ClButtonVariant.primary,
                      onAction: () => context.push('/createCommunity'),
                    ),
                  ),
                ),
              ];
            }
            if (mine.isEmpty) {
              return [
                Padding(
                  padding: AppSpacing.screen,
                  child: Text('None of your clubs match.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                ),
              ];
            }
            return [tiles([for (final c in mine) ClubTile(club: c, role: roleOf(c))])];
          },
        ),

        // ── Find a club ──
        section('Find a club', subtitle: membershipKnown ? 'Join one to vote and suggest films' : null),
        ...all.when(
          skipLoadingOnRefresh: all.hasValue,
          skipError: all.hasValue,
          loading: () => [skeletons(3)],
          error: (_, __) => [
            Padding(
              padding: AppSpacing.screen,
              child: ClErrorState(
                title: "Couldn't load clubs",
                compact: true,
                onRetry: () => ref.invalidate(allCommunitiesProvider),
              ),
            ),
          ],
          data: (_) {
            if (others.isEmpty) {
              return [
                Padding(
                  padding: AppSpacing.screen,
                  child: Text(
                    searching ? 'No other clubs match.' : "You're in every club so far.",
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ];
            }
            return [
              tiles([
                for (final c in others)
                  ClubTile(
                    club: c,
                    actionWidth: membershipKnown ? joinWidth : 0,
                    action: membershipKnown
                        ? ClButton(
                            label: 'Join',
                            expand: false,
                            variant: ClButtonVariant.secondary,
                            isLoading: _joining.contains(c.id),
                            semanticLabel: 'Join ${c.displayName}',
                            onPressed: _joining.contains(c.id) ? null : () => _join(c),
                          )
                        : null,
                  ),
              ]),
            ];
          },
        ),
      ],
      SizedBox(height: AppSpacing.xxl + bottom),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.purple,
        backgroundColor: AppColors.surfaceRaised,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.bg,
              scrolledUnderElevation: 0,
              titleSpacing: AppSpacing.gutter,
              title: Semantics(header: true, child: Text('Clubs', style: AppTextStyles.h2)),
              actions: [
                ClIconButton(
                  icon: AppIcons.add,
                  tooltip: 'Create a club',
                  onPressed: () => context.push('/createCommunity'),
                ),
                ClIconButton(
                  icon: AppIcons.bell,
                  tooltip: 'Notifications',
                  badge: unread > 0,
                  badgeLabel: '$unread unread',
                  onPressed: () => context.push('/notifications'),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
            ),
            SliverList.list(children: children),
          ],
        ),
      ),
    );
  }
}
