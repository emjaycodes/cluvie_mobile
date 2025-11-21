class Movie {
  final String? id;
  final int? tmdbId;
  final String? title;
  final String? description;
  final String? poster;
  final String? backdrop;
  final String? releaseDate;
  final List<int?> genreIds;
  List<String>? genreNames;
  final double rating;
  // final String? addedBy;
  final int? commentCount;
  final int? discussionCount;
  final int? engagementScore;
  final DateTime createdAt;
  final int? votes;
  final List<String?> voters;

  Movie({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.description,
    required this.poster,
    required this.backdrop,
    required this.releaseDate,
    required this.genreIds,
    this.genreNames,
    required this.rating,
    // required this.addedBy,
    required this.commentCount,
    required this.discussionCount,
    required this.engagementScore,
    required this.createdAt,
    required this.votes,
    required this.voters,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['_id'] ?? '',
      tmdbId: json['tmdbId'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      description: json['overview'] ?? 'No description available',
      poster: (json['posterPath'] != null && json['posterPath'].toString().isNotEmpty)
          ? 'https://image.tmdb.org/t/p/w500${json['posterPath']}'
          : 'https://image.tmdb.org/t/p/w500/r46leE6PSzLR3pnVzaxx5Q30yUF.jpg',
      backdrop: (json['backdropPath'] != null && json['backdropPath'].toString().isNotEmpty)
          ? 'https://image.tmdb.org/t/p/original${json['backdropPath']}'
          : 'https://image.tmdb.org/t/p/w500/44YfHklKam8COMUxDZop2Lnp0CS.jpg',
      releaseDate: json['releaseDate'] ?? 'Unknown Date',
     genreIds:
          json['genre_ids'] != null
              ? List<int?>.from(json['genre_ids'])
              : [], 
      // genreNames: (json['genres'] as List?)?.map((e) => e.toString()).toList(),
      rating: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      // addedBy: json['addedBy'] ?? 'Unknown',
      commentCount: json['commentCount'] ?? 0,
      discussionCount: json['discussionCount'] ?? 0,
      engagementScore: json['engagementScore'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      votes: json['votes'] ?? 0,
      voters: (json['voters'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  } 
  

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tmdbId': tmdbId,
      'title': title,
      'overview': description,
      'posterPath': poster?.replaceAll('https://image.tmdb.org/t/p/w500', ''),
      'backdropPath': backdrop?.replaceAll('https://image.tmdb.org/t/p/original', ''),
      'releaseDate': releaseDate,
      'genre_ids': genreIds,
      'genres': genreNames,
      'popularity': rating,
      // 'addedBy': addedBy,
      'commentCount': commentCount,
      'discussionCount': discussionCount,
      'engagementScore': engagementScore,
      'createdAt': createdAt.toIso8601String(),
      'votes': votes,
      'voters': voters,
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
  //     addedBy: 'placeholder_user',
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