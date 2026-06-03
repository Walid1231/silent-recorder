import 'dart:async';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level callback handler for phone state events.
/// Runs in a background Dart isolate.
/// Communicates via SharedPreferences since it can't access main isolate state.
@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
    PhoneStateBackgroundEvent event, String number, int duration) async {
  final prefs = await SharedPreferences.getInstance();

  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
      await prefs.setString('lastCallEvent', 'ringing');
      await prefs.setString('lastCallNumber', number);
      break;
    case PhoneStateBackgroundEvent.incomingreceived:
      await prefs.setString('lastCallEvent', 'active');
      await prefs.setString('lastCallNumber', number);
      break;
    case PhoneStateBackgroundEvent.incomingmissed:
      await prefs.setString('lastCallEvent', 'ended');
      break;
    case PhoneStateBackgroundEvent.incomingend:
      await prefs.setString('lastCallEvent', 'ended');
      await prefs.setInt('lastCallDuration', duration);
      break;
    case PhoneStateBackgroundEvent.outgoingstart:
      await prefs.setString('lastCallEvent', 'active');
      await prefs.setString('lastCallNumber', number);
      break;
    case PhoneStateBackgroundEvent.outgoingend:
      await prefs.setString('lastCallEvent', 'ended');
      await prefs.setInt('lastCallDuration', duration);
      break;
  }
}

enum CallState {
  idle,
  ringing,
  active,
  ended,
}

class CallService {
  bool _isInitialized = false;
  Timer? _pollTimer;

  final StreamController<CallEvent> _callEventController =
      StreamController<CallEvent>.broadcast();

  Stream<CallEvent> get callEvents => _callEventController.stream;
  bool get isInitialized => _isInitialized;

  Future<bool> requestPermissions() async {
    final phonePermission = await Permission.phone.request();
    return phonePermission.isGranted;
  }

  /// Initialize the phone state background listener.
  /// Uses PhoneStateBackground.initialize with the top-level callback.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await PhoneStateBackground.initialize(
          phoneStateBackgroundCallbackHandler);
      _isInitialized = true;

      // Poll SharedPreferences for events from the background isolate
      _startPolling();
    } catch (e) {
      // ignore - print removed for production
    }
  }

  String _lastProcessedEvent = '';

  /// Polls SharedPreferences to bridge events from the background isolate
  /// to the main isolate via the callEvents stream.
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final event = prefs.getString('lastCallEvent') ?? '';
      final number = prefs.getString('lastCallNumber') ?? '';

      if (event.isNotEmpty && event != _lastProcessedEvent) {
        _lastProcessedEvent = event;

        CallState state;
        switch (event) {
          case 'ringing':
            state = CallState.ringing;
            break;
          case 'active':
            state = CallState.active;
            break;
          case 'ended':
            state = CallState.ended;
            break;
          default:
            state = CallState.idle;
        }

        _callEventController.add(CallEvent(
          state: state,
          number: number,
        ));

        // Clear after processing 'ended'
        if (state == CallState.ended) {
          await prefs.remove('lastCallEvent');
          await prefs.remove('lastCallNumber');
          _lastProcessedEvent = '';
        }
      }
    });
  }

  void stopListening() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isInitialized = false;
  }

  void dispose() {
    stopListening();
    _callEventController.close();
  }
}

class CallEvent {
  final CallState state;
  final String number;

  CallEvent({
    required this.state,
    this.number = '',
  });
}
