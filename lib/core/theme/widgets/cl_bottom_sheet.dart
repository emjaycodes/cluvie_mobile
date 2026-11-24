import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Sheet body: title + content. The handle, radius and colour come from the
/// theme (BottomSheetThemeData). Open with [showClSheet].
class ClBottomSheet extends StatelessWidget {
  const ClBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.height,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Fixed height; when null the sheet sizes to content (max 90%).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Semantics(header: true, child: Text(title, style: AppTextStyles.h2)),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTextStyles.bodySm),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (height == null) Flexible(child: child) else Expanded(child: child),
        ],
      ),
    );
    return height == null ? content : SizedBox(height: height, child: content);
  }
}

/// Opens a themed modal sheet (max 90% height, keyboard-aware).
Future<T?> showClSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  String? subtitle,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (_) => ClBottomSheet(title: title, subtitle: subtitle, child: child),
  );
}
