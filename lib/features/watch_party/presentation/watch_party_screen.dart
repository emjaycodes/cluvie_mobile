import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The live co-watching room (`/watchParty`). It needs the socket events
/// (`watchparty:join`, presence) and the app has no socket client yet, so
/// while [kWatchPartyRoomAvailable] is false this says so plainly instead of
/// showing a room where nothing works (audit 1.29, P0-4).
class WatchPartyScreen extends StatelessWidget {
  const WatchPartyScreen({
    super.key,
    this.title,
    this.minutesLeft,
    this.partyId,
  });

  /// Kept for old callers (Home's demo cards); unused.
  final String? title;
  final int? minutesLeft;

  /// The party to go back to, when known.
  final String? partyId;

  @override
  Widget build(BuildContext context) {
    final id = partyId;
    return Scaffold(
      appBar: ClAppBar(
        title: 'Live room',
        fallbackRoute: id == null ? '/watch-parties' : '/watch-parties/$id',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          const SizedBox(height: AppSpacing.xl),
          ClEmptyState(
            illustration: ClIllustration.parties,
            title: "Live rooms aren't open yet",
            message:
                'RSVP to a watch party and meet up at the time it says. Watching together in the app is coming.',
            actionLabel: id == null ? 'See watch parties' : 'Open the party',
            actionVariant: ClButtonVariant.secondary,
            onAction:
                () => context.pushReplacement(
                  id == null ? '/watch-parties' : '/watch-parties/$id',
                ),
          ),
        ],
      ),
    );
  }
}
