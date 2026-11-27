import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// `/watchParty` without a party id (old demo links). With an id in
/// `extra` the route redirects to that party's live room; without one
/// there's no room to open, so this points to the list.
class WatchPartyScreen extends StatelessWidget {
  const WatchPartyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const ClAppBar(title: 'Live room', fallbackRoute: '/watch-parties'),
        body: ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
          const SizedBox(height: AppSpacing.xl),
          ClEmptyState(
            illustration: ClIllustration.parties,
            title: 'Pick a watch party',
            message: "Each party has its own live room. Open one you're going to.",
            actionLabel: 'See watch parties',
            actionVariant: ClButtonVariant.secondary,
            onAction: () => context.pushReplacement('/watch-parties'),
          ),
        ]),
      );
}
