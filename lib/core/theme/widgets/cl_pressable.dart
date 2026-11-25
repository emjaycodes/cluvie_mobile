import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';

/// The tappable primitive behind every custom control.
///
/// * Press: scale to [AppMotion.pressScale], 6% white overlay, light haptic.
/// * Focus (keyboard / switch access): 2px gold [AppColors.focusRing], painted
///   *above* the child so opaque fills can't hide it.
/// * [hitPadding] enlarges the tappable area beyond the visual (48dp minimum)
///   without moving the ring or overlay off the visual.
/// * Disabled when both [onTap] and [onLongPress] are null.
class ClPressable extends StatefulWidget {
  const ClPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.borderRadius,
    this.semanticLabel,
    this.isButton = true,
    this.selected,
    this.hitPadding,
    this.excludeChildSemantics = false,
    this.checked,
    this.inMutuallyExclusiveGroup = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final bool isButton;

  /// Exposes a selected state to assistive tech (tabs, chips).
  final bool? selected;
  final EdgeInsetsGeometry? hitPadding;

  /// Use when [semanticLabel] fully describes the control.
  final bool excludeChildSemantics;

  /// Radio and checkbox controls: the checked state, announced as such.
  final bool? checked;

  /// Radio controls: one of a set where only one can be checked.
  final bool inMutuallyExclusiveGroup;

  @override
  State<ClPressable> createState() => _ClPressableState();
}

class _ClPressableState extends State<ClPressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final br = widget.borderRadius ?? BorderRadius.zero;

    Widget visual = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: br,
        color: _pressed ? Colors.white.withValues(alpha: 0.06) : null,
        border: _focused ? Border.all(color: AppColors.focusRing, width: 2) : null,
      ),
      child: widget.excludeChildSemantics ? ExcludeSemantics(child: widget.child) : widget.child,
    );
    if (widget.hitPadding != null) visual = Padding(padding: widget.hitPadding!, child: visual);

    // A container, so a control never merges into a heading or another
    // control above it (round 4, S2).
    return Semantics(
      container: true,
      button: widget.isButton,
      enabled: _enabled,
      selected: widget.selected,
      checked: widget.checked,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: motion.instant,
        curve: AppMotion.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            // Feedback is drawn by the foreground decoration above.
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.white.withValues(alpha: 0.03),
            canRequestFocus: _enabled,
            onTap: widget.onTap == null
                ? null
                : () {
                    if (widget.haptic) HapticFeedback.lightImpact();
                    widget.onTap!();
                  },
            onLongPress: widget.onLongPress,
            onHighlightChanged: (v) {
              if (_enabled && v != _pressed && mounted) setState(() => _pressed = v);
            },
            onFocusChange: (v) {
              if (v != _focused && mounted) setState(() => _focused = v);
            },
            child: visual,
          ),
        ),
      ),
    );
  }
}
