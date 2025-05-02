import 'package:dio/dio.dart';


class MovieRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      headers: {
        'accept': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxZWQ0MTkzZWFlYzNmMWE5YjdjNzRjZTk4NGUyMGI2NiIsIm5iZiI6MS43NDEzMTA5MzY3MTI5OTk4ZSs5LCJzdWIiOiI2N2NhNGJkODc0NzlkOGM4NDkyYjNiYjIiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.9nldDyT56nlJrj6oKCkz7leRsgQP7bd_pOqTXXeJrV4',
    },
  ),
);
}