import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children:  [
            SizedBox(height: 16),
            SearchBarWidget(),
            // SizedBox(height: 12),
            // HashtagChipsWidget(),
            SizedBox(height: 24),
            MovieGridWidget(),
            SizedBox(height: 32),
            Text(
              'Suggested Clubs',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            SizedBox(height: 16),
            SuggestedClubsWidget(),
          ],
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(
        hintText: 'Search movies, clubs...',
        hintStyle: TextStyle(color: Colors.white54),
        // border: InputBorder.,
        // focusColor: Colors.white54,
        prefixIcon: Icon(Icons.search, color: Colors.white54),
      ),
      // style: TextStyle(color: Colors.white),
    );
  }
}

// class HashtagChipsWidget extends StatelessWidget {
//   const HashtagChipsWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final tags = ['#Drama', '#A24', '#Watchlist', '#Club'];
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: tags.map((tag) => Chip(
//         label: Text(tag),
//         backgroundColor: AppColors.darkSurface,
//         labelStyle: const TextStyle(color: Colors.white),
//       )).toList(),
//     );
//   }
// }

class MovieGridWidget extends StatelessWidget {
  const MovieGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = [
      {'title': 'Dune: Part Two', 'image': 'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg'},
      {'title': 'Batman', 'image': 'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg'},
      {'title': 'Everything everywhere all at once', 'image': 'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg'},
      {'title': 'Blade Runner 2049', 'image': 'https://image.tmdb.org/t/p/w500/aMpyrCizvSdc0UIMblJ1srVgAEF.jpg'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(movie['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie['title']!,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}

class SuggestedClubsWidget extends StatelessWidget {
  const SuggestedClubsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final clubs = [
      {'name': 'Chinatown Club', 'image': 'assets/images/group.jpg'},
      {'name': 'A24 Lovers', 'image': 'assets/images/group.jpg'},
      {'name': 'Drama Enthusiasts', 'image': 'assets/images/group.jpg'},
      {'name': 'Cinematic Universe', 'image': 'assets/images/group.jpg'},
      {'name': 'Watchlist Warriors', 'image': 'assets/images/group.jpg'},
    ];

    return Column(
      children: clubs.map((club) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(club['image']!),
              fit: BoxFit.cover,
            ),
          ),
          height: 140,
          child: Stack(
            children: [
              Positioned(
                left: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club['name']!,
                      style: AppTextStyles.heading2.copyWith(color: AppColors.lightTextPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Join Club', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
