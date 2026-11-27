import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The message box under a chat: a growing text field and a round Send
/// button (enabled when there's text). Used by watch-party rooms and club chat.
class ClChatComposer extends StatelessWidget {
  const ClChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.hintText,
    this.disabledHint = 'Joining…',
    this.maxLength = 500,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;

  /// Shown while enabled; [disabledHint] while not (connecting).
  final String hintText;
  final String disabledHint;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final canSend = enabled && !sending && controller.text.trim().isNotEmpty;
    const border = OutlineInputBorder(borderRadius: AppRadius.xlAll, borderSide: BorderSide(color: AppColors.borderInput));
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled && !sending,
                  minLines: 1,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: enabled ? hintText : disabledHint,
                    hintMaxLines: 1,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.xlAll,
                      borderSide: BorderSide(color: AppColors.focusRing, width: 2),
                    ),
                    disabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.xlAll,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: AppSpacing.minTouch,
              height: AppSpacing.minTouch,
              child: IconButton(
                tooltip: 'Send',
                onPressed: canSend ? onSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.purpleBadge,
                  disabledBackgroundColor: AppColors.surfaceRaised,
                  shape: const CircleBorder(),
                ),
                icon: sending
                    ? const ClLoading(size: 20, color: AppColors.textPrimary)
                    : Icon(AppIcons.send, size: 20, color: canSend ? AppColors.onPurpleBadge : AppColors.textSecondary),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
