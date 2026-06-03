import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/recording_model.dart';
import '../models/room_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  // ─── Auth ──────────────────────────────────────────────

  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Anonymous sign-in failed: $e');
      return null;
    }
  }

  // ─── Room Management ───────────────────────────────────

  String _generateRoomCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<String?> createRoom() async {
    if (uid == null) return null;

    String roomCode = _generateRoomCode();
    final ref = _database.ref('rooms/$roomCode');

    // Check if code already exists, regenerate if needed
    final snapshot = await ref.get();
    if (snapshot.exists) {
      roomCode = _generateRoomCode();
    }

    final room = RoomModel(
      roomCode: roomCode,
      recorderUid: uid!,
    );

    await ref.set(room.toMap());
    return roomCode;
  }

  Future<RoomModel?> joinRoom(String roomCode) async {
    final ref = _database.ref('rooms/$roomCode');
    final snapshot = await ref.get();

    if (!snapshot.exists) return null;

    // Link monitor UID
    await ref.update({'monitorUid': uid});

    final data = snapshot.value as Map<dynamic, dynamic>;
    return RoomModel.fromMap(roomCode, data);
  }

  Future<bool> roomExists(String roomCode) async {
    final snapshot = await _database.ref('rooms/$roomCode').get();
    return snapshot.exists;
  }

  Future<void> deleteRoom(String roomCode) async {
    await _database.ref('rooms/$roomCode').remove();
    // Also delete storage files
    try {
      final storageRef = _storage.ref('recordings/$roomCode');
      final listResult = await storageRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {}
  }

  // ─── Status ────────────────────────────────────────────

  Future<void> updateStatus(String roomCode, String status) async {
    await _database.ref('rooms/$roomCode').update({
      'status': status,
      'activeCall': status == 'on_call_recording',
    });
  }

  Stream<String> listenToStatus(String roomCode) {
    return _database
        .ref('rooms/$roomCode/status')
        .onValue
        .map((event) => event.snapshot.value as String? ?? 'idle');
  }

  Stream<bool> listenToActiveCall(String roomCode) {
    return _database
        .ref('rooms/$roomCode/activeCall')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }

  // ─── Recordings ────────────────────────────────────────

  Future<void> saveRecordingMetadata(
      String roomCode, RecordingModel recording) async {
    await _database
        .ref('rooms/$roomCode/recordings/${recording.id}')
        .set(recording.toMap());
  }

  Stream<List<RecordingModel>> listenToRecordings(String roomCode) {
    return _database
        .ref('rooms/$roomCode/recordings')
        .orderByChild('recordedAt')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <RecordingModel>[];

      final recordings = data.entries
          .map((e) => RecordingModel.fromMap(
              e.key.toString(), e.value as Map<dynamic, dynamic>))
          .toList();

      // Sort newest first
      recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return recordings;
    });
  }

  Future<int> getRecordingsCount(String roomCode) async {
    final snapshot = await _database.ref('rooms/$roomCode/recordings').get();
    if (!snapshot.exists) return 0;
    final data = snapshot.value as Map<dynamic, dynamic>?;
    return data?.length ?? 0;
  }

  // ─── File Upload ───────────────────────────────────────

  Future<String?> uploadAudioFile(String roomCode, String filePath) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split(Platform.pathSeparator).last;
      final storageRef = _storage.ref('recordings/$roomCode/$fileName');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'audio/mp4'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
