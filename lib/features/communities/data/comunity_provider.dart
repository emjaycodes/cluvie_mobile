import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/repository/comunity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/features/communities/states/community_state.dart';


final communityNotifierProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final repository = CommunityRepository(apiClient: apiClient);
  return CommunityNotifier(repository);
});


class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRepository repository;

  CommunityNotifier(this.repository) : super(CommunityState.loading()) {
    fetchCommunities();
  }

  Future<void> fetchCommunities() async {
    try {
      final communities = await repository.fetchCommunities();
      state = CommunityState.success(communities);
    } catch (e) {
      state = CommunityState.error(e.toString());
    }
  }

  Future<void> fetchCommunityById(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final community = await repository.fetchCommunityById(id);
      state = state.copyWith(selectedCommunity: community, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createCommunity(Community community) async {
    try {
      final newCommunity = await repository.createCommunity(community);
      state = state.copyWith(communities: [...state.communities, newCommunity]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateCommunity(String id, Community community) async {
    try {
      final updated = await repository.updateCommunity(id, community);
      final updatedList = state.communities.map((c) => c.id == id ? updated : c).toList();
      state = state.copyWith(communities: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCommunity(String id) async {
    try {
      await repository.deleteCommunity(id);
      final updatedList = state.communities.where((c) => c.id != id).toList();
      state = state.copyWith(communities: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
