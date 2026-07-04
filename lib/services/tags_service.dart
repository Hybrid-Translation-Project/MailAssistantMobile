import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class MailTag {
  final String id;
  final String name;
  final String color; // hex string, örn "#EF4444"
  final String description;
  final bool isSystem; // user_id null → sistem etiketi (silinemez)

  MailTag({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
    required this.isSystem,
  });

  factory MailTag.fromJson(Map<String, dynamic> json) => MailTag(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        color: (json['color'] ?? '#6366F1').toString(),
        description: (json['description'] ?? '').toString(),
        isSystem: json['user_id'] == null,
      );
}

class TagsService {
  TagsService._();
  static final TagsService instance = TagsService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<MailTag>> getTags() async {
    try {
      final resp = await _dio.get('/settings/tags');
      final list = resp.data as List;
      return list.map((e) => MailTag.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MailTag> addTag({required String name, required String color, String description = ''}) async {
    try {
      final resp = await _dio.post('/settings/tags', data: {
        'name': name,
        'color': color,
        'description': description,
      });
      return MailTag.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteTag(String tagId) async {
    try {
      await _dio.delete('/settings/tags/$tagId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
