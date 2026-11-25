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
Future<Community?> showSuggestSheet(BuildContext context, TmdbMovie movie, {String? communityId}) {
  return showClSheet<Community>(
    context,
    title: 'Suggest a film',
    child: SuggestSheet(movie: movie, communityId: communityId),
  );
}

class SuggestSheet extends ConsumerStatefulWidget {
  const SuggestSheet({super.key, required this.movie, this.communityId});

  final TmdbMovie movie;
  final String? communityId;

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
      if (mounted) Navigator.of(context).pop(club);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubs = ref.watch(joinedCommunitiesProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilmRow(movie: widget.movie),
          const SizedBox(height: AppSpacing.xl),
          Semantics(header: true, child: Text('Suggest to', style: AppTextStyles.h3)),
          const SizedBox(height: AppSpacing.md),
          ...clubs.when(
            skipLoadingOnReload: true,
            loading:
                () => [
                  Semantics(
                    label: 'Loading your clubs',
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
                ],
            error:
                (_, __) => [
                  ClErrorState(
                    compact: true,
                    title: "Couldn't load your clubs",
                    onRetry: () => ref.invalidate(joinedCommunitiesProvider),
                  ),
                ],
            data: (list) => list.isEmpty ? [_noClubs(context)] : _form(list),
          ),
        ],
      ),
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
        label: 'Clubs',
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
        semanticLabel: club == null ? null : 'Suggest ${widget.movie.title} to $clubName',
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
      selected: selected,
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
            ClAvatar(name: name, radius: 18),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('$members member${members == 1 ? '' : 's'}', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Radio mark: filled check when selected, an empty ring otherwise.
            selected
                ? const Icon(AppIcons.success, size: 24, color: AppColors.purpleText)
                : Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.all(1),
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
