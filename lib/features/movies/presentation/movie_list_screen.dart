import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate movie data
    // final List<String> movies = [
    //   'The Dark Knight',
    //   // 'Inception',
    //   // 'Interstellar',
    //   // 'The Matrix',
    //   // 'Avatar'
    // ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Movies"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('search'), // Route for search screen
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            children: [
               MovieItemWidget()],
          )
          ),
        ),
    );
  }
}

class MovieItemWidget extends StatelessWidget {
  // final String movieTitle;

  const MovieItemWidget({super.key, });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 345,
      height: 487,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/you.png', // Placeholder image
          // width: 345,
          // height: 250,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
