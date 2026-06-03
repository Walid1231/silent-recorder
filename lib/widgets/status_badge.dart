import 'package:flutter/material.dart';

class StatusBadge extends StatefulWidget {
  final String status;
  final double size;

  const StatusBadge({
    super.key,
    required this.status,
    this.size = 14,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldPulse) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  bool get _shouldPulse => widget.status == 'on_call_recording';

  Color get _color {
    switch (widget.status) {
      case 'on_call_recording':
        return const Color(0xFFEF4444);
      case 'uploading':
        return const Color(0xFFF59E0B);
      case 'idle':
      default:
        return const Color(0xFF22C55E);
    }
  }

  String get _label {
    switch (widget.status) {
      case 'on_call_recording':
        return 'ON CALL — RECORDING';
      case 'uploading':
        return 'UPLOADING';
      case 'idle':
      default:
        return 'IDLE';
    }
  }

  IconData get _icon {
    switch (widget.status) {
      case 'on_call_recording':
        return Icons.fiber_manual_record;
      case 'uploading':
        return Icons.cloud_upload_outlined;
      case 'idle':
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _shouldPulse ? _pulseAnimation.value : 1.0,
                child: Icon(
                  _icon,
                  color: _color,
                  size: widget.size + 4,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveDot extends StatefulWidget {
  final bool isActive;
  final double size;

  const LiveDot({
    super.key,
    required this.isActive,
    this.size = 12,
  });

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive
                ? Color.lerp(
                    const Color(0xFF22C55E),
                    const Color(0xFF22C55E).withValues(alpha: 0.3),
                    _controller.value,
                  )
                : Colors.grey.shade600,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
