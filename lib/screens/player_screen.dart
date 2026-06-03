import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import '../models/recording_model.dart';

class PlayerScreen extends StatefulWidget {
  final RecordingModel recording;

  const PlayerScreen({super.key, required this.recording});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _discAnimController;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.recording.downloadUrl);
      setState(() => _isLoading = false);

      // Listen to player state for disc animation
      _player.playingStream.listen((playing) {
        if (playing) {
          _discAnimController.repeat();
        } else {
          _discAnimController.stop();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load audio: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _discAnimController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, MMM dd, yyyy').format(widget.recording.recordedAt);
    final timeStr = DateFormat('hh:mm a').format(widget.recording.recordedAt);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1040),
              Color(0xFF0F0F1A),
              Color(0xFF0A0A14),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Now Playing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Disc / Art
              RotationTransition(
                turns: _discAnimController,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF4338CA),
                        Color(0xFF312E81),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F0F1A),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        color: Color(0xFF6366F1),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Caller Info
              Text(
                widget.recording.callerNumber,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$dateStr • $timeStr',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Duration: ${widget.recording.formattedDuration}',
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Error
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),

              // Loading
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 3,
                ),

              // Player Controls
              if (!_isLoading && _errorMessage == null) ...[
                // Seek Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: StreamBuilder<Duration?>(
                    stream: _player.positionStream,
                    builder: (context, posSnapshot) {
                      final position = posSnapshot.data ?? Duration.zero;
                      final duration =
                          _player.duration ?? Duration.zero;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16),
                              activeTrackColor: const Color(0xFF6366F1),
                              inactiveTrackColor: Colors.white
                                  .withValues(alpha: 0.08),
                              thumbColor: Colors.white,
                              overlayColor: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: position.inMilliseconds
                                  .toDouble()
                                  .clamp(
                                      0,
                                      duration.inMilliseconds
                                          .toDouble()
                                          .clamp(1, double.infinity)),
                              max: duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              onChanged: (value) {
                                _player.seek(
                                    Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Play/Pause Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rewind 10s
                    IconButton(
                      onPressed: () {
                        final pos = _player.position;
                        _player.seek(pos - const Duration(seconds: 10));
                      },
                      icon: Icon(
                        Icons.replay_10_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Play / Pause
                    StreamBuilder<bool>(
                      stream: _player.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              _player.pause();
                            } else {
                              _player.play();
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6)
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),

                    // Forward 10s
                    IconButton(
                      onPressed: () {
                        final pos = _player.position;
                        _player.seek(pos + const Duration(seconds: 10));
                      },
                      icon: Icon(
                        Icons.forward_10_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
