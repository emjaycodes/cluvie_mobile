import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class UpcomingWatchCard extends StatelessWidget {
  final String imageUrl =
      'https://image.tmdb.org/t/p/w200/8QVDXDiOGHRcAD4oM6MXjE0osSj.jpg';
  const UpcomingWatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 48,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // mainAxisAlignment: MainAxisAlignment.,
                children: [
                  Text(
                    "SAT, APR 13 ",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  Text(
                    "AT ",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  Text(
                    "8:00 PM",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Arrival",
                style: AppTextStyles.heading2.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}