import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pure voting widgets for isolated testing — mirrors VoteSummaryScreen logic
// without requiring ApiClient/GoRouter/CachedNetworkImage.

/// Sorts suggestions by votes desc, tie = earliest createdAt
List<Map<String, dynamic>> sortSuggestions(List<Map<String, dynamic>> list) {
  final copy = List<Map<String, dynamic>>.from(list);
  copy.sort((a, b) {
    final va = a['votes'] as int;
    final vb = b['votes'] as int;
    if (vb != va) return vb.compareTo(va);
    return (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime);
  });
  return copy;
}

class VotingCard extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final VoidCallback? onVote;
  const VotingCard({super.key, required this.suggestions, this.onVote});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const Text('No active polls — suggest a film!');
    }
    final sorted = sortSuggestions(suggestions);
    final winnerId = sorted.first['id'];
    return Column(
      key: const Key('voting-list'),
      children: sorted.asMap().entries.map((e) {
        final idx = e.key;
        final s = e.value;
        final isWinner = s['id'] == winnerId;
        return Container(
          key: Key('suggestion-${s['id']}'),
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Text('${idx + 1}', key: Key('rank-${s['id']}')),
            const SizedBox(width: 8),
            Expanded(child: Text(s['title'] as String)),
            Text('${s['votes']} votes'),
            if (isWinner) const Text('WINNER'),
            TextButton(onPressed: onVote, child: const Text('Vote')),
          ]),
        );
      }).toList(),
    );
  }
}

void main() {
  group('VotingCard', () {
    testWidgets('displays ranked suggestions with vote counts', (tester) async {
      final data = [
        {'id': '1', 'title': 'Past Lives', 'votes': 9, 'createdAt': DateTime(2024, 1, 1)},
        {'id': '2', 'title': 'Oppenheimer', 'votes': 7, 'createdAt': DateTime(2024, 1, 2)},
        {'id': '3', 'title': 'Poor Things', 'votes': 2, 'createdAt': DateTime(2024, 1, 3)},
      ];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VotingCard(suggestions: data))));
      expect(find.text('Past Lives'), findsOneWidget);
      expect(find.text('Oppenheimer'), findsOneWidget);
      expect(find.text('Poor Things'), findsOneWidget);
      expect(find.text('9 votes'), findsOneWidget);
      expect(find.text('7 votes'), findsOneWidget);
      expect(find.text('2 votes'), findsOneWidget);
    });

    testWidgets('shows WINNER badge on highest voted', (tester) async {
      final data = [
        {'id': '1', 'title': 'Past Lives', 'votes': 9, 'createdAt': DateTime(2024, 1, 1)},
        {'id': '2', 'title': 'Oppenheimer', 'votes': 7, 'createdAt': DateTime(2024, 1, 2)},
      ];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VotingCard(suggestions: data))));
      expect(find.text('WINNER'), findsOneWidget);
      // Winner should be Past Lives (highest votes)
      final winnerRow = find.byKey(const Key('suggestion-1'));
      expect(find.descendant(of: winnerRow, matching: find.text('WINNER')), findsOneWidget);
    });

    testWidgets('tie-breaker earliest wins', (tester) async {
      final data = [
        {'id': '2', 'title': 'Oppenheimer', 'votes': 7, 'createdAt': DateTime(2024, 1, 2, 10)},
        {'id': '3', 'title': 'Zone of Interest', 'votes': 7, 'createdAt': DateTime(2024, 1, 2, 12)},
        {'id': '1', 'title': 'Past Lives', 'votes': 9, 'createdAt': DateTime(2024, 1, 1)},
      ];
      // After sort, Past Lives first, then Oppenheimer (earlier tie), then Zone
      final sorted = sortSuggestions(data);
      expect(sorted[0]['id'], '1');
      expect(sorted[1]['id'], '2'); // earlier tie wins
      expect(sorted[2]['id'], '3');

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VotingCard(suggestions: data))));
      // WINNER should be on Past Lives still
      expect(find.text('WINNER'), findsOneWidget);
      // Now test tie for winner scenario
      final tieData = [
        {'id': 'a', 'title': 'Film A', 'votes': 5, 'createdAt': DateTime(2024, 1, 1, 8)},
        {'id': 'b', 'title': 'Film B', 'votes': 5, 'createdAt': DateTime(2024, 1, 1, 10)},
      ];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VotingCard(suggestions: tieData))));
      await tester.pump();
      expect(find.byKey(const Key('suggestion-a')), findsOneWidget);
      final winnerA = find.byKey(const Key('suggestion-a'));
      expect(find.descendant(of: winnerA, matching: find.text('WINNER')), findsOneWidget);
      final notWinner = find.byKey(const Key('suggestion-b'));
      expect(find.descendant(of: notWinner, matching: find.text('WINNER')), findsNothing);
    });

    testWidgets('empty state message', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: VotingCard(suggestions: []))));
      expect(find.text('No active polls — suggest a film!'), findsOneWidget);
    });

    testWidgets('rank order 1,2,3 displayed', (tester) async {
      final data = [
        {'id': '1', 'title': 'A', 'votes': 3, 'createdAt': DateTime(2024, 1, 1)},
        {'id': '2', 'title': 'B', 'votes': 2, 'createdAt': DateTime(2024, 1, 2)},
        {'id': '3', 'title': 'C', 'votes': 1, 'createdAt': DateTime(2024, 1, 3)},
      ];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VotingCard(suggestions: data))));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('vote button exists', (tester) async {
      var tapped = false;
      final data = [
        {'id': '1', 'title': 'Past Lives', 'votes': 9, 'createdAt': DateTime(2024, 1, 1)},
      ];
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: VotingCard(suggestions: data, onVote: () => tapped = true))));
      expect(find.text('Vote'), findsOneWidget);
      await tester.tap(find.text('Vote'));
      expect(tapped, isTrue);
    });
  });
}
