import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Labelled text field. Styling comes from the theme's InputDecorationTheme
/// (raised fill, ≥3:1 resting border, 2px gold focus ring, 2px error border).
class ClTextField extends StatefulWidget {
  const ClTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.errorText,
    this.helperText,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.focusNode,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType keyboardType;
  final bool isPassword;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final String? errorText;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<ClTextField> createState() => _ClTextFieldState();
}

class _ClTextFieldState extends State<ClTextField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    // MergeSemantics gives the field its visible label as accessible name.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            obscureText: _obscured,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: widget.errorText,
              helperText: widget.helperText,
              prefixIcon:
                  hasError
                      ? const Icon(AppIcons.error, size: 20, color: AppColors.error)
                      : widget.prefixIcon == null
                      ? null
                      : Icon(widget.prefixIcon, size: 20),
              suffixIcon:
                  widget.isPassword
                      ? IconButton(
                        tooltip: _obscured ? 'Show password' : 'Hide password',
                        icon: Icon(_obscured ? AppIcons.eye : AppIcons.eyeSlash, size: 20),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
