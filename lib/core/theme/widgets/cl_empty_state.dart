import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
class ClEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final double iconSize;

  const ClEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.movie_filter_outlined,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
