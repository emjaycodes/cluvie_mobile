import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/authentication/data/sign_out.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/user_profile/data/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Profile (tab 5, `/profile`): who you are, your activity, your watchlist,
/// and log out.
///
/// * Identity, XP and counts come from `GET /users/me`; the watchlist from
///   `GET /watchlist`. Removing a film is immediate, with Undo.
/// * Edit opens `/profile/edit` for username, bio and avatar.
/// * `/users/:id` shows someone else's public profile, with Follow.
///
/// Gold budget: none on either profile screen. The edit screen owns its Save.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, this.userId});

  /// Someone else's profile; null for your own.
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final id = userId;
    if (id != null && id != me) return _OtherProfile(id: id);
    return const _MyProfile();
  }
}

class _OtherProfile extends ConsumerStatefulWidget {
  const _OtherProfile({required this.id});
  final String id;

  @override
  ConsumerState<_OtherProfile> createState() => _OtherProfileState();
}

class _OtherProfileState extends ConsumerState<_OtherProfile> {
  bool _busy = false;

  Future<void> _toggle(PublicProfile profile) async {
    if (_busy) return;
    final following = ref.read(followOverrideProvider(widget.id)) ?? profile.isFollowing;
    setState(() => _busy = true);
    final outcome = await setFollowing(ref, widget.id, following: !following);
    if (!mounted) return;
    setState(() => _busy = false);
    final message = switch (outcome) {
      FollowOutcome.done || FollowOutcome.cannotFollowSelf => null,
      FollowOutcome.notFound => "This profile isn't available.",
      FollowOutcome.failed => following ? "Couldn't unfollow. Try again." : "Couldn't follow. Try again.",
    };
    if (message != null) ClSnackbar.show(context, message: message, type: ClSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider(widget.id));
    final bottom = MediaQuery.paddingOf(context).bottom;
    return profile.when(
      skipLoadingOnRefresh: profile.hasValue,
      skipError: profile.hasValue,
      loading: () => Scaffold(
        appBar: const ClAppBar(title: 'Profile', fallbackRoute: '/home'),
        body: Semantics(
          label: 'Loading this profile',
          liveRegion: true,
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: const [
              Row(children: [
                ClSkeleton(width: 72, height: 72, circle: true),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClSkeleton(height: 22, width: 180),
                    SizedBox(height: AppSpacing.sm),
                    ClSkeleton(height: 14, width: 120),
                  ]),
                ),
              ]),
              SizedBox(height: AppSpacing.xl),
              ClSkeleton(height: 64),
              SizedBox(height: AppSpacing.md),
              ClSkeleton(height: 88),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: const ClAppBar(title: 'Profile', fallbackRoute: '/home'),
        body: error is ProfileNotFound
            ? ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.xxl + bottom),
                children: [
                  ClEmptyState(
                    icon: AppIcons.profile,
                    title: "This profile isn't available.",
                    message: 'The link may be broken, or the account may have been deleted.',
                    actionLabel: 'Go home',
                    actionVariant: ClButtonVariant.secondary,
                    onAction: () => context.go('/home'),
                  ),
                ],
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.xxl + bottom),
                children: [
                  ClErrorState(
                    title: "Couldn't load this profile",
                    onRetry: () => ref.invalidate(userProfileProvider(widget.id)),
                  ),
                ],
              ),
      ),
      data: (p) {
        // The backend is the authority: someone opening their own link sees
        // their own profile (with Edit) rather than a Follow button.
        if (p.isMe) return const _MyProfile();
        return _buildProfile(context, p, bottom);
      },
    );
  }

  Widget _buildProfile(BuildContext context, PublicProfile p, double bottom) {
    final override = ref.watch(followOverrideProvider(widget.id));
    final following = override ?? p.isFollowing;
    final delta = override == null || override == p.isFollowing ? 0 : (override ? 1 : -1);
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final joined = p.joinedAt;

    final identity = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        header: true,
        child: FitWordsText(breakableTokens(p.username), styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
      ),
      if (joined != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Joined ${DateFormat.yMMMM().format(joined.toLocal())}',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ]);

    return Scaffold(
      appBar: const ClAppBar(title: 'Profile', fallbackRoute: '/home'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
        children: [
          if (roomy)
            Row(children: [
              ClAvatar(imageUrl: p.avatarUrl, name: p.username, radius: 36, ring: true),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: identity),
            ])
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: ClAvatar(imageUrl: p.avatarUrl, name: p.username, radius: 36, ring: true),
            ),
            const SizedBox(height: AppSpacing.md),
            identity,
          ],
          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(breakableTokens(p.bio), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: following ? 'Following' : 'Follow',
              icon: following ? AppIcons.check : AppIcons.add,
              variant: ClButtonVariant.secondary,
              expand: false,
              isLoading: _busy,
              semanticLabel: following ? 'Unfollow ${p.username}' : 'Follow ${p.username}',
              onPressed: () => _toggle(p),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Stats(stats: [
            (value: p.followers + delta, label: p.followers + delta == 1 ? 'Follower' : 'Followers'),
            (value: p.following, label: 'Following'),
            (value: p.suggestions, label: p.suggestions == 1 ? 'Film suggested' : 'Films suggested'),
            (value: p.clubs, label: p.clubs == 1 ? 'Club' : 'Clubs'),
          ]),
        ],
      ),
    );
  }
}

class _MyProfile extends ConsumerWidget {
  const _MyProfile();

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final had = ref.read(myProfileProvider).hasValue;
    ref.invalidate(myProfileProvider);
    ref.invalidate(watchlistProvider);
    try {
      await Future.wait([ref.read(myProfileProvider.future), ref.read(watchlistProvider.future)]);
    } catch (_) {
      if (had && context.mounted) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier details.", type: ClSnackbarType.error);
      }
    }
  }

  void _confirmLogOut(BuildContext context, WidgetRef ref) => showClDialog(
        context: context,
        title: 'Log out of Cluvie?',
        message: "You'll need your email and password to log back in.",
        confirmText: 'Log out',
        closeText: 'Cancel',
        showConfirm: true,
        destructive: true,
        // Clears the token, auth state and user-scoped caches (review round 3, B3).
        onConfirm: () => signOut(context, ref),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final unread = ref.watch(unreadCountProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    final header = profile.when(
      skipLoadingOnRefresh: profile.hasValue,
      skipError: profile.hasValue,
      loading: () => Semantics(
        label: 'Loading your profile',
        liveRegion: true,
        child: const Column(children: [
          ClSkeletonRow(thumbWidth: 72, thumbHeight: 72),
          SizedBox(height: AppSpacing.lg),
          ClSkeleton(height: 88),
        ]),
      ),
      error: (_, __) => ClErrorState(
        title: "Couldn't load your profile",
        compact: true,
        onRetry: () => ref.invalidate(myProfileProvider),
      ),
      data: (p) => _Header(profile: p),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        color: AppColors.purple,
        backgroundColor: AppColors.surfaceRaised,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.bg,
              scrolledUnderElevation: 0,
              titleSpacing: AppSpacing.gutter,
              title: Semantics(header: true, child: Text('Profile', style: AppTextStyles.h2)),
              actions: [
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
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl + bottom),
              sliver: SliverList.list(children: [
                header,
                const SizedBox(height: AppSpacing.section),
                const _Watchlist(),
                const SizedBox(height: AppSpacing.section),
                ClButton(
                  label: 'Log out',
                  icon: AppIcons.signOut,
                  variant: ClButtonVariant.danger,
                  onPressed: () => _confirmLogOut(context, ref),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final identity = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        header: true,
        child: FitWordsText(breakableTokens(p.username), styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
      ),
      if (p.email != null) ...[
        const SizedBox(height: AppSpacing.xxs),
        Text(breakableTokens(p.email!), style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
      ],
      if (p.bio.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(breakableTokens(p.bio), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ],
      if (p.isAdmin) ...[const SizedBox(height: AppSpacing.xs), const ClBadge('Admin')],
    ]);
    final stats = [
      (value: p.xp, label: 'XP'),
      (value: p.suggested, label: p.suggested == 1 ? 'Film suggested' : 'Films suggested'),
      (value: p.voted, label: p.voted == 1 ? 'Vote' : 'Votes'),
      (value: p.comments, label: p.comments == 1 ? 'Comment' : 'Comments'),
      (value: p.followers, label: p.followers == 1 ? 'Follower' : 'Followers'),
      (value: p.following, label: 'Following'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (roomy)
        Row(children: [
          ClAvatar(imageUrl: p.avatarUrl, name: p.username, radius: 36, ring: true),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: identity),
        ])
      else ...[
        Align(
          alignment: Alignment.centerLeft,
          child: ClAvatar(imageUrl: p.avatarUrl, name: p.username, radius: 36, ring: true),
        ),
        const SizedBox(height: AppSpacing.md),
        identity,
      ],
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: Alignment.centerLeft,
        child: ClButton(
          label: 'Edit profile',
          icon: AppIcons.edit,
          variant: ClButtonVariant.secondary,
          expand: false,
          onPressed: () => context.push('/profile/edit'),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      _Stats(stats: stats),
    ]);
  }
}

/// The responsive count cards shared by your profile and someone else's.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats});
  final List<({int value, String label})> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // The most columns in which every label still fits whole.
      final scaler = MediaQuery.textScalerOf(context);
      final labelStyle = AppTextStyles.caption;
      double widthFor(int n) => (box.maxWidth - AppSpacing.md * (n - 1)) / n;
      bool fits(int n) {
        // Card padding, plus a little for its border.
        final inner = widthFor(n) - 2 * AppSpacing.md - 4;
        return stats.expand((s) => s.label.split(' ')).every((w) {
          final tp = TextPainter(text: TextSpan(text: w, style: labelStyle), textScaler: scaler, textDirection: TextDirection.ltr)..layout();
          final ok = tp.width <= inner;
          tp.dispose();
          return ok;
        });
      }

      final columns = fits(3) ? 3 : (fits(2) ? 2 : 1);
      final w = widthFor(columns);
      return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
        for (final s in stats)
          SizedBox(
            width: w,
            child: ClCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Semantics(
                label: '${s.label}: ${s.value}',
                excludeSemantics: true,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.value}', style: AppTextStyles.h3),
                  Text(s.label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }
}

class _Watchlist extends ConsumerWidget {
  const _Watchlist();

  Future<void> _remove(BuildContext context, WidgetRef ref, SavedFilm item, int index) async {
    final notifier = ref.read(watchlistProvider.notifier);
    try {
      await notifier.remove(item);
    } catch (_) {
      if (context.mounted) {
        ClSnackbar.show(context, message: "Couldn't remove ${item.film.title}. Try again.", type: ClSnackbarType.error);
      }
      return;
    }
    if (!context.mounted) return;
    ClSnackbar.show(
      context,
      message: 'Removed ${item.film.title}.',
      type: ClSnackbarType.success,
      duration: const Duration(seconds: 5),
      actionLabel: 'Undo',
      onAction: () => notifier.restore(item, index).catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(watchlistProvider);
    final count = list.valueOrNull?.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        header: true,
        child: Text(count == null || count == 0 ? 'Watchlist' : 'Watchlist ($count)', style: AppTextStyles.h3),
      ),
      const SizedBox(height: AppSpacing.md),
      list.when(
        skipLoadingOnRefresh: list.hasValue,
        skipError: list.hasValue,
        loading: () => const Column(children: [
          ClSkeletonRow(thumbWidth: 48, thumbHeight: 72),
          SizedBox(height: AppSpacing.md),
          ClSkeletonRow(thumbWidth: 48, thumbHeight: 72),
        ]),
        error: (_, __) => ClErrorState(
          title: "Couldn't load your watchlist",
          compact: true,
          onRetry: () => ref.invalidate(watchlistProvider),
        ),
        data: (films) {
          if (films.isEmpty) {
            return ClCard(
              child: ClEmptyState(
                compact: true,
                icon: AppIcons.bookmark,
                title: 'Nothing saved yet',
                message: 'Films you save to watch later show up here.',
                actionLabel: 'Discover films',
                actionVariant: ClButtonVariant.secondary,
                onAction: () => context.go('/discover'),
              ),
            );
          }
          return ClCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final (i, f) in films.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                _SavedRow(item: f, onRemove: () => _remove(context, ref, f, i)),
              ],
            ]),
          );
        },
      ),
    ]);
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.item, required this.onRemove});
  final SavedFilm item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final f = item.film;
    final tmdb = f.id;
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.6;
    final info = Row(children: [
      if (roomy) ...[
        ClPosterImage(url: f.posterUrl('w185'), width: 48, height: 72, radius: AppRadius.sm, decorative: true),
        const SizedBox(width: AppSpacing.md),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitWordsText(f.title, styles: const [AppTextStyles.label, AppTextStyles.bodySm], maxLines: 3),
          if (f.year != null) Text(f.year!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ]),
      ),
    ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      child: Row(children: [
        Expanded(
          child: tmdb == null
              ? info
              : ClPressable(
                  semanticLabel: [f.title, if (f.year != null) f.year!].join(', '),
                  onTap: () => context.push('/movie/$tmdb'),
                  child: info,
                ),
        ),
        ClIconButton(icon: AppIcons.close, tooltip: 'Remove ${f.title} from watchlist', onPressed: onRemove),
      ]),
    );
  }
}
