import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'call_service.dart';
import 'recorder_service.dart';
import 'firebase_service.dart';
import '../models/recording_model.dart';

class BackgroundServiceManager {
  static const String _notificationChannelId = 'silent_recorder_service';
  static const String _notificationChannelName = 'Silent Recorder Service';
  static const int _notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Silent Recorder background service',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Silent Recorder',
        initialNotificationContent: 'Monitoring calls...',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.microphone],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase in the service isolate
  await Firebase.initializeApp();

  final firebaseService = FirebaseService();
  final recorderService = RecorderService();
  final callService = CallService();
  final uuid = Uuid();

  // Get saved room code
  final prefs = await SharedPreferences.getInstance();
  final roomCode = prefs.getString('roomCode') ?? '';
  final deviceRole = prefs.getString('deviceRole') ?? '';

  if (roomCode.isEmpty || deviceRole != 'recorder') {
    service.stopSelf();
    return;
  }

  // Sign in to Firebase
  await firebaseService.signInAnonymously();

  // Listen for stop command
  service.on('stopService').listen((event) {
    callService.dispose();
    recorderService.dispose();
    service.stopSelf();
  });

  // Start call detection
  await callService.initialize();

  // Handle call events
  callService.callEvents.listen((event) async {
    switch (event.state) {
      case CallState.active:
        // Call started - begin recording
        await firebaseService.updateStatus(roomCode, 'on_call_recording');
        await recorderService.startRecording();

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Silent Recorder',
            content: '🔴 Recording call...',
          );
        }
        break;

      case CallState.ended:
        // Call ended - stop recording and upload
        final result = await recorderService.stopRecording();

        if (result != null) {
          await firebaseService.updateStatus(roomCode, 'uploading');

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Silent Recorder',
              content: '⬆️ Uploading recording...',
            );
          }

          // Upload file
          final downloadUrl = await firebaseService.uploadAudioFile(
            roomCode,
            result.filePath,
          );

          if (downloadUrl != null) {
            // Save metadata
            final recording = RecordingModel(
              id: uuid.v4(),
              fileName: result.filePath.split('/').last,
              downloadUrl: downloadUrl,
              durationSeconds: result.durationSeconds,
              recordedAt: result.recordedAt,
              callerNumber: event.number.isNotEmpty ? event.number : 'Unknown',
            );

            await firebaseService.saveRecordingMetadata(roomCode, recording);

            // Delete local file
            await recorderService.deleteLocalFile(result.filePath);
          }
        }

        await firebaseService.updateStatus(roomCode, 'idle');

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Silent Recorder',
            content: 'Monitoring calls...',
          );
        }
        break;

      case CallState.ringing:
        // Incoming call - just update status
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Silent Recorder',
            content: '📞 Incoming call...',
          );
        }
        break;

      case CallState.idle:
        break;
    }
  });

  // Set initial status
  await firebaseService.updateStatus(roomCode, 'idle');

  // Service running for this room
}
