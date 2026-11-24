import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';

/// Press feedback used by every tappable surface: scale to
/// [AppMotion.pressScale] + light haptic. Disabled when [onTap] is null.
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
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final bool isButton;

  @override
  State<ClPressable> createState() => _ClPressableState();
}

class _ClPressableState extends State<ClPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return Semantics(
      button: widget.isButton,
      enabled: enabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: motion.instant,
        curve: AppMotion.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: widget.borderRadius,
            onTap: widget.onTap == null
                ? null
                : () {
                    if (widget.haptic) HapticFeedback.lightImpact();
                    widget.onTap!();
                  },
            onLongPress: widget.onLongPress,
            onHighlightChanged: enabled ? _set : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
