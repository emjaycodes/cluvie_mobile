import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_scaffold.dart';
import 'package:cluvie_mobile/features/discover/presentation/movie_poster_tile.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart';
import 'package:cluvie_mobile/features/movies/presentation/club_discussions_screen.dart' show ClubFilm, clubFilmsProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The server's limits (`models/Poll.js`).
const kVoteQuestionMax = 200;
const kVoteMinFilms = 2;
const kVoteMaxFilms = 10;

/// How long a vote stays open. The server's default is 48 hours.
const kVoteDurations = <(String, Duration)>[
  ('1 day', Duration(days: 1)),
  ('2 days', Duration(days: 2)),
  ('3 days', Duration(days: 3)),
  ('1 week', Duration(days: 7)),
];

enum StartVoteRefusal { notMember, filmGone, clubGone, failed }

/// `POST /polls/create` with the films' catalog ids. Refusals carry no
/// `code`, so they're told apart by status and text.
Future<StartVoteRefusal?> startVote(
  WidgetRef ref, {
  required String communityId,
  required String question,
  required List<String> movieIds,
  required Duration openFor,
  bool allowMultiple = false,
}) async {
  try {
    await ref.read(apiClientProvider).post('/polls/create', data: {
      'communityId': communityId,
      'question': question,
      'options': movieIds,
      'expiresAt': DateTime.now().add(openFor).toUtc().toIso8601String(),
      'allowMultiple': allowMultiple,
    });
  } on ApiException catch (e) {
    final body = e.responseBody;
    final message = body is Map ? '${body['message'] ?? ''}'.toLowerCase() : '';
    return switch (e.statusCode) {
      403 => StartVoteRefusal.notMember,
      404 when message.contains('movie') => StartVoteRefusal.filmGone,
      404 => StartVoteRefusal.clubGone,
      _ => StartVoteRefusal.failed,
    };
  } catch (_) {
    return StartVoteRefusal.failed;
  }
  ref.invalidate(activePollsProvider(communityId));
  if (ref.exists(homeFeedProvider)) ref.invalidate(homeFeedProvider);
  return null;
}

/// Start a vote for a club (`/communities/:id/vote/new`): a question, 2 to
/// 10 of the club's films, how long it stays open, and whether people can
/// vote for more than one. Members only. Lands on the club's vote.
///
/// Gold budget: "Start the vote".
class StartVoteScreen extends ConsumerWidget {
  const StartVoteScreen({super.key, required this.communityId});
  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClubScaffold(
        communityId: communityId,
        title: 'Start a vote',
        builder: (context, club) => membershipIn(ref, club) == ClubMembership.notMember
            ? _Blocked(
                title: 'Votes are started by members',
                message: 'Join ${club.displayName} to start one.',
                actionLabel: 'Open club',
                onAction: () => context.pushReplacement('/communities/${club.id}'),
              )
            : _FilmsGate(club: club),
      );
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.title, required this.message, required this.actionLabel, required this.onAction});
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
        const SizedBox(height: AppSpacing.xxl),
        ClEmptyState(
          illustration: ClIllustration.polls,
          title: title,
          message: message,
          actionLabel: actionLabel,
          actionVariant: ClButtonVariant.secondary,
          onAction: onAction,
        ),
      ]);
}

class _FilmsGate extends ConsumerWidget {
  const _FilmsGate({required this.club});
  final Community club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = club.id ?? '';
    final films = ref.watch(clubFilmsProvider(id));
    return films.when(
      skipLoadingOnRefresh: films.hasValue,
      skipError: films.hasValue,
      loading: () => Semantics(
        label: 'Loading the club’s films',
        liveRegion: true,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: const [
            ClSkeleton(height: 56),
            SizedBox(height: AppSpacing.lg),
            ClSkeleton(height: 260),
          ],
        ),
      ),
      error: (_, __) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
        const SizedBox(height: AppSpacing.xxl),
        ClErrorState(title: "Couldn't load the club's films", onRetry: () => ref.invalidate(clubFilmsProvider(id))),
      ]),
      data: (list) => list.length < kVoteMinFilms
          ? _Blocked(
              title: 'A vote needs two films',
              message: list.isEmpty
                  ? '${club.displayName} has no films yet. Suggest some, then put them to a vote.'
                  : '${club.displayName} has one film so far. Suggest another to start a vote.',
              actionLabel: 'Suggest a film',
              onAction: () => context.pushReplacement('/communities/$id/suggest'),
            )
          : _VoteForm(club: club, films: list),
    );
  }
}

class _VoteForm extends ConsumerStatefulWidget {
  const _VoteForm({required this.club, required this.films});
  final Community club;
  final List<ClubFilm> films;

  @override
  ConsumerState<_VoteForm> createState() => _VoteFormState();
}

class _VoteFormState extends ConsumerState<_VoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _question = TextEditingController(text: 'What should we watch next?');

  /// Picked catalog ids, in the order picked.
  final _picked = <String>[];
  Duration _openFor = kVoteDurations[1].$2;
  bool _multiple = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Up to the first three films (newest suggestions) to start from.
    _picked.addAll(widget.films.take(3).map((f) => f.movieId));
  }

  /// After a refetch, drop picks that left the club.
  @override
  void didUpdateWidget(_VoteForm old) {
    super.didUpdateWidget(old);
    final ids = {for (final f in widget.films) f.movieId};
    _picked.removeWhere((id) => !ids.contains(id));
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _toggle(ClubFilm f) {
    setState(() {
      _error = null;
      if (!_picked.remove(f.movieId)) {
        if (_picked.length >= kVoteMaxFilms) {
          _error = 'A vote can have at most $kVoteMaxFilms films.';
          return;
        }
        _picked.add(f.movieId);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_picked.length < kVoteMinFilms) {
      setState(() => _error = 'Pick at least $kVoteMinFilms films.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final id = widget.club.id ?? '';
    final refusal = await startVote(
      ref,
      communityId: id,
      question: _question.text.trim(),
      movieIds: List.of(_picked),
      openFor: _openFor,
      allowMultiple: _multiple,
    );
    if (!mounted) return;
    if (refusal == null) {
      ClSnackbar.show(context, message: 'Vote started. The club can vote now.', type: ClSnackbarType.success);
      context.pushReplacement('/communities/$id/vote', extra: {'club': widget.club.displayName});
      return;
    }
    if (refusal == StartVoteRefusal.filmGone) ref.invalidate(clubFilmsProvider(id));
    setState(() {
      _submitting = false;
      _error = switch (refusal) {
        StartVoteRefusal.notMember => 'Only members of ${widget.club.displayName} can start its votes.',
        StartVoteRefusal.filmGone => 'A picked film is no longer in the club. Check your picks.',
        StartVoteRefusal.clubGone => 'This club no longer exists.',
        StartVoteRefusal.failed => "Couldn't start the vote. Check your connection and try again.",
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final qLen = _question.text.trim().length;
    final count = _picked.length;

    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
        children: [
          Text(
            'Put some of ${widget.club.displayName}’s films to a vote. The club sees the result when it closes.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          ClTextField(
            label: 'Question',
            controller: _question,
            prefixIcon: AppIcons.poll,
            helperText: '$qLen / $kVoteQuestionMax',
            inputFormatters: [LengthLimitingTextInputFormatter(kVoteQuestionMax)],
            validator: (v) => (v?.trim() ?? '').isEmpty ? 'Ask the club something' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: Text('Films', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Semantics(
            liveRegion: true,
            child: Text(
              '$count picked · pick $kVoteMinFilms to $kVoteMaxFilms',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(builder: (context, box) {
            // Three across, two on narrow screens with large text.
            final big = MediaQuery.textScalerOf(context).scale(16) / 16 >= 1.5;
            final cols = big ? 2 : 3;
            final w = (box.maxWidth - AppSpacing.md * (cols - 1)) / cols;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.lg,
              children: [
                for (final f in widget.films)
                  MoviePosterTile(
                    movie: f.film,
                    width: w,
                    selected: _picked.contains(f.movieId),
                    onTap: _submitting ? null : () => _toggle(f),
                  ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: Text('Open for', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
            for (final (label, d) in kVoteDurations)
              ClChip(
                label: label,
                isSelected: _openFor == d,
                onTap: _submitting ? null : () => setState(() => _openFor = d),
              ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          MergeSemantics(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vote for more than one', style: AppTextStyles.label),
                  Text(
                    _multiple ? 'Everyone can vote for every film they’d watch.' : 'Everyone gets one vote.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ]),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch(
                value: _multiple,
                onChanged: _submitting ? null : (v) => setState(() => _multiple = v),
                activeTrackColor: AppColors.purpleBadge,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ...[
            ClStatusBanner(type: ClStatusType.error, message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          ClButton(
            label: 'Start the vote',
            variant: ClButtonVariant.primary,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
