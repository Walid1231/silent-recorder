class RecordingModel {
  final String id;
  final String fileName;
  final String downloadUrl;
  final int durationSeconds;
  final DateTime recordedAt;
  final String callerNumber;

  RecordingModel({
    required this.id,
    required this.fileName,
    required this.downloadUrl,
    required this.durationSeconds,
    required this.recordedAt,
    required this.callerNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'durationSeconds': durationSeconds,
      'recordedAt': recordedAt.toIso8601String(),
      'callerNumber': callerNumber,
    };
  }

  factory RecordingModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return RecordingModel(
      id: id,
      fileName: map['fileName'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      recordedAt: DateTime.tryParse(map['recordedAt'] ?? '') ?? DateTime.now(),
      callerNumber: map['callerNumber'] ?? 'Unknown',
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
