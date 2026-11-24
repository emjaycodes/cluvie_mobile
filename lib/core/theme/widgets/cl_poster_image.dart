import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_loading.dart';

enum ClScrim { none, bottom, top, both }

/// Network poster/backdrop with skeleton, error state, optional scrim and Hero.
/// Replaces every hand-rolled `CachedNetworkImage + Shimmer` block.
class ClPosterImage extends StatelessWidget {
  const ClPosterImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.md,
    this.heroTag,
    this.scrim = ClScrim.none,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final Object? heroTag;
  final ClScrim scrim;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final hasUrl = url != null && url!.isNotEmpty;

    Widget image = hasUrl
        ? CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: AppMotion.of(context).quick,
            fadeOutDuration: AppMotion.of(context).quick,
            placeholder: (_, __) => ClSkeleton(width: width, height: height, radius: 0),
            errorWidget: (_, __, ___) => _Fallback(width: width, height: height),
          )
        : _Fallback(width: width, height: height);

    if (scrim != ClScrim.none) {
      image = Stack(fit: StackFit.passthrough, children: [
        image,
        if (scrim == ClScrim.bottom || scrim == ClScrim.both)
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimBottom)),
            ),
          ),
        if (scrim == ClScrim.top || scrim == ClScrim.both)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimTop)),
            ),
          ),
      ]);
    }

    image = Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: ClipRRect(borderRadius: br, child: SizedBox(width: width, height: height, child: image)),
    );

    if (heroTag != null) {
      image = HeroMode(
        enabled: !AppMotion.of(context).reduced,
        child: Hero(tag: heroTag!, child: image),
      );
    }
    return image;
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceRaised,
        alignment: Alignment.center,
        child: const Icon(AppIcons.filmStrip, color: AppColors.textMuted, size: 28),
      );
}
