import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class ClTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final int maxLines;
  final Function(String)? onChanged;

  const ClTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:  TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight,
              fontSize: 14,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
