import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';


// class MovieListScreen extends StatelessWidget {
//   const MovieListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Simulate movie data
//     // final List<String> movies = [
//     //   'The Dark Knight',
//     //   // 'Inception',
//     //   // 'Interstellar',
//     //   // 'The Matrix',
//     //   // 'Avatar'
//     // ];

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


class MovieListScreen extends StatefulWidget {
   MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  // Simulate movie data
  final List<String> moviesImage = [
    'assets/images/f1.png',
    "assets/images/bb.png",
    "assets/images/black_mirror.png",
    "assets/images/bb.png",
    "assets/images/loveis_blind.png",
    'assets/images/f1.png',
  ];

    bool _showShimmer = true;

    @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Movies", style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('search'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            children: [
              //  🟥 Featured Movie Banner
               FeaturedMovieWidget(showShimmer: _showShimmer,),

              const SizedBox(height: AppSpacing.lg),

              // 🟩 Trending Discussions
              SectionTitle(title: "What's Trending in Discussions"),
              const SizedBox(height: AppSpacing.sm),
              const TrendingDiscussionsList(),

              const SizedBox(height: AppSpacing.lg),

              // 🟦 Explore Communities
              SectionTitle(title: "Join a Community"),
              const SizedBox(height: AppSpacing.sm),
              const CommunityList(),

              const SizedBox(height: AppSpacing.lg),

              // 🟪 Popular Movies
              SectionTitle(title: "Popular Movies"),
              const SizedBox(height: AppSpacing.sm),
               PopularMoviesGrid(showShimmer: _showShimmer, image: moviesImage,),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Reusable Widgets ---

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.heading2);
  }
}

class FeaturedMovieWidget extends StatelessWidget {
   FeaturedMovieWidget({super.key, required this.showShimmer});
  final bool showShimmer;

//   @override
//   State<FeaturedMovieWidget> createState() => _FeaturedMovieWidgetState();
// }

// class _FeaturedMovieWidgetState extends State<FeaturedMovieWidget> {
//   bool _showShimmer = true;

//     @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration(seconds: 2), () {
//       if (mounted) {
//         setState(() {
//           _showShimmer = false;
//         });
//       }
//     });
//   }

  @override
  Widget build(BuildContext context) {
    // Placeholder shimmer while real movie loads
    return 
    showShimmer ?
     Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child:  Container(
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
      )
    ) : ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/you.png', // Placeholder image
          // width: 345,
          // height: 250,
          fit: BoxFit.fill,
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
        itemCount: 5, // Later you replace this with real discussions
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          );
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
        itemCount: 5, // Real communities later
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class PopularMoviesGrid extends StatefulWidget {
  final bool showShimmer;
  final List<String> image;
  const PopularMoviesGrid({super.key,  this.showShimmer = true, required this.image});
  
  @override
  State<PopularMoviesGrid> createState() => _PopularMoviesGridState();
}


class _PopularMoviesGridState extends State<PopularMoviesGrid> {
  

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6, // Later fetch real movies
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        return widget.showShimmer ? Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            
          ),
        ) : ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
           widget.image[index],
          // width: 345,
          // height: 250,
          fit: BoxFit.fill,
        ),
      );
      },
    );
  }
}


class BigMovieItemWidget extends StatelessWidget {
  // final String movieTitle;

  const BigMovieItemWidget({super.key, });

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
          'assets/images/you.png', // Placeholder image
          // width: 345,
          // height: 250,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
