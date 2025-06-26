import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class ReactionFooter extends StatelessWidget {
  const ReactionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            child: CircleAvatar(
              radius: 10,
              backgroundImage: AssetImage('assets/images/dpboy.jpg'),
            ),
          ),
          const TextSpan(text: "  David just reacted to "),
          TextSpan(
            text: "Her (2013)",
            style: TextStyle(color: AppColors.accent),
          ),
          const WidgetSpan(
            child: Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
        style: AppTextStyles.caption.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}