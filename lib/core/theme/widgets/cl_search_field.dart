import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Pill search bar: search glyph (a spinner while [busy]), hint, and a 48dp
/// clear button once there's text. The keyboard's action is "search".
///
/// Unlike [ClTextField] it has no visible label; the hint names it for screen
/// readers, so make the hint say what is searched.
class ClSearchField extends StatefulWidget {
  const ClSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.busy = false,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after the clear button empties the field.
  final VoidCallback? onCleared;

  /// Shows a spinner in place of the search glyph (a search is in flight).
  final bool busy;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<ClSearchField> createState() => _ClSearchFieldState();
}

class _ClSearchFieldState extends State<ClSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(ClSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  // Rebuild so the clear button appears and disappears with the text.
  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.body,
      cursorColor: AppColors.purpleText,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        // Theme input tokens on a pill: borderInput at rest (>= 3:1, WCAG
        // 1.4.11) and the 2px focusRing when focused.
        border: const OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide(color: AppColors.borderInput),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide(color: AppColors.borderInput),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide(color: AppColors.focusRing, width: 2),
        ),
        prefixIcon: SizedBox(
          width: 48,
          child: Center(
            child:
                widget.busy
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
                    )
                    : const Icon(AppIcons.search, size: 20, color: AppColors.textSecondary),
          ),
        ),
        suffixIcon:
            hasText
                ? IconButton(
                  tooltip: 'Clear search',
                  constraints: const BoxConstraints(minWidth: AppSpacing.minTouch, minHeight: AppSpacing.minTouch),
                  icon: const Icon(AppIcons.close, size: 20, color: AppColors.textSecondary),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                    widget.onCleared?.call();
                  },
                )
                : null,
      ),
    );
  }
}
