// Proxy via backend GET /api/tmdb — never expose TMDB key to client.
// See PRD-080/081 + OPERATIONS.md §4. Use ApiClient (env-configured baseUrl).
import 'package:cluvie_mobile/core/api/api_client.dart';

class TmdbApi {
  final ApiClient _api;
  TmdbApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<dynamic>> trending({String window = 'week'}) async {
    final res = await _api.get('/tmdb/trending', params: {'window': window});
    final data = res.data;
    if (data is List) return data;
    return (data['results'] ?? data['trending'] ?? []) as List;
  }

  Future<List<dynamic>> popular() async {
    final res = await _api.get('/tmdb/popular');
    final data = res.data;
    if (data is List) return data;
    return (data['results'] ?? []) as List;
  }

  Future<List<dynamic>> search(String query) async {
    final res = await _api.get('/tmdb/search', params: {'query': query});
    final data = res.data;
    if (data is List) return data;
    return (data['results'] ?? []) as List;
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final res = await _api.get('/tmdb/movie/$id');
    return res.data as Map<String, dynamic>;
  }
}

// Deprecated direct TMDB repo — kept for reference but now delegates to proxy.
class MovieRepositoryProxy {
  final TmdbApi _tmdb = TmdbApi();
  Future<List<dynamic>> fetchTrendingMovies({String timeWindow = 'week'}) => _tmdb.trending(window: timeWindow);
}
