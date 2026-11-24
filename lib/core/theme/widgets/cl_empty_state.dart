import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';

/// Bundled empty-state illustrations (assets/illustrations).
enum ClIllustration {
  polls('empty_polls'),
  discussions('empty_discussions'),
  clubs('empty_clubs'),
  notifications('empty_notifications'),
  search('empty_search'),
  parties('empty_parties'),
  offline('offline');

  const ClIllustration(this.file);
  final String file;
  String get asset => 'assets/illustrations/$file.svg';
}

/// Illustration on a purple glow + title + message + one action.
class ClEmptyState extends StatelessWidget {
  const ClEmptyState({
    super.key,
    required this.message,
    this.title,
    this.illustration,
    this.icon = AppIcons.filmStrip,
    this.iconSize = 48,
    this.actionLabel,
    this.onAction,
    this.actionVariant = ClButtonVariant.secondary,
    this.compact = false,
  });

  final String message;
  final String? title;
  final ClIllustration? illustration;

  /// Used when no [illustration] is given.
  final IconData icon;
  final double iconSize;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ClButtonVariant actionVariant;

  /// Card-sized variant for inline sections.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final art = compact ? 88.0 : 128.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: compact ? AppSpacing.lg : AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: art,
            height: art,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow),
            child: illustration != null
                ? SvgPicture.asset(illustration!.asset, width: art * 0.6, height: art * 0.6, excludeFromSemantics: true)
                : Icon(icon, size: compact ? iconSize * 0.75 : iconSize, color: AppColors.textSecondary),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          if (title != null) ...[
            Text(title!, style: compact ? AppTextStyles.title : AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: compact ? 14 : 15),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            ClButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: actionVariant,
              size: compact ? ClButtonSize.sm : ClButtonSize.md,
              expand: false,
            ),
          ],
        ]),
      ),
    );
  }
}

/// Screen/section error with plain-language message and Retry.
class ClErrorState extends StatelessWidget {
  const ClErrorState({
    super.key,
    this.title = "Couldn't load this",
    this.message = 'Check your connection and try again.',
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => ClEmptyState(
        illustration: ClIllustration.offline,
        title: title,
        message: message,
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
        compact: compact,
      );
}
