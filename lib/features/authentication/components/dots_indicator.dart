import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';

class DotsIndicatorWidget extends StatelessWidget {
  final int pageLength; 
  final int currentPage; 
  const DotsIndicatorWidget({super.key, required this.pageLength, required this.currentPage});
  
  
  @override
  Widget build(BuildContext context) {
    return  DotsIndicator(
  dotsCount: pageLength,
  position: currentPage.toDouble(),
  decorator: DotsDecorator(
    color: Colors.grey, // Inactive color
    activeColor:AppColors.cinematicPurple,
  ),
);
  }
}