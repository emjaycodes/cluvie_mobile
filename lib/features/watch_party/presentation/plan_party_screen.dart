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
import 'package:cluvie_mobile/features/movies/presentation/club_discussions_screen.dart' show ClubFilm, clubFilmsProvider;
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const kPartyTitleMax = 80;
const kPartyDescriptionMax = 300;

/// The default start: 8pm today, or tomorrow when that's under an hour away.
DateTime defaultPartyStart(DateTime now) {
  final tonight = DateTime(now.year, now.month, now.day, 20);
  return tonight.difference(now) >= const Duration(hours: 1) ? tonight : tonight.add(const Duration(days: 1));
}

/// Why scheduling didn't happen.
enum PlanRefusal { notMember, inPast, filmGone, clubGone, failed }

/// `POST /watchparties`. [movieId] is the catalog id of one of the club's
/// films: the backend looks the film up and never adds it to the catalog.
/// Its refusals carry no `code`, so they're told apart by status and text.
Future<(WatchParty?, PlanRefusal?)> scheduleParty(
  WidgetRef ref, {
  required String communityId,
  required String movieId,
  required String title,
  required DateTime startsAt,
  String? description,
  bool isPrivate = false,
}) async {
  try {
    final res = await ref.read(apiClientProvider).post('/watchparties', data: {
      'title': title,
      'movieId': movieId,
      'communityId': communityId,
      'scheduledAt': startsAt.toUtc().toIso8601String(),
      if (description != null && description.isNotEmpty) 'description': description,
      'isPrivate': isPrivate,
    });
    final body = res.data;
    final party = WatchParty.fromJson(body is Map ? body['data'] : null);
    ref.invalidate(watchPartiesProvider);
    if (ref.exists(homeFeedProvider)) ref.invalidate(homeFeedProvider);
    return party == null ? (null, PlanRefusal.failed) : (party, null);
  } on ApiException catch (e) {
    final body = e.responseBody;
    final message = body is Map ? '${body['message'] ?? ''}'.toLowerCase() : '';
    return (
      null,
      switch (e.statusCode) {
        403 => PlanRefusal.notMember,
        400 when message.contains('future') => PlanRefusal.inPast,
        404 when message.contains('movie') => PlanRefusal.filmGone,
        404 => PlanRefusal.clubGone,
        _ => PlanRefusal.failed,
      },
    );
  } catch (_) {
    return (null, PlanRefusal.failed);
  }
}

/// Plan a watch party for a club (`/communities/:id/watch-party/new`):
/// one of the club's films, a title, a start time, an optional note, and
/// whether only members can see it. Members only. Lands on the new party.
///
/// [movieId] preselects a film (the catalog id).
///
/// Gold budget: "Schedule watch party".
class PlanPartyScreen extends ConsumerWidget {
  const PlanPartyScreen({super.key, required this.communityId, this.movieId});
  final String communityId;
  final String? movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClubScaffold(
        communityId: communityId,
        title: 'Plan a watch party',
        builder: (context, club) => membershipIn(ref, club) == ClubMembership.notMember
            ? _Blocked(
                title: 'Watch parties are planned by members',
                message: 'Join ${club.displayName} to plan one.',
                actionLabel: 'Open club',
                onAction: () => context.pushReplacement('/communities/${club.id}'),
              )
            : _FilmsGate(club: club, movieId: movieId),
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
          illustration: ClIllustration.parties,
          title: title,
          message: message,
          actionLabel: actionLabel,
          actionVariant: ClButtonVariant.secondary,
          onAction: onAction,
        ),
      ]);
}

/// The club's films, or why there's nothing to pick from.
class _FilmsGate extends ConsumerWidget {
  const _FilmsGate({required this.club, this.movieId});
  final Community club;
  final String? movieId;

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
            ClSkeleton(height: 220),
            SizedBox(height: AppSpacing.lg),
            ClSkeleton(height: 56),
            SizedBox(height: AppSpacing.lg),
            ClSkeleton(height: 120),
          ],
        ),
      ),
      error: (_, __) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
        const SizedBox(height: AppSpacing.xxl),
        ClErrorState(title: "Couldn't load the club's films", onRetry: () => ref.invalidate(clubFilmsProvider(id))),
      ]),
      data: (list) => list.isEmpty
          ? _Blocked(
              title: 'Suggest a film first',
              message: 'A watch party is for one of the club’s films, and ${club.displayName} has none yet.',
              actionLabel: 'Suggest a film',
              onAction: () => context.pushReplacement('/communities/$id/suggest'),
            )
          : _PlanForm(club: club, films: list, movieId: movieId),
    );
  }
}

class _PlanForm extends ConsumerStatefulWidget {
  const _PlanForm({required this.club, required this.films, this.movieId});
  final Community club;
  final List<ClubFilm> films;
  final String? movieId;

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  late ClubFilm _film;
  late DateTime _startsAt;

  /// The title still follows the film until the user types their own.
  bool _titleEdited = false;
  bool _private = false;
  bool _submitting = false;
  String? _error;

  static String _titleFor(ClubFilm f) => '${f.film.title} night';

  @override
  void initState() {
    super.initState();
    _film = widget.films.firstWhere((f) => f.movieId == widget.movieId, orElse: () => widget.films.first);
    _title.text = _titleFor(_film);
    _startsAt = defaultPartyStart(DateTime.now());
  }

  /// After a refetch the picked film may be gone from the club.
  @override
  void didUpdateWidget(_PlanForm old) {
    super.didUpdateWidget(old);
    if (!widget.films.any((f) => f.movieId == _film.movieId)) {
      _film = widget.films.first;
      if (!_titleEdited) _title.text = _titleFor(_film);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _pickFilm(ClubFilm f) {
    setState(() {
      _film = f;
      if (!_titleEdited) _title.text = _titleFor(f);
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startsAt.isBefore(today) ? today : _startsAt,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Party date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(picked.year, picked.month, picked.day, _startsAt.hour, _startsAt.minute);
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
      helpText: 'Starts at',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(_startsAt.year, _startsAt.month, _startsAt.day, picked.hour, picked.minute);
      _error = null;
    });
  }

  bool get _inPast => !_startsAt.isAfter(DateTime.now());

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_inPast) {
      setState(() => _error = 'That time has passed. Pick a later one.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final (party, refusal) = await scheduleParty(
      ref,
      communityId: widget.club.id ?? '',
      movieId: _film.movieId,
      title: _title.text.trim(),
      startsAt: _startsAt,
      description: _note.text.trim(),
      isPrivate: _private,
    );
    if (!mounted) return;
    if (party != null) {
      ClSnackbar.show(context, message: 'Watch party scheduled. The club gets a heads-up.', type: ClSnackbarType.success);
      context.pushReplacement('/watch-parties/${party.id}');
      return;
    }
    if (refusal == PlanRefusal.filmGone) ref.invalidate(clubFilmsProvider(widget.club.id ?? ''));
    setState(() {
      _submitting = false;
      _error = switch (refusal) {
        PlanRefusal.notMember => 'Only members of ${widget.club.displayName} can plan its watch parties.',
        PlanRefusal.inPast => 'That time has passed. Pick a later one.',
        PlanRefusal.filmGone => 'That film is no longer in the club. Pick another.',
        PlanRefusal.clubGone => 'This club no longer exists.',
        _ => "Couldn't schedule the party. Check your connection and try again.",
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final titleLen = _title.text.trim().length;
    final noteLen = _note.text.trim().length;
    const posterWidth = 104.0;
    final films = widget.films;
    final date = DateFormat.yMMMEd().format(_startsAt);
    final time = DateFormat.jm().format(_startsAt);

    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl + bottom),
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Text(
              'Pick one of ${widget.club.displayName}’s films and a time. Members get a notification.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: AppSpacing.screen,
            child: Semantics(header: true, child: Text('Film', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary))),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: posterWidth * 3 / 2 + MoviePosterTile.textHeight(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: films.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final f = films[i];
                return MoviePosterTile(
                  movie: f.film,
                  width: posterWidth,
                  selected: f.movieId == _film.movieId,
                  onTap: _submitting ? null : () => _pickFilm(f),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: AppSpacing.screen,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ClTextField(
                label: 'Title',
                controller: _title,
                prefixIcon: AppIcons.ticket,
                textInputAction: TextInputAction.next,
                helperText: '$titleLen / $kPartyTitleMax',
                inputFormatters: [LengthLimitingTextInputFormatter(kPartyTitleMax)],
                validator: (v) => (v?.trim() ?? '').isEmpty ? 'Give the party a title' : null,
                onChanged: (_) => setState(() => _titleEdited = true),
              ),
              const SizedBox(height: AppSpacing.lg),
              ClCard(
                child: Column(children: [
                  _WhenRow(icon: AppIcons.calendar, label: 'Date', value: date, onTap: _submitting ? null : _pickDate),
                  const Divider(height: 1, color: AppColors.border),
                  _WhenRow(icon: AppIcons.clock, label: 'Starts', value: time, onTap: _submitting ? null : _pickTime),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
              ClTextField(
                label: 'Note for the club (optional)',
                controller: _note,
                hintText: 'e.g. Bring snacks. We start on time.',
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                helperText: '$noteLen / $kPartyDescriptionMax',
                inputFormatters: [LengthLimitingTextInputFormatter(kPartyDescriptionMax)],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              MergeSemantics(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Members only', style: AppTextStyles.label),
                      Text(
                        _private
                            ? 'Only ${widget.club.displayName} members can see it.'
                            : 'Anyone on Cluvie can see it. Only members can join.',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                      ),
                    ]),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Switch(
                    value: _private,
                    onChanged: _submitting ? null : (v) => setState(() => _private = v),
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
                label: 'Schedule watch party',
                variant: ClButtonVariant.primary,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _WhenRow extends StatelessWidget {
  const _WhenRow({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClPressable(
        semanticLabel: '$label $value. Change',
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.label),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyles.title.copyWith(color: AppColors.purpleText),
              ),
            ),
          ]),
        ),
      );
}
