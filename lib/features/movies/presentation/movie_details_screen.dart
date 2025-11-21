// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// class MovieDetailScreen extends StatelessWidget {
//   final Movie movie;

//   const MovieDetailScreen({super.key, required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     print('MovieDetailScreen: ${movie.genreNames?[0]}');
//     return Scaffold(
//       body: DefaultTabController(
//         length: 2,
//         child: NestedScrollView(
//           headerSliverBuilder:
//               (context, innerBoxIsScrolled) => [
//                 SliverAppBar(
//                   expandedHeight: 200,
//                   pinned: true,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: CachedNetworkImage(
//                             imageUrl: movie.backdrop,
//                             fit: BoxFit.cover,
//                             placeholder: (context, url) => Shimmer.fromColors(
//                                   baseColor: Colors.grey.shade300,
//                                   highlightColor: Colors.grey.shade100,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(12),
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                             errorWidget: (context, url, error) => Icon(Icons.error),
//                          ),
//                     // title: Text(movie.title),
//                   ),
//                 ),
//               ],
//           body: Column(
//             children: [
//               _MovieInfo(movie: movie),
//               DefaultTabController(
//                 length: 2,
//                 child: Column(
//                   children: [
//                     Container(
//                       height: 48,
//                       decoration: BoxDecoration(
//                         // color: Colors.grey[900], // Background of the TabBar
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: TabBar(
//                         indicator: BoxDecoration(
//                           color:
//                               AppColors
//                                   .cinematicPurple, // Change to your desired selected tab color
//                           borderRadius: BorderRadius.circular(
//                             8,
//                           ), // Optional: Rounded corners
//                         ),
//                         indicatorSize: TabBarIndicatorSize.tab,
//                         tabs: [Tab(text: 'Talks'), Tab(text: 'Discussions')],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: TabBarView(
//                   children: [
//                     MovieTalksTab(movieId: movie.id),
//                     MovieDiscussionsTab(movieId: movie.id),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MovieInfo extends StatelessWidget {
//   final Movie movie;

//   const _MovieInfo({required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             movie.title,
//             style: AppTextStyles.heading1.copyWith(
//               fontSize: 40,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '${DateTimeHelper.getYear(movie.releaseDate)} • ${movie.genreNames?.join(', ') ?? ''}',
//             style: AppTextStyles.body.copyWith(color: Colors.grey),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             movie.description,
//             style: AppTextStyles.body.copyWith(fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MovieTalksTab extends StatelessWidget {
//   final String movieId;

//   const MovieTalksTab({super.key, required this.movieId});

//   @override
//   Widget build(BuildContext context) {
//     // Replace with your state management logic
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: 10,
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: const CircleAvatar(child: Icon(Icons.person)),
//           title: Text("User $index"),
//           subtitle: Text("This movie was 🔥🔥🔥"),
//         );
//       },
//     );
//   }
// }

// class MovieDiscussionsTab extends StatelessWidget {
//   final String movieId;

//   const MovieDiscussionsTab({super.key, required this.movieId});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             title: Text("Discussion Topic $index"),
//             subtitle: Text("Started by @user_${index + 1}"),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 14),
//             onTap: () {
//               // Navigate to discussion thread
//             },
//           ),
//         );
//       },
//     );
//   }
// }



class MovieDetailScreen extends StatelessWidget {
  //  final Movie? movie;
  const MovieDetailScreen({super.key, });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => [
          SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    background: CachedNetworkImage(
                            imageUrl: "https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg",
                            fit: BoxFit.cover,
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
                    title: Text("Everything Everywhere All At Once", style: AppTextStyles.heading1.copyWith(color: Colors.white, /*fontSize: 36,*/ overflow: TextOverflow.ellipsis, height: 1.2))
                  ),
          ),
        ],
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // PosterAndTitle(),
              SizedBox(height: 16),
              RatingRow(),
              SizedBox(height: 16),
              DescriptionText(),
              SizedBox(height: 12),
              TagSection(),
              SizedBox(height: 28),
              CastAndCrewSection(),
              SizedBox(height: 28),
              DiscussionSection(),
              SizedBox(height: 32),
                
   
                
            ],
          ),
        ),

      ),
    );
  }
}

class PosterAndTitle extends StatelessWidget {
  const PosterAndTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image.network(
        //   'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
        //   height: 420,
        //   fit: BoxFit.cover,
        //   width: double.infinity,
        // ),
        // Positioned(
        //   top: 60,
        //   left: 16,
        //   child: GestureDetector(
        //     onTap: () => Navigator.pop(context),
        //     child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        //   ),
        // ),
        Text(
          'Everything everywhere all at once',
          style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 36, height: 1),
        ),
      ],
    );
  }
}

class RatingRow extends StatelessWidget {
  const RatingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          RatingPill(icon: Icons.star, label: "Cluvie", score: "4.8"),
          SizedBox(width: 8),
          RatingPill(icon: Icons.movie, label: "TMDB", score: "7.4"),
          SizedBox(width: 8),
          RatingPill(icon: Icons.person, label: "My", score: "5.0"),
        ],
      ),
    );
  }
}

class RatingPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String score;
  const RatingPill({required this.icon, required this.label, required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 4),
          Text('$label $score', style: AppTextStyles.caption.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class DescriptionText extends StatelessWidget {
  const DescriptionText({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'A Chinese immigrant gets unwillingly embroiled in an epic adventure where she must connect different versions of herself in the parallel universe to stop someone who intends to harm the multiverse.',
        style: AppTextStyles.body.copyWith(color: AppColors.darkTextSecondary),
      ),
    );
  }
}

class TagSection extends StatelessWidget {
  const TagSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: const [
          TagChip(label: "#commedy"),
          TagChip(label: "#LGBTQ+"),
          TagChip(label: "#indieFilm"),
          TagChip(label: "#ScienceFiction"),

        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  const TagChip({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: AppColors.cinematicPurple,
      label: Text(label),
      elevation: 16,
      // labelStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

class CastAndCrewSection extends StatelessWidget {
  const CastAndCrewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Cast & Crew", style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            children: const [
              CastCard(name: "Mahershala Ali", image: 'assets/cast1.jpg'),
              CastCard(name: "Naomie Harris", image: 'assets/cast2.jpg'),
              CastCard(name: "Alex R. Hibbert", image: 'assets/cast3.jpg'),
              CastCard(name: "Barry Jenkins", image: 'assets/cast4.jpg'),
            ],
          ),
        ),
      ],
    );
  }
}

class CastCard extends StatelessWidget {
  final String name;
  final String image;
  const CastCard({required this.name, required this.image, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(image),
            radius: 28,
          ),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class DiscussionSection extends StatelessWidget {
  const DiscussionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Discussion", style: AppTextStyles.heading2.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/user1.jpg'),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Favorite scene?", style: AppTextStyles.body.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        "The ocean swim with Kevin, Watching Chiron finally let his guard down was so.",
                        style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
