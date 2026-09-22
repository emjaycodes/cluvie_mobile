import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Debounced search widget for testing — mirrors DiscoverScreen debounce 300ms
class DebouncedSearchField extends StatefulWidget {
  final void Function(String) onSearch;
  final Duration debounce;
  const DebouncedSearchField({super.key, required this.onSearch, this.debounce = const Duration(milliseconds: 300)});

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  final _ctrl = TextEditingController();
  Timer? _timer;

  void _onChanged(String v) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onSearch(v.trim()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('search-field'),
      controller: _ctrl,
      onChanged: _onChanged,
      decoration: const InputDecoration(hintText: 'Search movies, clubs...'),
    );
  }
}

class SearchResultsWidget extends StatelessWidget {
  final String query;
  final List<Map<String, String>> results;
  const SearchResultsWidget({super.key, required this.query, required this.results});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();
    if (results.isEmpty) {
      return Text("No results for '$query' — try another title", key: const Key('empty-search'));
    }
    return Column(
      key: const Key('results'),
      children: results.map((r) => Text(r['title']!)).toList(),
    );
  }
}

class RetryCard extends StatelessWidget {
  final VoidCallback onRetry;
  const RetryCard({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('retry-card'),
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.all(14),
        child: const Row(children: [
          Icon(Icons.error_outline),
          Expanded(child: Text("Couldn't load Discover — tap to retry")),
          Icon(Icons.refresh),
        ]),
      ),
    );
  }
}

void main() {
  group('Discover search', () {
    testWidgets('debounced search 300ms', (tester) async {
      String? searched;
      int callCount = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: DebouncedSearchField(onSearch: (q) {
        searched = q;
        callCount++;
      }))));

      await tester.enterText(find.byKey(const Key('search-field')), 'a');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('search-field')), 'ab');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('search-field')), 'abc');
      // Before 300ms, should not have fired
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(callCount, 1);
      expect(searched, 'abc');
    });

    testWidgets('debounced search fires only once for rapid typing', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DebouncedSearchField(onSearch: (_) => callCount++))));
      for (var i = 0; i < 5; i++) {
        await tester.enterText(find.byKey(const Key('search-field')), 'test $i');
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(callCount, 1);
    });

    testWidgets('empty state No results for', (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: SearchResultsWidget(query: 'xyz123', results: []))));
      expect(find.text("No results for 'xyz123' — try another title"), findsOneWidget);
      expect(find.byKey(const Key('empty-search')), findsOneWidget);
    });

    testWidgets('search results rendered when not empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: SearchResultsWidget(query: 'dune', results: [
        {'title': 'Dune: Part Two'},
        {'title': 'Dune'},
      ]))));
      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);
      expect(find.textContaining("No results for"), findsNothing);
    });

    testWidgets('retry card tap to retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RetryCard(onRetry: () => retried = true))));
      expect(find.text("Couldn't load Discover — tap to retry"), findsOneWidget);
      expect(find.byKey(const Key('retry-card')), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry-card')));
      expect(retried, isTrue);
    });

    testWidgets('no empty state when query empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchResultsWidget(query: '', results: []))));
      expect(find.textContaining("No results for"), findsNothing);
    });
  });
}
