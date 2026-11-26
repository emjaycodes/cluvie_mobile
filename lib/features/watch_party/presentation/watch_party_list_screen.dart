import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/widgets/party_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watch parties (`/watch-parties`): live now, coming up, and past, from
/// `GET /watchparties`. Each opens its own page, where RSVP happens (one
/// RSVP per party, not one shared value: audit P0-8).
///
/// No "create" yet: parties are scheduled from a club's films, which isn't
/// built. Gold budget: none.
class WatchPartyListScreen extends ConsumerWidget {
  const WatchPartyListScreen({super.key, this.focus});

  /// Ignored. Home's demo cards passed a party here before Home read the
  /// real feed; kept so old callers still compile.
  final Map<String, dynamic>? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parties = ref.watch(watchPartiesProvider);
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();

    Future<void> refresh() async {
      final had = ref.read(watchPartiesProvider).hasValue;
      ref.invalidate(watchPartiesProvider);
      try {
        await ref.read(watchPartiesProvider.future);
      } catch (_) {
        if (had && context.mounted) {
          ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier parties.", type: ClSnackbarType.error);
        }
      }
    }

    Widget section(String title, List<WatchParty> list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.md),
              child: Semantics(header: true, child: Text(title, style: AppTextStyles.h3)),
            ),
            for (final (i, p) in list.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              ClEntrance(index: i, child: PartyTile(party: p, me: me)),
            ],
          ],
        );

    Widget body(List<Widget> children) => RefreshIndicator(
          onRefresh: refresh,
          color: AppColors.purple,
          backgroundColor: AppColors.surfaceRaised,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: children,
          ),
        );

    return Scaffold(
      appBar: const ClAppBar(title: 'Watch parties', frosted: true, fallbackRoute: '/home'),
      body: parties.when(
        skipLoadingOnRefresh: parties.hasValue,
        skipError: parties.hasValue,
        loading: () => Semantics(
          label: 'Loading watch parties',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const ClSkeletonRow(thumbWidth: 56, thumbHeight: 84),
              ],
            ],
          ),
        ),
        error: (_, __) => body([
          const SizedBox(height: AppSpacing.xxl),
          ClErrorState(title: "Couldn't load watch parties", onRetry: () => ref.invalidate(watchPartiesProvider)),
        ]),
        data: (all) {
          final live = [for (final p in all) if (p.status == PartyStatus.live) p];
          final upcoming = [
            for (final p in all)
              if (p.status == PartyStatus.scheduled && !p.isOver(now)) p,
          ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          final past = [
            for (final p in all)
              if (!live.contains(p) && !upcoming.contains(p)) p,
          ]..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          if (all.isEmpty) {
            return body([
              const SizedBox(height: AppSpacing.xxl),
              const ClEmptyState(
                illustration: ClIllustration.parties,
                title: 'No watch parties yet',
                message: "When a club plans one, it'll show up here.",
              ),
            ]);
          }
          return body([
            if (live.isNotEmpty) section('Happening now', live),
            if (upcoming.isNotEmpty)
              section('Coming up', upcoming)
            else
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.section),
                child: Text(
                  'Nothing planned right now.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ),
            if (past.isNotEmpty) section('Past', past),
          ]);
        },
      ),
    );
  }
}
