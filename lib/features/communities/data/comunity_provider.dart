import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/repository/comunity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client_provider.dart';

final joinedCommunitiesProvider =
    AsyncNotifierProvider<JoinedCommunityNotifier, List<Community>>(() {
  return JoinedCommunityNotifier();
});

// Fetch all communities (  explore or global)
final allCommunitiesProvider =
    AsyncNotifierProvider<AllCommunitiesNotifier, List<Community>>(() => AllCommunitiesNotifier());


class AllCommunitiesNotifier extends AsyncNotifier<List<Community>> {
  late final CommunityRepository _repository;

  @override
  Future<List<Community>> build() async {
    final apiClient = ref.read(apiClientProvider);
    _repository = CommunityRepository(apiClient: apiClient);
    return await _repository.fetchAllCommunities();
  }
}

class JoinedCommunityNotifier extends AsyncNotifier<List<Community>> {
  late final CommunityRepository _repo;

  @override
  Future<List<Community>> build() async {
    final apiClient = ref.read(apiClientProvider);
    _repo = CommunityRepository(apiClient: apiClient);

    return _repo.fetchJoinedCommunities(); // initial load
  }

  /// 🔁 Refresh the list
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchJoinedCommunities());
  }

  Future<void> fetchAllCommunities() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchAllCommunities());
  }
  
  Future<void> createCommunity(String name, String description) async {
    final newCommunity = await _repo.createCommunity(name, description);
    final current = state.value ?? [];
    state = AsyncData([...current, newCommunity]);
  }

 
  Future<void> updateCommunity(String id, Community community) async {
    final updated = await _repo.updateCommunity(id, community);
    final current = state.value ?? [];
    final updatedList = current.map((c) => c.id == id ? updated : c).toList();
    state = AsyncData(updatedList);
  }


  Future<void> deleteCommunity(String id) async {
    await _repo.deleteCommunity(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  
  Future<Community> fetchCommunityById(String id) async {
    return await _repo.fetchCommunityById(id);
  }
}
