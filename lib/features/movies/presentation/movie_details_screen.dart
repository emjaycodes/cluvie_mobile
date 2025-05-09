import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/models/movie.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/utils/date_time_helper.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    print('MovieDetailScreen: ${movie.genreNames?[0]}');
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder:
              (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: CachedNetworkImage(
                            imageUrl: movie.backdrop,
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
                    // title: Text(movie.title),
                  ),
                ),
              ],
          body: Column(
            children: [
              _MovieInfo(movie: movie),
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        // color: Colors.grey[900], // Background of the TabBar
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color:
                              AppColors
                                  .primary, // Change to your desired selected tab color
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Optional: Rounded corners
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [Tab(text: 'Talks'), Tab(text: 'Discussions')],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    MovieTalksTab(movieId: movie.id),
                    MovieDiscussionsTab(movieId: movie.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieInfo extends StatelessWidget {
  final Movie movie;

  const _MovieInfo({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateTimeHelper.getYear(movie.releaseDate)} • ${movie.genreNames?.join(', ') ?? ''}',
            style: AppTextStyles.body.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            movie.description,
            style: AppTextStyles.body.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class MovieTalksTab extends StatelessWidget {
  final String movieId;

  const MovieTalksTab({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    // Replace with your state management logic
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text("User $index"),
          subtitle: Text("This movie was 🔥🔥🔥"),
        );
      },
    );
  }
}

class MovieDiscussionsTab extends StatelessWidget {
  final String movieId;

  const MovieDiscussionsTab({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text("Discussion Topic $index"),
            subtitle: Text("Started by @user_${index + 1}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              // Navigate to discussion thread
            },
          ),
        );
      },
    );
  }
}
