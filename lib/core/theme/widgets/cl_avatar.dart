import 'package:flutter/material.dart';

class ClAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ClAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24, required String url,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl ?? "https://image.tmdb.org/t/p/w500/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg"),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
