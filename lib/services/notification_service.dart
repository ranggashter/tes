import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Inisialisasi
  static Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notifikasi diklik: ${details.payload}');
      },
    );

    // Buat channel untuk JATUH (dengan suara alarm)
    await _createFallChannel();

    // Minta permission (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
    print('✅ NotificationService siap');
  }

  // Buat channel khusus JATUH dengan suara alarm
  static Future<void> _createFallChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'fallsafe_fall',
      'FallSafe - Deteksi Jatuh',
      description: 'Notifikasi saat jatuh terdeteksi',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Notifikasi JATUH (dipanggil dari UI isolate saat app dibuka)
  static Future<void> notifyFall() async {
    await init();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500, 200, 1000],
        repeat: 0,
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'fallsafe_fall',
      'FallSafe - Deteksi Jatuh',
      channelDescription: 'Notifikasi saat jatuh terdeteksi',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
    );

    await _notifications.show(
      999,
      '🚨 JATUH TERDETEKSI!',
      'Segera cek kondisi pengguna!',
      const NotificationDetails(android: androidDetails),
      payload: 'FALL',
    );
  }

  // Notifikasi CURIGA
  static Future<void> notifyWarning() async {
    await init();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500, amplitude: 128);
    }

    const androidDetails = AndroidNotificationDetails(
      'fallsafe_warning',
      'FallSafe - Peringatan',
      channelDescription: 'Peringatan gerakan curiga',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications.show(
      998,
      '⚠️ Gerakan Curiga',
      'Ada gerakan tidak normal. Mohon periksa.',
      const NotificationDetails(android: androidDetails),
    );
  }

  // Stop alarm (dipanggil saat user klik OK di dialog)
  static Future<void> stopAlarm() async {
    await Vibration.cancel();
    await _notifications.cancel(999);
    print('🔇 Alarm dihentikan');
  }
}