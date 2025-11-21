import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/utils/build_config.dart';

class CommunityRepository {
  // final Dio _dio;
   final ApiClient _apiClient;

    CommunityRepository({required ApiClient apiClient}) : _apiClient = apiClient;

 


  // Fetch all communities
  Future<List<Community>> fetchJoinedCommunities() async {
    try {
      final response = await _apiClient.get('/communities/joined');
      final data = response.data;
      final communityList = data['communities'] as List;
      final communities = communityList.map((json) => Community.fromJson(json)).toList();
      return communities;
    } catch (e) {
      log('Error fetching communities: $e');
      rethrow;
    }
  }

  Future<List<Community>> fetchAllCommunities() async {
    try {
      final response = await _apiClient.get('/communities/all');
      final data = response.data;
      final communityList = data['communities'] as List;
      final communities = communityList.map((json) => Community.fromJson(json)).toList();
      return communities;
    } catch (e) {
      log('Error fetching communities: $e');
      rethrow;
    }
  }


  // Fetch a single community by ID
  Future<Community> fetchCommunityById(String id) async {
    try {
      final response = await _apiClient.get('/communities/$id');
      return Community.fromJson(response.data);
    } catch (e) {
      log('Error fetching community: $e');
      rethrow;
    }
  }

  // Create a new community
  Future<Community> createCommunity(String name, String description) async {
    try {
      final response = await _apiClient.post(
        '/communities',
        data: {
          'name': name,
          'description': description,
        }
      );
      final data = response.data;
      final community= data['community'];
      log('✅ Success: ${response.data}');
      return Community.fromJson(community);
      
    } catch (e) {
      log('Error creating community: $e');
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
      log('Error updating a community: $e');
      rethrow;
    }
  }

  // Delete a community
  Future<void> deleteCommunity(String id) async {
    try {
      await _apiClient.delete('/communities/$id');
    } catch (e) {
      log('Error deleting a community: $e');
      rethrow;
    }
  }
}
