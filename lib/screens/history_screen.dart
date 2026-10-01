import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/sensor_log.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SensorLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await DatabaseService.getAllLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text('Data tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.clearAll();
      _loadLogs();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'NORMAL':
        return Colors.green;
      case 'DUDUK':
        return Colors.blue;
      case 'CURIGA':
        return Colors.orange;
      case 'JATUH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat (${_logs.length})'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada riwayat.\nTunggu data dari Wemos...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(log.status),
                        child: Icon(
                          log.status == 'JATUH'
                              ? Icons.emergency
                              : log.status == 'CURIGA'
                                  ? Icons.warning
                                  : log.status == 'DUDUK'
                                      ? Icons.chair
                                      : Icons.check,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        log.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _statusColor(log.status),
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy - HH:mm:ss')
                            .format(log.timestamp),
                      ),
                      trailing: Text(
                        '#${log.id}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}