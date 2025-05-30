import 'package:cluvie_mobile/core/models/community.dart';

class CommunityState {
  final List<Community> communities;
  final Community? selectedCommunity;
  final bool isLoading;
  final String? error;

  CommunityState({
    this.communities = const [],
    this.selectedCommunity,
    this.isLoading = false,
    this.error,
  });

  // Loading state
  CommunityState.loading()
      : communities = const [],
        selectedCommunity = null,
        isLoading = true,
        error = null;

  // Error state
  CommunityState.error(this.error)
      : communities = const [],
        selectedCommunity = null,
        isLoading = false;

  // Success (list)
  CommunityState.success(this.communities)
      : selectedCommunity = null,
        isLoading = false,
        error = null;

  // Success (single detail)
  CommunityState.detail(this.selectedCommunity)
      : communities = const [],
        isLoading = false,
        error = null;

  CommunityState copyWith({
    List<Community>? communities,
    Community? selectedCommunity,
    bool? isLoading,
    String? error,
  }) {
    return CommunityState(
      communities: communities ?? this.communities,
      selectedCommunity: selectedCommunity ?? this.selectedCommunity,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
