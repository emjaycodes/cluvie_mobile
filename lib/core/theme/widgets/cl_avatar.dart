import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Avatar with initials fallback and optional gold ring (e.g. host, you).
class ClAvatar extends StatelessWidget {
  const ClAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.ring = false,
    this.borderColor,
    this.neutral = false,
  });

  final String? imageUrl;

  /// Used for the initials fallback and semantics.
  final String? name;
  final double radius;

  /// Purple ring around the avatar (host, you). Gold is reserved (gold budget).
  final bool ring;

  /// Thin separating border, used by [ClAvatarStack].
  final Color? borderColor;

  /// An unnamed person: a neutral placeholder with no initials (R11-N3).
  final bool neutral;

  String get _initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  // Deterministic tint so the same person keeps the same colour.
  Color get _tint {
    const tints = [Color(0xFF3A2D5C), Color(0xFF2B3D55), Color(0xFF4A2F3F), Color(0xFF2F4A43), Color(0xFF4A402A)];
    return tints[(name ?? '').hashCode.abs() % tints.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final fallback = Container(
      color: neutral ? AppColors.surfaceRaised : _tint,
      alignment: Alignment.center,
      // Initials are part of the picture, sized to the fixed circle; the name
      // is in semantics, so they don't scale with text size.
      child: neutral
          ? Icon(AppIcons.profile, size: radius * 0.9, color: AppColors.textSecondary)
          : Text(
              _initials,
              textScaler: TextScaler.noScaling,
              maxLines: 1,
              softWrap: false,
              style: AppTextStyles.label.copyWith(fontSize: radius * 0.7, color: AppColors.textPrimary),
            ),
    );

    Widget avatar = ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceRaised),
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );

    if (borderColor != null || ring) {
      avatar = Container(
        padding: EdgeInsets.all(ring ? 2.5 : 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor ?? AppColors.bg,
          gradient: ring
              ? const LinearGradient(colors: [AppColors.purpleText, AppColors.purpleBadge])
              : null,
        ),
        child: ring
            ? Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg),
                child: avatar,
              )
            : avatar,
      );
    }

    if (name == null) return ExcludeSemantics(child: avatar);
    return Semantics(label: name, image: true, excludeSemantics: true, child: avatar);
  }
}

/// Overlapping avatars + optional "Ada, Tunde +6" caption.
class ClAvatarStack extends StatelessWidget {
  const ClAvatarStack({
    super.key,
    required this.people,
    this.total,
    this.max = 3,
    this.radius = 12,
    this.showCaption = true,
    this.suffix = 'going',
    this.borderColor = AppColors.surface,
  });

  /// (name, imageUrl) pairs.
  final List<({String name, String? imageUrl})> people;

  /// Total count when larger than [people] (e.g. from the API).
  final int? total;
  final int max;
  final double radius;
  final bool showCaption;
  final String suffix;

  /// Should match the surface the stack sits on.
  final Color borderColor;

  String get caption {
    final count = total ?? people.length;
    if (count == 0) return 'No one $suffix yet';
    final named = people.take(2).map((p) => p.name.split(' ').first).toList();
    final rest = count - named.length;
    return rest > 0 ? '${named.join(', ')} +$rest $suffix' : '${named.join(' and ')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    final step = radius * 1.4;
    final size = radius * 2 + 4;
    return Semantics(
      label: caption,
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (shown.isNotEmpty)
          SizedBox(
            width: size + step * (shown.length - 1),
            height: size,
            child: Stack(children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * step,
                  child: ClAvatar(
                    imageUrl: shown[i].imageUrl,
                    name: shown[i].name,
                    radius: radius,
                    borderColor: borderColor,
                  ),
                ),
            ]),
          ),
        if (showCaption) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(caption, style: AppTextStyles.bodySm, overflow: TextOverflow.ellipsis),
          ),
        ],
      ]),
    );
  }
}
