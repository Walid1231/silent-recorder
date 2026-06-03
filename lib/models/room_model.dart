class RoomModel {
  final String roomCode;
  final String recorderUid;
  final String? monitorUid;
  final String status;
  final bool activeCall;
  final DateTime createdAt;

  RoomModel({
    required this.roomCode,
    required this.recorderUid,
    this.monitorUid,
    this.status = 'idle',
    this.activeCall = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'recorderUid': recorderUid,
      'monitorUid': monitorUid,
      'status': status,
      'activeCall': activeCall,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoomModel.fromMap(String code, Map<dynamic, dynamic> map) {
    return RoomModel(
      roomCode: code,
      recorderUid: map['recorderUid'] ?? '',
      monitorUid: map['monitorUid'],
      status: map['status'] ?? 'idle',
      activeCall: map['activeCall'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
