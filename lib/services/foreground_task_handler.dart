import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:vibration/vibration.dart';
import 'database_service.dart';
import '../models/sensor_log.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(FallSafeTaskHandler());
}

class FallSafeTaskHandler extends TaskHandler {
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  String _lastStatus = 'NORMAL';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _connectWebSocket();
  }

  void _connectWebSocket() {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1:81'));

      _channel!.stream.listen(
        (message) async {
          try {
            final data = jsonDecode(message);
            final status = data['status'] as String;

            // Simpan ke database
            await DatabaseService.insertLog(SensorLog(
              status: status,
              timestamp: DateTime.now(),
            ));

            // 🟢 KUNCI PERBAIKAN: Panggil notif & alarm DARI SINI
            await _handleStatusChange(status);

            // Kirim ke UI (untuk update tampilan jika app terbuka)
            FlutterForegroundTask.sendDataToMain({
              'status': status,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          } catch (e) {
            print('❌ Parse error: $e');
          }
        },
        onDone: () {
          _isConnecting = false;
          _scheduleReconnect();
        },
        onError: (e) {
          _isConnecting = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // ⚡ Handle status change - update notifikasi service & getar
  Future<void> _handleStatusChange(String status) async {
    // Jangan spam kalau status sama
    if (status == _lastStatus) return;
    _lastStatus = status;

    if (status == 'JATUH') {
      // Update notifikasi foreground jadi JATUH
      await FlutterForegroundTask.updateService(
        notificationTitle: '🚨 JATUH TERDETEKSI!',
        notificationText: 'Segera cek kondisi pengguna!',
      );

      // Getar pola panjang
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500, 200, 1000],
          repeat: 0,
        );
      }

      print('🚨 JATUH - notif & getar dipicu dari background');
    } else if (status == 'CURIGA') {
      await FlutterForegroundTask.updateService(
        notificationTitle: '⚠️ Gerakan Curiga',
        notificationText: 'Ada gerakan tidak normal',
      );

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500, amplitude: 128);
      }

      print('⚠️ CURIGA - notif & getar dipicu dari background');
    } else {
      // NORMAL atau DUDUK - kembalikan ke notif normal
      await FlutterForegroundTask.updateService(
        notificationTitle: 'FallSafe Aktif',
        notificationText: 'Memantau sensor jatuh...',
      );
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      _connectWebSocket();
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _channel?.sink.close();
  }

  @override
  void onReceiveData(Object data) {}
}