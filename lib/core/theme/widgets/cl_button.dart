import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class ClButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isLoading;

  const ClButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: isSecondary ? Colors.white : AppColors.goldenPopcorn,
      foregroundColor: isSecondary ? AppColors.cinematicPurple : Colors.white,
      side:
          isSecondary
              ? BorderSide(color: AppColors.cinematicPurple, width: 1.5)
              : BorderSide.none,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: AppTextStyles.heading2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child:
            isLoading
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(label),
      ),
    );
  }
}
