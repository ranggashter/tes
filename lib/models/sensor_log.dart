class SensorLog {
  final int? id;
  final String status;
  final DateTime timestamp;

  SensorLog({
    this.id,
    required this.status,
    required this.timestamp,
  });

  // Konversi ke Map (untuk simpan ke database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Konversi dari Map (untuk baca dari database)
  factory SensorLog.fromMap(Map<String, dynamic> map) {
    return SensorLog(
      id: map['id'],
      status: map['status'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}