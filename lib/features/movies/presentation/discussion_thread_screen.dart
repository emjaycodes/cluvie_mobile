import 'dart:math' as math;

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/movies/data/discussions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A film's discussion (`/discussionThread`, film passed as `extra`; see
/// [extraFor]).
///
/// * Posts come from `GET /discussions/:movieId`: pinned first, then newest.
/// * Posting (`POST /discussions`) keeps the draft if it fails. Posts are
///   capped at [kMaxPostLength] characters; the counter appears near the cap.
/// * Like is the API's upvote, which can't be undone, so a liked post shows
///   as liked and the button is disabled.
/// * Without a catalog movie id (demo links) there is nothing to load, so the
///   screen says the discussion isn't open rather than showing demo posts.
///
/// Gold budget: none. Purple carries the send button.
class DiscussionThreadScreen extends ConsumerStatefulWidget {
  const DiscussionThreadScreen({super.key, this.movieId, this.title, this.posterUrl, this.tmdbId});

  /// Catalog (Mongo) id of the film. Null shows the "not open" state.
  final String? movieId;
  final String? title;
  final String? posterUrl;

  /// TMDB id, so the header can open Movie Detail.
  final int? tmdbId;

  /// The route `extra` for a film's discussion.
  static Map<String, Object> extraFor({required String movieId, required String title, String? posterUrl, int? tmdbId}) => {
        'movieId': movieId,
        'title': title,
        if (posterUrl != null) 'posterUrl': posterUrl,
        if (tmdbId != null) 'tmdbId': tmdbId,
      };

  /// Builds the screen from a route `extra` (see [extraFor]). Anything
  /// missing or of the wrong type is ignored.
  factory DiscussionThreadScreen.fromExtra(Object? extra) {
    final m = extra is Map ? extra : const {};
    String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
    final tmdb = m['tmdbId'];
    return DiscussionThreadScreen(
      movieId: str(m['movieId']),
      title: str(m['title']),
      posterUrl: str(m['posterUrl']),
      tmdbId: tmdb is int ? tmdb : null,
    );
  }

  @override
  ConsumerState<DiscussionThreadScreen> createState() => _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends ConsumerState<DiscussionThreadScreen> {
  final _draft = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _draft.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _heading => widget.title ?? 'Discussion';

  Future<void> _refresh(String movieId) async {
    try {
      await ref.read(discussionProvider(movieId).notifier).reload();
    } catch (_) {
      if (mounted) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier posts.", type: ClSnackbarType.error);
      }
    }
  }

  Future<void> _send(String movieId) async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final user = ref.read(authNotifierProvider).user;
      await ref.read(discussionProvider(movieId).notifier).post(
            text,
            authorName: user?.name,
            authorId: ref.read(currentUserIdProvider).valueOrNull,
          );
      _draft.clear();
      if (mounted) ClSnackbar.show(context, message: 'Posted', type: ClSnackbarType.success);
    } catch (_) {
      if (mounted) {
        ClSnackbar.show(
          context,
          message: "Couldn't post. Your text is still here.",
          type: ClSnackbarType.error,
          actionLabel: 'Retry',
          // The snackbar can outlive the screen; then there's nothing to retry.
          onAction: () {
            if (mounted) _send(movieId);
          },
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like(String movieId, DiscussionPost post) async {
    final me = ref.read(currentUserIdProvider).valueOrNull;
    if (me == null) {
      ClSnackbar.show(context, message: 'Sign in to like posts', type: ClSnackbarType.info);
      return;
    }
    try {
      await ref.read(discussionProvider(movieId).notifier).like(post.id, me);
    } catch (_) {
      if (mounted) ClSnackbar.show(context, message: "Couldn't like that post. Try again.", type: ClSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieId = widget.movieId;
    return Scaffold(
      appBar: ClAppBar(
        // The film's title is in the header below; the bar says what this is.
        title: movieId == null ? _heading : 'Discussion',
        frosted: true,
        fallbackRoute: widget.tmdbId != null ? '/movie/${widget.tmdbId}' : '/home',
      ),
      body: movieId == null ? _notOpen(context) : _thread(context, movieId),
    );
  }

  Widget _notOpen(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: ClEmptyState(
            illustration: ClIllustration.discussions,
            title: "This discussion isn't open yet",
            message: 'Discussions open once a club suggests the film. Find it in Discover and suggest it.',
            actionLabel: 'Go to Discover',
            onAction: () => context.go('/discover'),
          ),
        ),
      );

  Widget _thread(BuildContext context, String movieId) {
    final posts = ref.watch(discussionProvider(movieId));
    final me = ref.watch(currentUserIdProvider).valueOrNull;

    // Retrying after an error shows the skeleton. Pull-to-refresh goes
    // through reload(), which never enters loading, so posts don't flash.
    final Widget content = posts.when(
      skipLoadingOnRefresh: false,
      loading: () => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          _FilmHeader(title: widget.title, posterUrl: widget.posterUrl, tmdbId: widget.tmdbId, count: null),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 4; i++) ...[
            const ClSkeletonRow(thumbWidth: 40, thumbHeight: 40),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
      error: (_, __) => ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          _FilmHeader(title: widget.title, posterUrl: widget.posterUrl, tmdbId: widget.tmdbId, count: null),
          const SizedBox(height: AppSpacing.xl),
          ClErrorState(
            title: "Couldn't load the discussion",
            onRetry: () => ref.invalidate(discussionProvider(movieId)),
          ),
        ],
      ),
      data: (list) => RefreshIndicator(
        onRefresh: () => _refresh(movieId),
        color: AppColors.purple,
        backgroundColor: AppColors.surfaceRaised,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
          itemCount: list.isEmpty ? 2 : list.length + 1,
          separatorBuilder: (_, i) => SizedBox(height: i == 0 ? AppSpacing.lg : AppSpacing.md),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _FilmHeader(title: widget.title, posterUrl: widget.posterUrl, tmdbId: widget.tmdbId, count: list.length);
            }
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl),
                child: ClEmptyState(
                  illustration: ClIllustration.discussions,
                  title: 'Be the first to comment',
                  message: 'Share what you thought. Keep spoilers for people who have seen it.',
                ),
              );
            }
            final post = list[i - 1];
            return ClEntrance(
              index: i - 1,
              child: _PostCard(
                post: post,
                likedByMe: me != null && post.likedBy.contains(me),
                onLike: () => _like(movieId, post),
              ),
            );
          },
        ),
      ),
    );

    // The body's height is what the app bar and keyboard leave (the
    // Scaffold strips the keyboard inset from MediaQuery here).
    return LayoutBuilder(builder: (context, box) => Column(children: [
      Expanded(child: content),
      _Composer(
        bodyHeight: box.maxHeight,
        controller: _draft,
        focusNode: _focus,
        sending: _sending,
        enabled: posts.hasValue,
        onSend: () => _send(movieId),
      ),
    ]));
  }
}

class _FilmHeader extends StatelessWidget {
  const _FilmHeader({required this.title, required this.posterUrl, required this.tmdbId, required this.count});
  final String? title;
  final String? posterUrl;
  final int? tmdbId;
  final int? count;

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    final subtitle = count == null ? 'Discussion' : '$count ${count == 1 ? 'post' : 'posts'}';
    // Above 1.6× text the decorative poster steps aside so long words fit.
    final showPoster = MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.6;
    final row = Row(children: [
      if (showPoster) ...[
        ClPosterImage(url: posterUrl, width: 48, height: 72, radius: AppRadius.sm, decorative: true),
        const SizedBox(width: AppSpacing.md),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitWordsText(title!, styles: const [AppTextStyles.title, AppTextStyles.label, AppTextStyles.bodySm]),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
          if (tmdbId != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Film details', style: AppTextStyles.label.copyWith(color: AppColors.purpleText)),
          ],
        ]),
      ),
    ]);
    if (tmdbId == null) return row;
    return ClPressable(
      onTap: () => context.push('/movie/$tmdbId'),
      semanticLabel: '$title, $subtitle. Open film details',
      excludeChildSemantics: true,
      borderRadius: AppRadius.mdAll,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: row),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.likedByMe, required this.onLike});
  final DiscussionPost post;
  final bool likedByMe;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final name = post.authorName ?? 'Cluvie member';
    final likes = post.likes;
    final likeLabel = likedByMe
        ? 'You liked this${likes > 1 ? ', $likes likes' : ''}'
        : 'Like${likes > 0 ? ', $likes ${likes == 1 ? 'like' : 'likes'}' : ''}';

    return ClCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.card, AppSpacing.card, AppSpacing.sm, AppSpacing.xs),
      borderColor: post.pinned ? AppColors.purple : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Above 1.6× text the avatar steps aside so long names fit.
            if (MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.6) ...[
              ClAvatar(name: name, radius: 18),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Semantics(
                label: '$name, ${timeAgoSpoken(post.createdAt)}${post.pinned ? ', pinned' : ''}',
                excludeSemantics: true,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(name, style: AppTextStyles.label),
                    Text(timeAgo(post.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    if (post.pinned) const ClBadge('PINNED', tone: ClBadgeTone.purple, icon: AppIcons.pin),
                  ],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Text(post.text, style: AppTextStyles.body),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ClPressable(
            onTap: likedByMe ? null : onLike,
            semanticLabel: likeLabel,
            selected: likedByMe,
            excludeChildSemantics: true,
            borderRadius: AppRadius.pillAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouch, minWidth: AppSpacing.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    likedByMe ? AppIcons.heartFill : AppIcons.heart,
                    size: 20,
                    color: likedByMe ? AppColors.purpleText : AppColors.textSecondary,
                  ),
                  if (likes > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text('$likes', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.bodyHeight,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  /// Height of the screen body the composer shares with the posts.
  final double bodyHeight;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    final canSend = enabled && !sending && controller.text.trim().isNotEmpty;
    final nearLimit = length >= kMaxPostLength - 200;

    // Cap the field's height, not its line count: at large text five lines
    // are taller than the space above a keyboard on a small phone, which
    // pushed Post under the keyboard and squeezed the posts to nothing.
    // Up to five lines, but never more than 35% of the body (what the app
    // bar and keyboard leave); past that the field scrolls inside.
    const style = AppTextStyles.body;
    final line = MediaQuery.textScalerOf(context).scale(style.fontSize!) * (style.height ?? 1.2);
    final fieldMax = math.max(AppSpacing.minTouch, math.min(5 * line + 2 * AppSpacing.md, bodyHeight * 0.35));

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: fieldMax),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled && !sending,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(kMaxPostLength)],
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Add to the discussion',
                      border: const OutlineInputBorder(borderRadius: AppRadius.xlAll, borderSide: BorderSide(color: AppColors.borderInput)),
                      enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.xlAll, borderSide: BorderSide(color: AppColors.borderInput)),
                      focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.xlAll, borderSide: BorderSide(color: AppColors.focusRing, width: 2)),
                      disabledBorder: const OutlineInputBorder(borderRadius: AppRadius.xlAll, borderSide: BorderSide(color: AppColors.border)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: AppSpacing.minTouch,
                height: AppSpacing.minTouch,
                child: IconButton(
                  tooltip: 'Post',
                  onPressed: canSend ? onSend : null,
                  style: IconButton.styleFrom(
                    // purple has no on-colour; purpleBadge carries white (tokens.md).
                    backgroundColor: AppColors.purpleBadge,
                    disabledBackgroundColor: AppColors.surfaceRaised,
                    shape: const CircleBorder(),
                  ),
                  icon: sending
                      ? const ClLoading(size: 20, color: AppColors.textPrimary)
                      : Icon(AppIcons.send, size: 20, color: canSend ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
            ]),
            if (nearLimit)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.minTouch + AppSpacing.sm),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '$length / $kMaxPostLength',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(
                      color: length >= kMaxPostLength ? AppColors.warning : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
