import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class VoiceCommandAction {
  final String action;
  final String? target;
  final String? prompt;
  VoiceCommandAction({required this.action, this.target, this.prompt});

  factory VoiceCommandAction.fromJson(Map<String, dynamic> json) => VoiceCommandAction(
        action: json['action'] ?? 'none',
        target: json['target'],
        prompt: json['prompt'],
      );
}

class VoiceCommandResult {
  final String type;
  final String message;
  final List<VoiceCommandAction> actions;
  VoiceCommandResult({required this.type, required this.message, required this.actions});

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) => VoiceCommandResult(
        type: json['type'] ?? 'error',
        message: json['message'] ?? json['content'] ?? '',
        actions: (json['actions'] as List?)?.map((e) => VoiceCommandAction.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      );
}

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Ses kaydı yerine yazılı komut gönderir (gerçek konuşma-metin dönüşümü
  /// için mikrofon izni + kayıt eklentisi gerekir, bu bir sonraki adım).
  Future<VoiceCommandResult> sendTextCommand(String text) async {
    try {
      final resp = await _dio.post('/voice/command/text', data: {'text': text});
      return VoiceCommandResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
