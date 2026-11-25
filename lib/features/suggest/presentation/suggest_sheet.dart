import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The focused suggest step: which club, an optional note, and submit.
///
/// Posts `{tmdbId, note}` to `/communities/<club>/suggest` for the club the
/// user picked. [communityId] preselects a club (deep link from a club page).
/// Resolves to the club the film was suggested to, or null if dismissed.
/// Reusable from anywhere a film is shown (e.g. Movie Detail).
///
/// The sheet can't be dismissed while a suggestion is sending. If it is gone
/// anyway when the request finishes, the outcome is reported from [context].
Future<Community?> showSuggestSheet(BuildContext context, TmdbMovie movie, {String? communityId}) {
  return showClSheet<Community>(
    context,
    title: 'Suggest a film',
    child: SuggestSheet(movie: movie, communityId: communityId, reportTo: context),
  );
}

class SuggestSheet extends ConsumerStatefulWidget {
  const SuggestSheet({super.key, required this.movie, this.communityId, this.reportTo});

  final TmdbMovie movie;
  final String? communityId;

  /// Where to report the result if the sheet has closed before it arrives.
  final BuildContext? reportTo;

  @override
  ConsumerState<SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends ConsumerState<SuggestSheet> {
  final _note = TextEditingController();
  String? _clubId;
  bool _submitting = false;
  bool _failed = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The selected club: the user's pick, else the deep-linked club, else the
  /// only club when there's just one.
  Community? _selected(List<Community> clubs) {
    final id = _clubId ?? widget.communityId;
    for (final c in clubs) {
      if (c.id == id) return c;
    }
    return clubs.length == 1 ? clubs.first : null;
  }

  Future<void> _submit(Community club) async {
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post('/communities/${club.id}/suggest', data: {'tmdbId': widget.movie.id, 'note': _note.text.trim()});
      if (mounted) {
        Navigator.of(context).pop(club);
      } else {
        _report('Suggested ${widget.movie.title} to ${club.name ?? 'your club'}.', ClSnackbarType.success);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _failed = true;
        });
      } else {
        _report("Couldn't suggest ${widget.movie.title}. Try again.", ClSnackbarType.error);
      }
    }
  }

  void _report(String message, ClSnackbarType type) {
    final ctx = widget.reportTo;
    if (ctx != null && ctx.mounted) ClSnackbar.show(ctx, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final clubs = ref.watch(joinedCommunitiesProvider);
    final List<Widget> body;
    if (clubs.hasValue && !(clubs.isLoading && clubs.hasError)) {
      final list = clubs.requireValue;
      final linked = widget.communityId;
      body =
          list.isEmpty
              ? [_noClubs(context)]
              : linked != null && !list.any((c) => c.id == linked)
              ? [_notMember(context, linked)]
              : _form(list);
    } else if (clubs.isLoading) {
      // Also while a retry is in flight, so "Try again" visibly does something.
      body = [
        Semantics(
          label: 'Loading your clubs',
          liveRegion: true,
          child: const ExcludeSemantics(
            child: Column(
              children: [
                ClSkeleton(height: 56, radius: AppRadius.lg),
                SizedBox(height: AppSpacing.sm),
                ClSkeleton(height: 56, radius: AppRadius.lg),
              ],
            ),
          ),
        ),
      ];
    } else {
      body = [
        ClErrorState(
          compact: true,
          title: "Couldn't load your clubs",
          onRetry: () => ref.invalidate(joinedCommunitiesProvider),
        ),
      ];
    }
    return PopScope(
      // No closing mid-send: the result would be lost.
      canPop: !_submitting,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilmRow(movie: widget.movie),
            const SizedBox(height: AppSpacing.xl),
            Semantics(header: true, child: Text('Suggest to', style: AppTextStyles.h3)),
            const SizedBox(height: AppSpacing.md),
            ...body,
          ],
        ),
      ),
    );
  }

  /// Deep link to a club the user isn't in: say so, rather than quietly
  /// offering their other clubs.
  Widget _notMember(BuildContext context, String id) {
    final name =
        (ref.watch(allCommunitiesProvider).valueOrNull ?? const <Community>[])
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull;
    return ClEmptyState(
      compact: true,
      illustration: ClIllustration.clubs,
      message: "You're not in ${name ?? 'this club'} yet. Join it to suggest films to its poll.",
      actionLabel: 'Open club',
      actionVariant: ClButtonVariant.secondary,
      onAction: () {
        Navigator.of(context).pop();
        GoRouter.of(context).go('/communities/$id');
      },
    );
  }

  Widget _noClubs(BuildContext context) {
    return ClEmptyState(
      compact: true,
      illustration: ClIllustration.clubs,
      message: 'Join a club first. Suggestions go to a club’s weekly poll.',
      actionLabel: 'Find a club',
      actionVariant: ClButtonVariant.secondary,
      onAction: () {
        Navigator.of(context).pop();
        GoRouter.of(context).go('/communities');
      },
    );
  }

  List<Widget> _form(List<Community> clubs) {
    final club = _selected(clubs);
    final clubName = club?.name ?? 'club';
    return [
      Semantics(
        // Announce the group so the rows read as one choice.
        container: true,
        label: 'Choose a club',
        child: Column(
          children: [
            for (final c in clubs) ...[
              _ClubOption(
                club: c,
                selected: c.id == club?.id,
                onTap: _submitting ? null : () => setState(() => _clubId = c.id),
              ),
              if (c != clubs.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      ClTextField(
        label: 'Note (optional)',
        hintText: 'Why should the club watch it?',
        controller: _note,
        maxLines: 3,
        enabled: !_submitting,
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_failed) ...[
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(AppIcons.error, size: 20, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "Couldn't send the suggestion. Check your connection and try again.",
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      // The sheet's one gold action.
      // Short label so it never truncates (club names can be long; the
      // selected club is shown above). The spoken label says it all.
      ClButton(
        label: club == null ? 'Pick a club' : (_failed ? 'Try again' : 'Suggest'),
        // Starts with the visible text (WCAG 2.5.3), then says what it does.
        semanticLabel:
            club == null
                ? null
                : _failed
                ? 'Try again: suggest ${widget.movie.title} to $clubName'
                : 'Suggest ${widget.movie.title} to $clubName',
        variant: ClButtonVariant.primary,
        icon: AppIcons.send,
        isLoading: _submitting,
        onPressed: club == null || widget.movie.id == null ? null : () => _submit(club),
      ),
    ];
  }
}

class _FilmRow extends StatelessWidget {
  const _FilmRow({required this.movie});

  final TmdbMovie movie;

  @override
  Widget build(BuildContext context) {
    final year = movie.year;
    return Row(
      children: [
        ClPosterImage(url: movie.posterUrl('w185'), width: 56, height: 84, radius: AppRadius.sm, decorative: true),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(movie.title, style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (year != null) Text(year, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

/// One radio-style club row. Selected is purple (the gold budget keeps gold
/// for the submit button).
class _ClubOption extends StatelessWidget {
  const _ClubOption({required this.club, required this.selected, required this.onTap});

  final Community club;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = club.name ?? 'Club';
    final members = club.members.length;
    return ClPressable(
      onTap: onTap,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      borderRadius: AppRadius.lgAll,
      semanticLabel: '$name, $members member${members == 1 ? '' : 's'}',
      excludeChildSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleContainer : AppColors.surfaceRaised,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: selected ? AppColors.purpleText : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            // At very large text the (decorative) avatar steps aside so long
            // words in the club name keep the width.
            if (MediaQuery.textScalerOf(context).scale(1) <= 1.6) ...[
              ClAvatar(name: name, radius: 18),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The club the user commits to: always shown in full.
                  Text(name, style: AppTextStyles.title),
                  Text('$members member${members == 1 ? '' : 's'}', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Radio mark: filled check when selected, an empty ring otherwise.
            selected
                ? const Icon(AppIcons.success, size: 24, color: AppColors.purpleText)
                : Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textSecondary, width: 1.5),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
