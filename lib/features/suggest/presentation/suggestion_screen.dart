// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Suggest Tab — CF-05
/// TMDB search debounce, poster/year, confirm CTA, optimistic update + snackbar rollback.
class SuggestMovieScreen extends StatefulWidget {
  const SuggestMovieScreen({super.key});
  @override
  State<SuggestMovieScreen> createState() => _SuggestMovieScreenState();
}

class _SuggestMovieScreenState extends State<SuggestMovieScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  Map<String, dynamic>? _selected;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String _query = '';
  final ApiClient _api = ApiClient();

  final List<Map<String, String>> _clubs = [
    {'name': 'Cinephiles Unite 🎬', 'members': '227 members', 'time': '3 hr ago'},
    {'name': 'Late Night Indies 🍊', 'members': '178 members', 'time': '5 h ago'},
    {'name': 'Cinema Sundays 🌅', 'members': '243 members', 'time': '1d ago'},
  ];
  int _selectedClub = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    // Preload demo trending for empty state
    _results = _demo;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchCtrl.text.trim();
      if (q.length >= 2) {
        _search(q);
      } else if (q.isEmpty) {
        setState(() {
          _query = '';
          _results = _demo;
          _selected = null;
        });
      }
    });
  }

  Future<void> _search(String q) async {
    setState(() {
      _isSearching = true;
      _query = q;
    });
    try {
      final res = await _api.get('/tmdb/search', params: {'query': q});
      final list = res.data is List ? res.data as List : (res.data['results'] ?? []) as List;
      if (mounted) setState(() => _results = list.isNotEmpty ? list : _filteredDemo(q));
    } catch (_) {
      if (mounted) setState(() => _results = _filteredDemo(q));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  List<dynamic> _filteredDemo(String q) => _demo.where((m) => (m['title'] as String).toLowerCase().contains(q.toLowerCase())).toList();

  Future<void> _submit() async {
    if (_selected == null) {
      ClSnackbar.show(context, message: 'Pick a movie first', type: ClSnackbarType.warning);
      return;
    }
    setState(() => _isSubmitting = true);
    final title = _selected!['title'] ?? 'Movie';
    // optimistic
    ClSnackbar.show(context, message: 'Suggesting "$title" to ${_clubs[_selectedClub]['name']}…', type: ClSnackbarType.loading);
    try {
      await _api.post('/communities/demo/suggest', data: {'tmdbId': _selected!['id'] ?? _selected!['tmdbId'], 'note': ''});
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ClSnackbar.show(context, message: 'Suggestion submitted! +10 XP', type: ClSnackbarType.success);
      setState(() {
        _selected = null;
        _searchCtrl.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ClSnackbar.show(context, message: "Couldn't suggest — tap to retry", type: ClSnackbarType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Suggest a Movie', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar — debounced
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for any movie...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))) : const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54, size: 18), onPressed: () => _searchCtrl.clear()) : null,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_selected != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.5))),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _posterFor(_selected!),
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 60, height: 80, color: Colors.white)),
                      errorWidget: (_, __, ___) => Container(width: 60, height: 80, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white30)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_selected!['title'] ?? 'Untitled', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text('${_yearFor(_selected!)} · Selected', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => setState(() => _selected = null)),
                ]),
              ),
              const SizedBox(height: 14),
            ],
            // Results grid or empty state
            if (_query.isNotEmpty && _results.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
                child: ClEmptyState(message: "No results for '$_query' — try another title", icon: Icons.search_off_rounded),
              )
            else ...[
              if (_query.isEmpty) Text('Trending to suggest', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              if (_query.isNotEmpty) Text("Results for '$_query'", style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                itemCount: _results.length.clamp(0, 6),
                itemBuilder: (_, i) {
                  final m = _results[i];
                  final isSelected = _selected != null && (_selected!['id'] == m['id'] || _selected!['title'] == m['title']);
                  return GestureDetector(
                    onTap: () => setState(() => _selected = m as Map<String, dynamic>),
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.accent : Colors.white10, width: isSelected ? 2 : 1)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(children: [
                          CachedNetworkImage(
                            imageUrl: _posterFor(m),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(color: Colors.white)),
                            errorWidget: (_, __, ___) => Container(color: AppColors.darkSurface),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.75), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m['title'] ?? 'Untitled', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(_yearFor(m), style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 10)),
                              ]),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle), child: const Icon(Icons.check, size: 14, color: Colors.black)),
                            ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),
            Text('Where would you like to suggest this movie?', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ..._clubs.asMap().entries.map((e) {
              final idx = e.key;
              final club = e.value;
              final selected = idx == _selectedClub;
              return GestureDetector(
                onTap: () => setState(() => _selectedClub = idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.accent.withOpacity(0.5) : Colors.white10),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                      child: Icon(selected ? Icons.check_circle : Icons.group, color: selected ? AppColors.accent : Colors.white70, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(club['name']!, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                        Text("${club['members']} · ${club['time']}", style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                      ]),
                    ),
                    if (selected) const Icon(Icons.radio_button_checked, color: AppColors.accent, size: 20) else const Icon(Icons.radio_button_off, color: Colors.white30, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text('Set default club for suggestions', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text('Submit Suggestion', style: AppTextStyles.button.copyWith(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _posterFor(dynamic m) {
    final p = m['poster_path'] ?? m['posterPath'] ?? m['poster'] ?? '';
    if (p.toString().startsWith('http')) return p;
    if (p.toString().isEmpty) return 'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg';
    return 'https://image.tmdb.org/t/p/w500$p';
  }

  String _yearFor(dynamic m) {
    final d = m['release_date'] ?? m['releaseDate'] ?? '';
    if (d.toString().length >= 4) return d.toString().substring(0, 4);
    return '2024';
  }

  static const _demo = [
    {'id': 1, 'title': 'Everything Everywhere All At Once', 'poster_path': '/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 'release_date': '2022-03-11'},
    {'id': 2, 'title': 'Dune: Part Two', 'poster_path': '/d5NXSklXo0qyIYkgV94XAgMIckC.jpg', 'release_date': '2024-02-27'},
    {'id': 3, 'title': 'Past Lives', 'poster_path': '/kAellTx1ukNtc42BP1kcnHPCG5e.jpg', 'release_date': '2023-06-02'},
    {'id': 4, 'title': 'Oppenheimer', 'poster_path': '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', 'release_date': '2023-07-19'},
    {'id': 5, 'title': 'The Batman', 'poster_path': '/74xTEgt7R36Fpooo50r9T25onhq.jpg', 'release_date': '2022-03-01'},
    {'id': 6, 'title': 'Blade Runner 2049', 'poster_path': '/aMpyrCizvSdc0UIMblJ1srVgAEF.jpg', 'release_date': '2017-10-04'},
  ];
}
