import 'package:flutter/material.dart';

class WeeklyWatchlist extends StatefulWidget {
  final List<MovieCard> movies;

  const WeeklyWatchlist({super.key, required this.movies});

  @override
  State<WeeklyWatchlist> createState() => _WeeklyWatchlistState();
}

class _WeeklyWatchlistState extends State<WeeklyWatchlist> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "This Week's Watchlist",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              final isActive = index == _selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  // Optional: callback or navigation
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 160,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFFFFD27D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 6),
                          child: Text(
                            movie.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MovieCard {
  final String title;
  final String posterUrl;

  MovieCard({required this.title, required this.posterUrl});
}
