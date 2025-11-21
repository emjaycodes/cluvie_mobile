// ignore_for_file: deprecated_member_use

import 'package:cluvie_mobile/core/models/movie.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/features/movies/data/movie_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

// class MovieListScreen extends StatelessWidget {
//   const MovieListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Discover Movies", style :AppTextStyles.appBarTitle),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () => context.pushNamed('search'), // Route for search screen
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(AppSpacing.md),
//           child: ListView(
//             children: [
//                BigMovieItemWidget(),
//                SizedBox(
//                 height: AppSpacing.sm
//                ),
//                Text("what are they talking about", style: AppTextStyles.heading2,)
//                ],
//           )
//           ),
//         ),
//     );
//   }
// }

class MovieListScreen extends ConsumerStatefulWidget {
  const MovieListScreen({super.key});

  @override
  ConsumerState<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends ConsumerState<MovieListScreen> {
  // Simulate movie data
  final List<String> moviesImage = [
    'assets/images/f1.png',
    "assets/images/bb.png",
    "assets/images/black_mirror.png",
    "assets/images/bb.png",
    "assets/images/loveis_blind.png",
    'assets/images/f1.png',
  ];

  @override
  Widget build(BuildContext context) {
    final movieState = ref.watch(movieNotifierProvider);
    //     if (movieState.isLoading || movieState.movies.isEmpty) {
    //   return FeaturedMovieWidget(showShimmer: true, movie:movieState.movies[0]);
    // }

    if (movieState.error != null) {
      return Center(child: Text(movieState.error!));
    }

    if (movieState.movies.isEmpty) {
      return const Center(child: Text('No movies available'));
    }


    
    // if (movieState.movies. == null) {
    //   return Center(child: Shimmer.fromColors(
    //     baseColor: Colors.grey.shade300,
    //     highlightColor: Colors.grey.shade100,
    //     child: Container(
    //       width: 345,
    //       height: 487,
    //       margin: const EdgeInsets.only(bottom: AppSpacing.md),
    //       decoration: BoxDecoration(
    //         color: Colors.grey[200],
    //         borderRadius: BorderRadius.circular(16),
    //         boxShadow: [
    //           BoxShadow(
    //             color: Colors.black.withOpacity(0.5),
    //             blurRadius: 4,
    //             offset: const Offset(0, 2),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),);
    // }

    final numberOneMovie = movieState.movies[0];
    return Scaffold(
      appBar: AppBar(
        title: Text("Discover Movies", style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('movieSearch'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            children: [
              FeaturedMovieWidget(
                movie: numberOneMovie,
                showShimmer: false,
                error: movieState.error,
              ),

              const SizedBox(height: AppSpacing.lg),

              SectionTitle(title: "Trending in Discussions"),
              const SizedBox(height: AppSpacing.sm),
              const TrendingDiscussionsList(),

              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle(title: "Join a Community"),
                  TextButton(
                    onPressed: () {
                      context.pushNamed('allCommunities');
                    },
                    child: const Text(
                      'See more',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const CommunityList(),

              const SizedBox(height: AppSpacing.lg),

              SectionTitle(title: "Popular Movies"),
              const SizedBox(height: AppSpacing.sm),
              PopularMoviesGrid(
                movies: movieState.movies,
                showShimmer: movieState.isLoading,
                error: movieState.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.heading2);
  }
}

class FeaturedMovieWidget extends StatelessWidget {
  const FeaturedMovieWidget({
    super.key,
    required this.showShimmer,
    this.error,
    required this.movie,
  });
  final bool showShimmer;

  final String? error;
  final Movie movie;

  @override
  Widget build(BuildContext context) {
   if (error?.isNotEmpty == true || error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return InkWell(
      onTap: () {
        context.pushNamed('movieDetails', extra: movie);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
        imageUrl: movie.poster!,
        placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: 345,
          height: 487,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
        // Image.network(
        //   movie.poster,
        //   // width: 345,
        //   // height: 250,
        //   fit: BoxFit.fill,
        // ),
      ),
    );
    // : SizedBox(height: 20,);
  }
}

class TrendingDiscussionsList extends StatelessWidget {
  const TrendingDiscussionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return  Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/dis.png',
                      fit: BoxFit.cover,
                      width: 200,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    "Discussion Title",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
          // Shimmer.fromColors(
          //   baseColor: Colors.grey.shade300,
          //   highlightColor: Colors.grey.shade100,
          //   child: Container(
          //     width: 200,
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(12),
          //       color: Colors.white,
          //     ),
              
              
          //   ),
          // );
        },
      ),
    );
  }
}

class CommunityList extends StatelessWidget {
  const CommunityList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return CircleAvatar(radius: 40, foregroundImage: const AssetImage('assets/images/group.jpg'));
          // Shimmer.fromColors(
          //   enabled: false,
          //   baseColor: Colors.grey.shade300,
          //   highlightColor: Colors.grey.shade100,
          //   child: 
          // );
        },
      ),
    );
  }
}

class PopularMoviesGrid extends StatelessWidget {
  final bool showShimmer;
  final String? error;
  final List<Movie> movies;
  const PopularMoviesGrid({
    super.key,
    required this.showShimmer,
    required this.movies,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (showShimmer) {
      return GridView.builder(
        itemCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.7,
        ),
        itemBuilder:
            (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
              ),
            ),
      );
    }

    return GridView.builder(
      itemCount: movies.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return InkWell(
          onTap: () {
            context.pushNamed('movieDetails', extra: movie);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
        imageUrl: movie.poster!,
        placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
              ),
            ),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
            
            //  Image.network(movie.poster, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class BigMovieItemWidget extends StatelessWidget {
  // final String movieTitle;

  const BigMovieItemWidget({super.key});

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
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/you.png',
          // width: 345,
          // height: 250,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
