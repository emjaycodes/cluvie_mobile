import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:dio/dio.dart';

class CommunityRepository {
  // final Dio _dio;
   final ApiClient _apiClient;

    CommunityRepository({required ApiClient apiClient}) : _apiClient = apiClient;

 


  // Fetch all communities
  Future<List<Community>> fetchCommunities() async {
    try {
      final response = await _apiClient.get('/communities/joined');
      final data = response.data as List;
      return data.map((json) => Community.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching communities: $e');
      rethrow;
    }
  }



  // Fetch a single community by ID
  Future<Community> fetchCommunityById(String id) async {
    try {
      final response = await _apiClient.get('/communities/$id');
      return Community.fromJson(response.data);
    } catch (e) {
      print('Error fetching community: $e');
      rethrow;
    }
  }

  // Create a new community
  Future<Community> createCommunity(Community community) async {
    try {
      final response = await _apiClient.post(
        '/communities',
        data: community.toJson(),
      );
      return Community.fromJson(response.data);
    } catch (e) {
      print('Error creating community: $e');
      rethrow;
    }
  }

  // Update a community
  Future<Community> updateCommunity(String id, Community community) async {
    try {
      final response = await _apiClient.put(
        '/communities/$id',
        data: community.toJson(),
      );
      return Community.fromJson(response.data);
    } catch (e) {
      print('Error updating a community: $e');
      rethrow;
    }
  }

  // Delete a community
  Future<void> deleteCommunity(String id) async {
    try {
      await _apiClient.delete('/communities/$id');
    } catch (e) {
      print('Error deleting a community: $e');
      rethrow;
    }
  }
}
