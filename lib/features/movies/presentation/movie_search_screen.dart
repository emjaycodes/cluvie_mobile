import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  _MovieSearchScreenState createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List _movies = [];
  bool _isLoading = false;

  Future<void> _searchMovies(String query) async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = "1ed4193eaec3f1a9b7c74ce984e20b66";
    final url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _movies = data['results'];
        });
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TMDB Movie Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search Movies',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                if (query.isNotEmpty) {
                  _searchMovies(query);
                } else {
                  setState(() {
                    _movies = [];
                  });
                }
              },
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        final movie = _movies[index];
                        return ListTile(
                          title: Text(movie['title']),
                          subtitle: Text(movie['release_date'] ?? 'N/A'),
                          leading: movie['poster_path'] != null
                              ? Image.network(
                                  'https://image.tmdb.org/t/p/w92${movie['poster_path']}')
                              : Container(),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
