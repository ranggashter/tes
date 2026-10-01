import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/foreground_task_handler.dart';
import '../models/sensor_log.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'MENUNGGU...';
  String _connectionState = 'Terputus';
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();

    // 1. Cek apakah service sudah jalan
    _checkServiceRunning();

    // 2. Pasang callback terima data dari background
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    // 3. Muat data terakhir dari database (offline-first)
    _loadLatestFromDb();
  }

  Future<void> _checkServiceRunning() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      // Jalankan foreground service
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'FallSafe Aktif',
        notificationText: 'Memantau sensor jatuh...',
        callback: startCallback,
      );
    }
    if (mounted) {
      setState(() {
        _connectionState = 'Terhubung';
      });
    }
  }

  // Dipanggil saat background service mengirim data
void _onReceiveTaskData(Object data) {
  if (data is! Map) return;
  final map = Map<String, dynamic>.from(data);
  final status = map['status'] as String?;
  final timestamp = map['timestamp'] as int?;
  if (status == null || timestamp == null) return;
  if (!mounted) return;

  setState(() {
    _status = status;
    _lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    _connectionState = 'Terhubung';
  });

  // ⚡ Notif & getar sudah dipicu dari service (foreground_task_handler)
  // Di sini hanya tampilkan dialog JATUH kalau app sedang dibuka
  if (status == 'JATUH') {
    _showFallDialog();
  }
}
  Future<void> _loadLatestFromDb() async {
    final latest = await DatabaseService.getLatestLog();
    if (latest != null && mounted) {
      setState(() {
        _status = latest.status;
        _lastUpdate = latest.timestamp;
      });
    }
  }

  void _showFallDialog() {
    // Hindari double dialog
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade100,
        icon: Icon(Icons.emergency, size: 64, color: Colors.red.shade800),
        title: Text(
          '🚨 JATUH TERDETEKSI',
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Segera cek kondisi pengguna!\nTekan OK untuk mematikan alarm.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                NotificationService.stopAlarm();
                _isDialogShowing = false;
                Navigator.pop(ctx);
              },
              child: const Text('OK', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDialogShowing = false;

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'NORMAL':
        return Colors.green;
      // case 'DUDUK':
      //   return Colors.blue;
      case 'CURIGA':
        return Colors.orange;
      case 'JATUH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case 'NORMAL':
        return Icons.check_circle;
      // case 'DUDUK':
      //   return Icons.chair;
      case 'CURIGA':
        return Icons.warning;
      case 'JATUH':
        return Icons.emergency;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FallSafe'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(),
                size: 120,
                color: _getStatusColor(),
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(height: 40),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _connectionState == 'Terhubung'
                                ? Icons.wifi
                                : Icons.wifi_off,
                            color: _connectionState == 'Terhubung'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _connectionState,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastUpdate == null
                            ? 'Belum ada data'
                            : 'Update: ${_lastUpdate!.hour.toString().padLeft(2, '0')}:'
                              '${_lastUpdate!.minute.toString().padLeft(2, '0')}:'
                              '${_lastUpdate!.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ws://192.168.4.1:81',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}