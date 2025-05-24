import 'package:cluvie_mobile/core/models/community.dart';
import 'package:dio/dio.dart';

class CommunityRepository {
  final Dio _dio;

  CommunityRepository({Dio? dio}) : _dio = dio ?? Dio();

  // Fetch all communities
  Future<List<Community>> fetchCommunities() async {
    try {
      final response = await _dio.get('https://api.example.com/communities');
      final data = response.data as List;
      return data.map((json) => Community.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch a single community by ID
  Future<Community> fetchCommunityById(String id) async {
    try {
      final response = await _dio.get('https://api.example.com/communities/$id');
      return Community.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Create a new community
  Future<Community> createCommunity(Community community) async {
    try {
      final response = await _dio.post(
        'https://api.example.com/communities',
        data: community.toJson(),
      );
      return Community.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Update a community
  Future<Community> updateCommunity(String id, Community community) async {
    try {
      final response = await _dio.put(
        'https://api.example.com/communities/$id',
        data: community.toJson(),
      );
      return Community.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a community
  Future<void> deleteCommunity(String id) async {
    try {
      await _dio.delete('https://api.example.com/communities/$id');
    } catch (e) {
      rethrow;
    }
  }
}
