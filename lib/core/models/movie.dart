class Movie {
  final String id;
  final int tmdbId;
  final String title;
  final String description;
  final String poster;
  final String backdrop; // Not used in the current implementation
  final String releaseDate;
  final List<int> genreIds;
   List<String>? genreNames; 
  final double rating;
  final String suggestedBy;

  Movie({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.description,
    required this.poster,
    required this.backdrop, // Optional, not used in the current implementation
    required this.releaseDate,
    required this.genreIds,
    this.genreNames,
    required this.rating,
    required this.suggestedBy,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['_id'] ?? '', // from MongoDB
      tmdbId: json['id'] ?? 0, // from tmdB
      title: json['title'] ?? 'Unknown Title',
      description: json['overview'] ?? 'No description available',
      poster:
          json['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
              : 'https://image.tmdb.org/t/p/w500/r46leE6PSzLR3pnVzaxx5Q30yUF.jpg', // Fallback for poster
      backdrop:
          json['backdrop_path'] != null
              ? 'https://image.tmdb.org/t/p/original${json['backdrop_path']}'
              : 'https://image.tmdb.org/t/p/w500/44YfHklKam8COMUxDZop2Lnp0CS.jpg',
      releaseDate: json['release_date'] ?? '2025-04-24',
      genreIds:
          json['genre_ids'] != null
              ? List<int>.from(json['genre_ids'])
              : [], // Ensure genre IDs are parsed as integers
      rating:
          (json['popularity'] as num?)?.toDouble() ?? 0.0, // Rating fallback
      suggestedBy:
          json['suggestedBy'] ?? 'John Doe', // From MongoDB or your source
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': tmdbId,
      'title': title,
      'overview': description,
      'poster_path': poster,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'popularity': rating,
      'suggestedBy': suggestedBy,
    };
  }

  // factory Movie.placeholder() {
  //   return Movie(
  //     id: 'placeholder_id',
  //     tmdbId: 0,
  //     title: 'batman',
  //     description: 'Loading description for the movie. Please wait...',
  //     poster: 'https://image.tmdb.org/t/p/w500/w500/r46leE6PSzLR3pnVzaxx5Q30yUF.jpg',
  //     releaseDate: '2025-01-01',
  //     genres: [28, 29],
  //     rating: 0.0,
  //     suggestedBy: 'placeholder_user',
  //   );
  // }
}


// REFRENCE

  // {
  //     "adult": false,
  //     "backdrop_path": "/44YfHklKam8COMUxDZop2Lnp0CS.jpg",
  //     "genre_ids": [
  //       28,
  //       80,
  //       53
  //     ],
  //     "id": 668489,
  //     "original_language": "en",
  //     "original_title": "Havoc",
  //     "overview": "When a drug heist swerves lethally out of control, a jaded cop fights his way through a corrupt city's criminal underworld to save a politician's son.",
  //     "popularity": 584.7785,
  //     "poster_path": "/r46leE6PSzLR3pnVzaxx5Q30yUF.jpg",
  //     "release_date": "2025-04-24",
  //     "title": "Havoc",
  //     "video": false,
  //     "vote_average": 6.604,
  //     "vote_count": 331
  //   },