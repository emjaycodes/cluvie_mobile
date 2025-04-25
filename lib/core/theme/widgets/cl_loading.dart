import 'package:flutter/material.dart';

class ClLoading extends StatelessWidget {
  final double size;

  const ClLoading({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
