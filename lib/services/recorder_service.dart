import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentFilePath;
  DateTime? _recordingStartTime;

  bool _isRecording = false;
  bool get isRecording => _isRecording;
  String? get currentFilePath => _currentFilePath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String?> startRecording() async {
    if (_isRecording) return _currentFilePath;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        print('RecorderService: No mic permission');
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${dir.path}/call_$timestamp.m4a';
      _recordingStartTime = DateTime.now();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      print('RecorderService: Started recording to $_currentFilePath');
      return _currentFilePath;
    } catch (e) {
      print('RecorderService: Failed to start recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null || _currentFilePath == null) return null;

      // Calculate duration
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inSeconds
          : 0;

      final result = RecordingResult(
        filePath: _currentFilePath!,
        durationSeconds: duration,
        recordedAt: _recordingStartTime ?? DateTime.now(),
      );

      print('RecorderService: Stopped recording. Duration: ${duration}s');
      _currentFilePath = null;
      _recordingStartTime = null;
      return result;
    } catch (e) {
      print('RecorderService: Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> deleteLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('RecorderService: Deleted local file $filePath');
      }
    } catch (e) {
      print('RecorderService: Failed to delete file: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}

class RecordingResult {
  final String filePath;
  final int durationSeconds;
  final DateTime recordedAt;

  RecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.recordedAt,
  });
}
