class MedicineReminder {
  final String id;
  final String name;
  final String dosage;
  final String timingTag;
  final String timingDetail;
  final String condition;
  bool isTaken;
  final String? takenAt;

  MedicineReminder({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timingTag,
    required this.timingDetail,
    required this.condition,
    this.isTaken = false,
    this.takenAt,
  });
}

class ChatMessage {
  final String id;
  final String sender; // 'agent' or 'user'
  final String textEn;
  final String textHi;
  final String time;
  final String? tag;
  final String? audioDuration;
  final bool isHighPrecision;
  final bool hasVerifiedSchedule;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.textEn,
    required this.textHi,
    required this.time,
    this.tag,
    this.audioDuration,
    this.isHighPrecision = false,
    this.hasVerifiedSchedule = false,
  });
}

class PairedDevice {
  final String name;
  final String status; // 'Active', 'Connected', 'Standby'
  final int battery;
  final String details;
  final String lastSynced;
  final bool isConnected;

  PairedDevice({
    required this.name,
    required this.status,
    required this.battery,
    required this.details,
    required this.lastSynced,
    this.isConnected = true,
  });
}
