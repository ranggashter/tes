import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_task_handler.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi komunikasi port
  FlutterForegroundTask.initCommunicationPort();

  // 2. Minta izin (Android 13+ memerlukan izin notifikasi)
  final notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  // 3. Minta mengabaikan optimasi baterai (kunci agar dapat dijalankan setelah reboot)
  if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  // 4. Inisialisasi konfigurasi service
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'fallsafe_service',
      channelName: 'FallSafe Monitoring',
      channelDescription: 'Memantau sensor jatuh secara real-time',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true, // 5. Jalankan otomatis saat boot
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

   await NotificationService.init();

  runApp(const FallSafeApp());
}

class FallSafeApp extends StatelessWidget {
  const FallSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FallSafe',
      home: const HomeScreen(),
    );
  }
}