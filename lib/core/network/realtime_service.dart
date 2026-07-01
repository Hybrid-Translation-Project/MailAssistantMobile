import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/secure_storage_service.dart';

/// Backend'in /api/v1/ws endpoint'ine bağlanıp "new_mail",
/// "whatsapp_message_received" gibi olayları yayınlar. Ekranlar bu stream'i
/// dinleyip sadece kendini ilgilendiren olay tipinde listeyi yeniler —
/// tam bir realtime senkron değil, ama pull-to-refresh'e göre çok daha canlı.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  bool _manuallyDisconnected = false;

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect() async {
    _manuallyDisconnected = false;
    await _connectOnce();
  }

  Future<void> _connectOnce() async {
    final serverUrl = await SecureStorageService.instance.getServerUrl();
    final token = await SecureStorageService.instance.getAccessToken();
    if (serverUrl == null || token == null) return;

    try {
      final wsScheme = serverUrl.startsWith('https') ? 'wss' : 'ws';
      final host = serverUrl.replaceFirst(RegExp(r'^https?'), '');
      final uri = Uri.parse('$wsScheme$host/api/v1/ws?token=$token');

      _channel?.sink.close();
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (raw) {
          try {
            final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
            if (decoded['type'] == 'ping') {
              _channel?.sink.add(jsonEncode({'type': 'pong'}));
              return;
            }
            _controller.add(decoded);
          } catch (_) {
            // Bozuk mesaj, yut.
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manuallyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connectOnce);
  }

  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
