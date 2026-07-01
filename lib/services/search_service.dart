import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/search_result.dart';

class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<SearchResultItem>> search(String query) async {
    try {
      final resp = await _dio.get('/search/universal', queryParameters: {'q': query});
      final results = (resp.data as Map<String, dynamic>)['results'] as List;
      return results.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
