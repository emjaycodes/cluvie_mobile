
import 'dart:core';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final int xp;
  final String? fcmToken;
  final List<String?> suggestedMovies;
  final List<String?> votedMovies;
  final List<String?> comments;
  final List<String?> followers;
  final List<String?> following;
  final List<String?> watchlist;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.xp,
    this.fcmToken,
    required this.suggestedMovies,
    required this.votedMovies,
    required this.comments,
    required this.followers,
    required this.following,
    required this.watchlist,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      name: json['username'],
      email: json['email'],
      role: json['role'] ?? 'user',
      xp: json['xp'] ?? 0,
      fcmToken: json['fcmToken'],
      suggestedMovies: List<String>.from(json['suggestedMovies'] ?? []),
      votedMovies: List<String>.from(json['votedMovies'] ?? []),
      comments: List<String>.from(json['comments'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      watchlist: List<String>.from(json['watchlist'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': name,
        'email': email,
        'role': role,
        'xp': xp,
        'fcmToken': fcmToken,
        'suggestedMovies': suggestedMovies,
        'votedMovies': votedMovies,
        'comments': comments,
        'followers': followers,
        'following': following,
        'watchlist': watchlist,
        'createdAt': createdAt.toIso8601String()
      };
}
