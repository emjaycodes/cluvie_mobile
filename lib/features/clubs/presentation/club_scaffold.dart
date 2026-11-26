import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A club sub-screen (About, Membership): app bar plus the club's loading,
/// not-found and error states. [builder] gets the loaded club.
class ClubScaffold extends ConsumerWidget {
  const ClubScaffold({super.key, required this.communityId, required this.title, required this.builder});

  final String communityId;
  final String title;
  final Widget Function(BuildContext context, Community club) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(communityProvider(communityId));
    return Scaffold(
      appBar: ClAppBar(title: title, frosted: true, fallbackRoute: '/communities/$communityId'),
      body: club.when(
        skipLoadingOnRefresh: club.hasValue,
        skipError: club.hasValue,
        loading: () => Semantics(
          label: 'Loading club',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: const [
              ClSkeleton(height: 28, width: 200),
              SizedBox(height: AppSpacing.lg),
              ClSkeleton(height: 96),
              SizedBox(height: AppSpacing.lg),
              ClSkeleton(height: 96),
            ],
          ),
        ),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            if (e is ClubNotFound)
              ClEmptyState(
                illustration: ClIllustration.clubs,
                title: "This club doesn't exist",
                message: 'It may have been removed, or the link is wrong.',
                actionLabel: 'Browse clubs',
                actionVariant: ClButtonVariant.secondary,
                onAction: () => context.go('/communities'),
              )
            else
              ClErrorState(title: "Couldn't load this club", onRetry: () => ref.invalidate(communityProvider(communityId))),
          ],
        ),
        data: (c) => builder(context, c),
      ),
    );
  }
}
