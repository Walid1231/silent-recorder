import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  final VoidCallback onGranted;
  final VoidCallback? onDenied;

  const PermissionDialog({
    super.key,
    required this.onGranted,
    this.onDenied,
  });

  static Future<bool> requestAll(BuildContext context) async {
    final statuses = await [
      Permission.microphone,
      Permission.phone,
      Permission.notification,
    ].request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final phoneGranted = statuses[Permission.phone]?.isGranted ?? false;

    if (!micGranted || !phoneGranted) {
      if (context.mounted) {
        _showPermissionRequired(context);
      }
      return false;
    }
    return true;
  }

  static void _showPermissionRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 10),
            Text(
              'Permissions Required',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPermissionRow(
              Icons.mic_rounded,
              'Microphone',
              'Record audio during calls',
              const Color(0xFF6366F1),
            ),
            const SizedBox(height: 12),
            _buildPermissionRow(
              Icons.phone_rounded,
              'Phone',
              'Detect incoming and outgoing calls',
              const Color(0xFF22C55E),
            ),
            const SizedBox(height: 12),
            _buildPermissionRow(
              Icons.notifications_rounded,
              'Notifications',
              'Show recording service status',
              const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 16),
            Text(
              'Please grant these permissions in your device Settings to use this app.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Widget _buildPermissionRow(
      IconData icon, String title, String desc, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
